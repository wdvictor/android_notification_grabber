package br.syntax.nebula.notificationsgraber.notification_graber

import android.Manifest
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var pendingFailedNotificationId: String? = null
    private var receiverRegistered = false

    private val offlineNotificationsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (::channel.isInitialized) {
                channel.invokeMethod("offlineNotificationsChanged", null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingFailedNotificationId = NotificationDispatcher.extractFailureNotificationId(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(::handleMethodCall)
    }

    override fun onStart() {
        super.onStart()
        if (!receiverRegistered) {
            ContextCompat.registerReceiver(
                this,
                offlineNotificationsReceiver,
                IntentFilter(NotificationDispatcher.actionOfflineNotificationsChanged),
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            receiverRegistered = true
        }
    }

    override fun onStop() {
        if (receiverRegistered) {
            unregisterReceiver(offlineNotificationsReceiver)
            receiverRegistered = false
        }
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingFailedNotificationId = NotificationDispatcher.extractFailureNotificationId(intent)
        notifySelectedFailedNotification()
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppBootstrap" -> {
                val payload = NotificationDispatcher.createBootstrapPayload(
                    context = applicationContext,
                    pendingFailedNotificationId = pendingFailedNotificationId,
                    notificationAccessGranted = isNotificationAccessGranted(),
                    notificationPermissionGranted = isNotificationPermissionGranted(),
                )
                pendingFailedNotificationId = null
                result.success(payload)
            }

            "openNotificationAccessSettings" -> {
                startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }

            "requestNotificationPermission" -> requestNotificationPermission(result)

            "retryOfflineNotification" -> {
                val id = call.argument<String>("id")
                if (id.isNullOrBlank()) {
                    result.error("invalid_id", "Identificador da notificação não informado.", null)
                    return
                }

                NotificationDispatcher.executor.execute {
                    val deliveryOutcome =
                        NotificationDispatcher.retryOfflineNotification(applicationContext, id)
                    runOnUiThread {
                        result.success(deliveryOutcome.toMap())
                    }
                }
            }

            "retryAllOfflineNotifications" -> {
                NotificationDispatcher.executor.execute {
                    val retryOutcome =
                        NotificationDispatcher.retryAllOfflineNotifications(applicationContext)
                    runOnUiThread {
                        result.success(retryOutcome.toMap())
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (isNotificationPermissionGranted()) {
            result.success(true)
            return
        }

        if (notificationPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "Já existe uma solicitação de permissão em andamento.",
                null,
            )
            return
        }

        notificationPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notificationPermissionRequestCode)
    }

    private fun notifySelectedFailedNotification() {
        val id = pendingFailedNotificationId ?: return
        if (!::channel.isInitialized) {
            return
        }

        channel.invokeMethod("failedNotificationSelected", mapOf("id" to id))
        pendingFailedNotificationId = null
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        return enabledListeners.split(':')
            .mapNotNull(ComponentName::unflattenFromString)
            .any { it.packageName == applicationContext.packageName }
    }

    private fun isNotificationPermissionGranted(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
    }

    private companion object {
        const val CHANNEL_NAME = "notification_graber/platform"
        const val notificationPermissionRequestCode = 1001
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != notificationPermissionRequestCode) {
            return
        }

        val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        notificationPermissionResult?.success(isGranted)
        notificationPermissionResult = null
    }
}

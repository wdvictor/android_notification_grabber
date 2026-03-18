package br.syntax.nebula.notificationsgrabber.notification_grabber

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var receiverRegistered = false

    private val offlineNotificationsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (::channel.isInitialized) {
                channel.invokeMethod("offlineNotificationsChanged", null)
            }
        }
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
                IntentFilter(NotificationBackgroundBridge.actionOfflineNotificationsChanged),
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

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAppBootstrap" -> {
                runPlatformTask("getAppBootstrap", result) {
                    mapOf(
                        "notificationAccessGranted" to isNotificationAccessGranted(),
                        "offlineNotifications" to NotificationBackgroundBridge
                            .getOfflineNotifications(applicationContext),
                    )
                }
            }

            "getInstalledApplications" -> {
                runPlatformTask("getInstalledApplications", result) {
                    getInstalledApplications()
                }
            }

            "openNotificationAccessSettings" -> {
                startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }

            "retryOfflineNotification" -> {
                val id = call.argument<String>("id")
                if (id.isNullOrBlank()) {
                    result.error("invalid_id", "Identificador da notificação não informado.", null)
                    return
                }

                runPlatformTask("retryOfflineNotification", result) {
                    NotificationBackgroundBridge
                        .retryOfflineNotification(applicationContext, id)
                }
            }

            "retryAllOfflineNotifications" -> {
                runPlatformTask("retryAllOfflineNotifications", result) {
                    NotificationBackgroundBridge
                        .retryAllOfflineNotifications(applicationContext)
                }
            }

            "getApiKey" -> result.success(BuildConfig.X_API_KEY)

            "getBackendBaseUrl" -> result.success(BuildConfig.BACKEND_BASE_URL)

            else -> result.notImplemented()
        }
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

    private fun getInstalledApplications(): List<Map<String, Any?>> {
        val packageManager = applicationContext.packageManager
        return loadInstalledApplications(packageManager)
            .asSequence()
            .filter { applicationInfo -> applicationInfo.packageName != applicationContext.packageName }
            .map { applicationInfo ->
                val appName = packageManager.getApplicationLabel(applicationInfo)
                    ?.toString()
                    ?.trim()
                    .orEmpty()
                    .ifEmpty { applicationInfo.packageName }

                mapOf(
                    "name" to appName,
                    "packageName" to applicationInfo.packageName,
                    "icon" to drawableToPngBytes(
                        drawable = packageManager.getApplicationIcon(applicationInfo),
                        sizePx = (resources.displayMetrics.density * 40).toInt().coerceAtLeast(64),
                    ),
                )
            }
            .toList()
    }

    private fun loadInstalledApplications(packageManager: PackageManager): List<ApplicationInfo> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledApplications(0)
        }
    }

    private fun drawableToPngBytes(drawable: Drawable, sizePx: Int): ByteArray? {
        return runCatching {
            val bitmap = when (drawable) {
                is BitmapDrawable -> {
                    val sourceBitmap = drawable.bitmap ?: return null
                    Bitmap.createScaledBitmap(sourceBitmap, sizePx, sizePx, true)
                }

                else -> {
                    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                }
            }

            bitmapToPng(bitmap)
        }.getOrNull()
    }

    private fun bitmapToPng(bitmap: Bitmap): ByteArray? {
        return java.io.ByteArrayOutputStream().use { stream ->
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) {
                return null
            }

            stream.toByteArray()
        }
    }

    private fun runPlatformTask(
        method: String,
        result: MethodChannel.Result,
        block: () -> Any?,
    ) {
        NotificationBackgroundBridge.executor.execute {
            try {
                val value = block()
                runOnUiThread {
                    result.success(value)
                }
            } catch (error: Throwable) {
                Log.e(TAG, "Falha ao executar $method.", error)
                runOnUiThread {
                    result.error(
                        "android_bridge_failure",
                        error.message ?: "Falha ao executar $method.",
                        null,
                    )
                }
            }
        }
    }

    private companion object {
        const val TAG = "MainActivityBridge"
        const val CHANNEL_NAME = "notification_grabber/platform"
    }
}

package br.syntax.nebula.notificationsgraber.notification_graber

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONObject

object NotificationDispatcher {
    const val actionOfflineNotificationsChanged =
        "br.syntax.nebula.notificationsgraber.notification_graber.OFFLINE_NOTIFICATIONS_CHANGED"

    private const val endpoint = "https://is-that-a-pix-api.onrender.com/add_notification"
    private const val deliveryFailuresChannelId = "delivery_failures"
    private const val failureNotificationAction =
        "br.syntax.nebula.notificationsgraber.notification_graber.OPEN_FAILED_NOTIFICATION"
    private const val failureNotificationExtraId = "failed_notification_id"
    private const val connectTimeoutMs = 120000
    private const val readTimeoutMs = 120000
    private val ignoredPackageTerms = listOf("whatsapp", "android", "samsung", "google")

    val executor: ExecutorService = Executors.newSingleThreadExecutor()

    fun shouldIgnorePackage(context: Context, packageName: String): Boolean {
        if (packageName == context.packageName) {
            return true
        }

        return ignoredPackageTerms.any { term ->
            packageName.contains(term, ignoreCase = true)
        }
    }

    fun createBootstrapPayload(
        context: Context,
        pendingFailedNotificationId: String?,
        notificationAccessGranted: Boolean,
        notificationPermissionGranted: Boolean,
    ): Map<String, Any?> {
        val store = OfflineNotificationStore(context)
        return mapOf(
            "notificationAccessGranted" to notificationAccessGranted,
            "notificationPermissionGranted" to notificationPermissionGranted,
            "offlineNotifications" to store.getAll().map { it.toMap() },
            "pendingFailedNotificationId" to pendingFailedNotificationId,
        )
    }

    fun retryOfflineNotification(context: Context, id: String): DeliveryOutcome {
        val store = OfflineNotificationStore(context)
        val record = store.getById(id) ?: return DeliveryOutcome(success = true, record = null)
        return dispatch(
            context = context,
            app = record.app,
            text = record.text,
            existingId = record.id,
            notifyOnFailure = true,
        )
    }

    fun retryAllOfflineNotifications(context: Context): RetryAllOutcome {
        val store = OfflineNotificationStore(context)
        val snapshot = store.getAll()
        var successCount = 0
        var failureCount = 0

        snapshot.forEach { record ->
            val result = dispatch(
                context = context,
                app = record.app,
                text = record.text,
                existingId = record.id,
                notifyOnFailure = true,
            )
            if (result.success) {
                successCount += 1
            } else {
                failureCount += 1
            }
        }

        return RetryAllOutcome(successCount = successCount, failureCount = failureCount)
    }

    fun dispatch(
        context: Context,
        app: String,
        text: String,
        existingId: String? = null,
        notifyOnFailure: Boolean = true,
    ): DeliveryOutcome {
        val store = OfflineNotificationStore(context)
        val previousRecord = existingId?.let(store::getById)
        val requestBody = createRequestBody(app = app, text = text)
        val requestSnapshot = RequestSnapshot(
            method = "PUT",
            url = endpoint,
            body = requestBody,
            attemptedAt = System.currentTimeMillis(),
        )

        var statusCode: Int? = null
        var responseBody: String? = null
        var errorMessage: String? = null

        var connection: HttpURLConnection? = null
        try {
            connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
                requestMethod = "PUT"
                connectTimeout = connectTimeoutMs
                readTimeout = readTimeoutMs
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("X-API-Key", BuildConfig.X_API_KEY)
            }

            connection.outputStream.use { outputStream ->
                outputStream.write(requestBody.toByteArray(StandardCharsets.UTF_8))
                outputStream.flush()
            }

            statusCode = connection.responseCode
            responseBody = connection.readResponseBody()
        } catch (error: Exception) {
            errorMessage = error.message ?: error.javaClass.simpleName
        } finally {
            connection?.disconnect()
        }

        if (statusCode == 201) {
            if (existingId != null) {
                store.delete(existingId)
                broadcastOfflineNotificationsChanged(context)
            }
            return DeliveryOutcome(success = true, record = null)
        }

        val updatedAt = System.currentTimeMillis()
        val record = OfflineNotificationRecord(
            id = existingId ?: UUID.randomUUID().toString(),
            app = app,
            text = text,
            request = requestSnapshot,
            response = ResponseSnapshot(
                statusCode = statusCode,
                body = responseBody,
                errorMessage = errorMessage,
                receivedAt = updatedAt,
            ),
            createdAt = previousRecord?.createdAt ?: updatedAt,
            updatedAt = updatedAt,
        )

        store.upsert(record)
        broadcastOfflineNotificationsChanged(context)
        if (notifyOnFailure) {
            showFailureNotification(context, record)
        }
        return DeliveryOutcome(success = false, record = record)
    }

    fun broadcastOfflineNotificationsChanged(context: Context) {
        context.sendBroadcast(Intent(actionOfflineNotificationsChanged).setPackage(context.packageName))
    }

    private fun createRequestBody(app: String, text: String): String {
        return JSONObject()
            .put("app", app)
            .put("text", text)
            .put("is_financial_notification", JSONObject.NULL)
            .toString()
    }

    private fun showFailureNotification(context: Context, record: OfflineNotificationRecord) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notificationManager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                deliveryFailuresChannelId,
                "Falhas de envio",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Exibe falhas ao entregar notificações ao backend"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            record.id.hashCode(),
            Intent(context, MainActivity::class.java).apply {
                action = failureNotificationAction
                putExtra(failureNotificationExtraId, record.id)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, deliveryFailuresChannelId)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle("Backend não recebeu a notificação")
            .setContentText(record.app)
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "Toque para ver os detalhes da última tentativa com falha.",
                ),
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(record.id.hashCode(), notification)
    }

    private fun HttpURLConnection.readResponseBody(): String? {
        val source: InputStream? = if (responseCode in 200..299) {
            inputStream
        } else {
            errorStream
        }

        if (source == null) {
            return null
        }

        return BufferedReader(InputStreamReader(source, StandardCharsets.UTF_8)).use { reader ->
            reader.readText()
        }
    }

    fun extractFailureNotificationId(intent: Intent?): String? {
        if (intent?.action != failureNotificationAction) {
            return null
        }

        return intent.getStringExtra(failureNotificationExtraId)
    }
}

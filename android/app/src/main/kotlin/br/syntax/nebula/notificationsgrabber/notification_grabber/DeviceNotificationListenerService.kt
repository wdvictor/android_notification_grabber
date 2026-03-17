package br.syntax.nebula.notificationsgrabber.notification_grabber

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class DeviceNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (NotificationBackgroundBridge.shouldIgnorePackage(applicationContext, packageName)) {
            return
        }

        val text = extractNotificationText(sbn.notification) ?: return
        NotificationBackgroundBridge.processCapturedNotification(
            context = applicationContext,
            app = packageName,
            text = text,
        )
    }

    private fun extractNotificationText(notification: Notification): String? {
        val extras = notification.extras ?: return null
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.mapNotNull { value -> value?.toString()?.trim()?.takeIf { it.isNotEmpty() } }
            .orEmpty()

        val content = when {
            lines.isNotEmpty() -> lines.joinToString(separator = "\n")
            bigText.isNotEmpty() -> bigText
            text.isNotEmpty() -> text
            else -> ""
        }

        val parts = buildList {
            if (title.isNotEmpty() && !title.equals(content, ignoreCase = true)) {
                add(title)
            }
            if (content.isNotEmpty()) {
                add(content)
            }
        }

        val result = parts.joinToString(separator = "\n").trim()
        return result.ifEmpty { null }
    }
}

package br.syntax.nebula.notificationsgrabber.notification_grabber

import android.app.Notification
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class DeviceNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (NotificationBackgroundBridge.shouldIgnorePackage(applicationContext, packageName)) {
            return
        }

        val notification = sbn.notification
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) {
            return
        }

        val text = extractNotificationText(notification) ?: return
        if (shouldIgnoreDuplicate(packageName, text)) {
            return
        }

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

    private fun shouldIgnoreDuplicate(packageName: String, text: String): Boolean {
        val fingerprint = "$packageName|${text.normalizeFingerprint()}"

        return synchronized(recentNotificationsLock) {
            val now = SystemClock.elapsedRealtime()
            pruneExpiredFingerprints(now)

            val lastSeenAt = recentNotificationFingerprints[fingerprint]
            recentNotificationFingerprints[fingerprint] = now

            lastSeenAt != null && now - lastSeenAt <= duplicateWindowMs
        }
    }

    private fun String.normalizeFingerprint(): String {
        return trim().replace(whitespaceRegex, " ").lowercase()
    }

    private companion object {
        const val duplicateWindowMs = 3000L
        const val maxRecentFingerprints = 200
        val whitespaceRegex = "\\s+".toRegex()
        val recentNotificationsLock = Any()
        val recentNotificationFingerprints = LinkedHashMap<String, Long>()

        fun pruneExpiredFingerprints(now: Long) {
            val iterator = recentNotificationFingerprints.entries.iterator()
            while (iterator.hasNext()) {
                val entry = iterator.next()
                if (now - entry.value > duplicateWindowMs) {
                    iterator.remove()
                }
            }

            while (recentNotificationFingerprints.size > maxRecentFingerprints) {
                val eldestKey = recentNotificationFingerprints.entries.firstOrNull()?.key
                    ?: return
                recentNotificationFingerprints.remove(eldestKey)
            }
        }
    }
}

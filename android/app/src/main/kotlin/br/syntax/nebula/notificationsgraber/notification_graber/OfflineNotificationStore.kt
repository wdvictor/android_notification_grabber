package br.syntax.nebula.notificationsgraber.notification_graber

import android.content.Context
import org.json.JSONArray

class OfflineNotificationStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    @Synchronized
    fun getAll(): List<OfflineNotificationRecord> {
        val raw = preferences.getString(KEY_OFFLINE_NOTIFICATIONS, null).orEmpty()
        if (raw.isBlank()) {
            return emptyList()
        }

        return try {
            val jsonArray = JSONArray(raw)
            val records = mutableListOf<OfflineNotificationRecord>()
            for (index in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.optJSONObject(index) ?: continue
                records += OfflineNotificationRecord.fromJson(jsonObject)
            }

            records.sortedByDescending { it.updatedAt }
        } catch (_: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun getById(id: String): OfflineNotificationRecord? {
        return getAll().firstOrNull { it.id == id }
    }

    @Synchronized
    fun upsert(record: OfflineNotificationRecord) {
        val records = getAll().toMutableList()
        val index = records.indexOfFirst { it.id == record.id }
        if (index >= 0) {
            records[index] = record
        } else {
            records += record
        }

        save(records)
    }

    @Synchronized
    fun delete(id: String) {
        val updated = getAll().filterNot { it.id == id }
        save(updated)
    }

    @Synchronized
    private fun save(records: List<OfflineNotificationRecord>) {
        val jsonArray = JSONArray()
        records.sortedByDescending { it.updatedAt }.forEach { record ->
            jsonArray.put(record.toJson())
        }

        preferences.edit().putString(KEY_OFFLINE_NOTIFICATIONS, jsonArray.toString()).apply()
    }

    private companion object {
        const val PREFERENCES_NAME = "notification_graber_store"
        const val KEY_OFFLINE_NOTIFICATIONS = "offline_notifications"
    }
}

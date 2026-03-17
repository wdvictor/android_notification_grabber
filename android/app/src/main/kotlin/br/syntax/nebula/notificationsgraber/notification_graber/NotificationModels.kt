package br.syntax.nebula.notificationsgraber.notification_graber

import org.json.JSONObject

data class RequestSnapshot(
    val method: String,
    val url: String,
    val body: String,
    val attemptedAt: Long,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("method", method)
            .put("url", url)
            .put("body", body)
            .put("attemptedAt", attemptedAt)
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "method" to method,
            "url" to url,
            "body" to body,
            "attemptedAt" to attemptedAt,
        )
    }

    companion object {
        fun fromJson(jsonObject: JSONObject): RequestSnapshot {
            return RequestSnapshot(
                method = jsonObject.optString("method", "PUT"),
                url = jsonObject.optString("url", ""),
                body = jsonObject.optString("body", "{}"),
                attemptedAt = jsonObject.optLong("attemptedAt", 0L),
            )
        }
    }
}

data class ResponseSnapshot(
    val statusCode: Int?,
    val body: String?,
    val errorMessage: String?,
    val receivedAt: Long,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("statusCode", statusCode ?: JSONObject.NULL)
            .put("body", body ?: JSONObject.NULL)
            .put("errorMessage", errorMessage ?: JSONObject.NULL)
            .put("receivedAt", receivedAt)
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "statusCode" to statusCode,
            "body" to body,
            "errorMessage" to errorMessage,
            "receivedAt" to receivedAt,
        )
    }

    companion object {
        fun fromJson(jsonObject: JSONObject): ResponseSnapshot {
            return ResponseSnapshot(
                statusCode = if (jsonObject.isNull("statusCode")) {
                    null
                } else {
                    jsonObject.optInt("statusCode")
                },
                body = jsonObject.optNullableString("body"),
                errorMessage = jsonObject.optNullableString("errorMessage"),
                receivedAt = jsonObject.optLong("receivedAt", 0L),
            )
        }
    }
}

data class OfflineNotificationRecord(
    val id: String,
    val app: String,
    val text: String,
    val isFinancialNotification: Any? = null,
    val request: RequestSnapshot,
    val response: ResponseSnapshot,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("id", id)
            .put("app", app)
            .put("text", text)
            .put("isFinancialNotification", JSONObject.NULL)
            .put("request", request.toJson())
            .put("response", response.toJson())
            .put("createdAt", createdAt)
            .put("updatedAt", updatedAt)
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "app" to app,
            "text" to text,
            "isFinancialNotification" to isFinancialNotification,
            "request" to request.toMap(),
            "response" to response.toMap(),
            "createdAt" to createdAt,
            "updatedAt" to updatedAt,
        )
    }

    companion object {
        fun fromJson(jsonObject: JSONObject): OfflineNotificationRecord {
            return OfflineNotificationRecord(
                id = jsonObject.optString("id", ""),
                app = jsonObject.optString("app", ""),
                text = jsonObject.optString("text", ""),
                request = RequestSnapshot.fromJson(jsonObject.getJSONObject("request")),
                response = ResponseSnapshot.fromJson(jsonObject.getJSONObject("response")),
                createdAt = jsonObject.optLong("createdAt", 0L),
                updatedAt = jsonObject.optLong("updatedAt", 0L),
            )
        }
    }
}

data class DeliveryOutcome(
    val success: Boolean,
    val record: OfflineNotificationRecord?,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "success" to success,
            "record" to record?.toMap(),
        )
    }
}

data class RetryAllOutcome(
    val successCount: Int,
    val failureCount: Int,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "successCount" to successCount,
            "failureCount" to failureCount,
        )
    }
}

private fun JSONObject.optNullableString(key: String): String? {
    return if (isNull(key)) {
        null
    } else {
        optString(key, null)
    }
}

class RequestDetails {
  const RequestDetails({
    required this.method,
    required this.url,
    required this.body,
    required this.attemptedAt,
  });

  factory RequestDetails.fromMap(Map<Object?, Object?> map) {
    return RequestDetails(
      method: map['method'] as String? ?? 'PUT',
      url: map['url'] as String? ?? '',
      body: map['body'] as String? ?? '{}',
      attemptedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['attemptedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final String method;
  final String url;
  final String body;
  final DateTime attemptedAt;
}

class ResponseDetails {
  const ResponseDetails({
    required this.statusCode,
    required this.body,
    required this.errorMessage,
    required this.receivedAt,
  });

  factory ResponseDetails.fromMap(Map<Object?, Object?> map) {
    return ResponseDetails(
      statusCode: (map['statusCode'] as num?)?.toInt(),
      body: map['body'] as String?,
      errorMessage: map['errorMessage'] as String?,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['receivedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final int? statusCode;
  final String? body;
  final String? errorMessage;
  final DateTime receivedAt;
}

class OfflineNotification {
  const OfflineNotification({
    required this.id,
    required this.app,
    required this.text,
    required this.isFinancialNotification,
    required this.request,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfflineNotification.fromMap(Map<Object?, Object?> map) {
    return OfflineNotification(
      id: map['id'] as String? ?? '',
      app: map['app'] as String? ?? '',
      text: map['text'] as String? ?? '',
      isFinancialNotification: map['isFinancialNotification'],
      request: RequestDetails.fromMap(
        (map['request'] as Map<Object?, Object?>?) ?? const {},
      ),
      response: ResponseDetails.fromMap(
        (map['response'] as Map<Object?, Object?>?) ?? const {},
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final String id;
  final String app;
  final String text;
  final Object? isFinancialNotification;
  final RequestDetails request;
  final ResponseDetails response;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get preview {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= 96) {
      return normalized;
    }

    return '${normalized.substring(0, 93)}...';
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.notificationAccessGranted,
    required this.notificationPermissionGranted,
    required this.offlineNotifications,
    required this.pendingFailedNotificationId,
  });

  factory AppSnapshot.fromMap(Map<Object?, Object?> map) {
    final rawNotifications =
        (map['offlineNotifications'] as List<Object?>?) ?? const [];

    return AppSnapshot(
      notificationAccessGranted:
          map['notificationAccessGranted'] as bool? ?? false,
      notificationPermissionGranted:
          map['notificationPermissionGranted'] as bool? ?? true,
      offlineNotifications: rawNotifications
          .whereType<Map<Object?, Object?>>()
          .map(OfflineNotification.fromMap)
          .toList(),
      pendingFailedNotificationId:
          map['pendingFailedNotificationId'] as String?,
    );
  }

  final bool notificationAccessGranted;
  final bool notificationPermissionGranted;
  final List<OfflineNotification> offlineNotifications;
  final String? pendingFailedNotificationId;
}

class RetryNotificationResult {
  const RetryNotificationResult({required this.success, required this.record});

  factory RetryNotificationResult.fromMap(Map<Object?, Object?> map) {
    final rawRecord = map['record'];

    return RetryNotificationResult(
      success: map['success'] as bool? ?? false,
      record: rawRecord is Map<Object?, Object?>
          ? OfflineNotification.fromMap(rawRecord)
          : null,
    );
  }

  final bool success;
  final OfflineNotification? record;
}

class RetryAllResult {
  const RetryAllResult({
    required this.successCount,
    required this.failureCount,
  });

  factory RetryAllResult.fromMap(Map<Object?, Object?> map) {
    return RetryAllResult(
      successCount: (map['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (map['failureCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int successCount;
  final int failureCount;
}

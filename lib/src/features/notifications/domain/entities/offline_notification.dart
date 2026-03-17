class RequestDetails {
  const RequestDetails({
    required this.method,
    required this.url,
    required this.body,
    required this.attemptedAt,
  });

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

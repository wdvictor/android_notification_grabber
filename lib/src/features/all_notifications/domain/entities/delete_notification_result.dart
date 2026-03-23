class DeleteNotificationResult {
  const DeleteNotificationResult({
    required this.notificationId,
    required this.requestMethod,
    required this.requestUrl,
    required this.requestQuery,
    this.responseStatusCode,
    this.responseBody,
    this.responseErrorMessage,
  });

  final String notificationId;
  final String requestMethod;
  final String requestUrl;
  final String requestQuery;
  final int? responseStatusCode;
  final String? responseBody;
  final String? responseErrorMessage;

  bool get isSuccess =>
      responseStatusCode != null &&
      responseStatusCode! >= 200 &&
      responseStatusCode! < 300 &&
      responseErrorMessage == null;
}

class UpdateNotificationResult {
  const UpdateNotificationResult({
    required this.notificationId,
    required this.isFinancialTransaction,
    required this.requestMethod,
    required this.requestUrl,
    required this.requestBody,
    this.responseStatusCode,
    this.responseBody,
    this.responseErrorMessage,
  });

  final String notificationId;
  final bool isFinancialTransaction;
  final String requestMethod;
  final String requestUrl;
  final String requestBody;
  final int? responseStatusCode;
  final String? responseBody;
  final String? responseErrorMessage;

  bool get isSuccess =>
      responseStatusCode == 200 && responseErrorMessage == null;
}

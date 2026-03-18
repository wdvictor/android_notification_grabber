import '../../domain/entities/update_notification_result.dart';

class UpdateNotificationResultModel {
  const UpdateNotificationResultModel({
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

  UpdateNotificationResult toEntity() {
    return UpdateNotificationResult(
      notificationId: notificationId,
      isFinancialTransaction: isFinancialTransaction,
      requestMethod: requestMethod,
      requestUrl: requestUrl,
      requestBody: requestBody,
      responseStatusCode: responseStatusCode,
      responseBody: responseBody,
      responseErrorMessage: responseErrorMessage,
    );
  }
}

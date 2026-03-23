import '../../domain/entities/delete_notification_result.dart';

class DeleteNotificationResultModel {
  const DeleteNotificationResultModel({
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

  DeleteNotificationResult toEntity() {
    return DeleteNotificationResult(
      notificationId: notificationId,
      requestMethod: requestMethod,
      requestUrl: requestUrl,
      requestQuery: requestQuery,
      responseStatusCode: responseStatusCode,
      responseBody: responseBody,
      responseErrorMessage: responseErrorMessage,
    );
  }
}

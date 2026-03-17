class DeliveryResponseModel {
  const DeliveryResponseModel({
    required this.requestUrl,
    required this.requestBody,
    this.statusCode,
    this.body,
    this.errorMessage,
  });

  final String requestUrl;
  final String requestBody;
  final int? statusCode;
  final String? body;
  final String? errorMessage;
}

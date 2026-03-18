import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/app_http_client_factory.dart';
import '../../../../core/network/dio_error_message.dart';
import '../models/delivery_response_model.dart';

class NotificationDeliveryDataSource {
  NotificationDeliveryDataSource({Dio? httpClient})
    : _httpClient = httpClient ?? AppHttpClientFactory.create();

  static const String _missingEndpointMessage =
      'Backend base URL not configured. Set BACKEND_BASE_URL in .env.';
  final Dio _httpClient;

  Future<DeliveryResponseModel> send({
    required String endpoint,
    required String app,
    required String text,
    required String apiKey,
  }) async {
    final requestBody = jsonEncode(<String, Object?>{
      'app': app,
      'text': text,
      'is_financial_notification': null,
    });
    final endpointUri = _parseEndpoint(endpoint);
    if (endpointUri == null) {
      return DeliveryResponseModel(
        requestUrl: endpoint.trim(),
        requestBody: requestBody,
        errorMessage: _describeEndpointError(endpoint),
      );
    }

    try {
      final response = await _httpClient.requestUri<String>(
        endpointUri,
        data: requestBody,
        options: Options(
          method: 'PUT',
          headers: <String, Object?>{
            Headers.contentTypeHeader: 'application/json; charset=UTF-8',
            Headers.acceptHeader: 'application/json',
            'X-API-Key': apiKey,
          },
        ),
      );
      final responseBody = _responseBody(response.data);

      return DeliveryResponseModel(
        requestUrl: endpointUri.toString(),
        requestBody: requestBody,
        statusCode: response.statusCode,
        body: responseBody,
      );
    } catch (error) {
      return DeliveryResponseModel(
        requestUrl: endpointUri.toString(),
        requestBody: requestBody,
        errorMessage: _describeError(error),
      );
    }
  }

  Uri? _parseEndpoint(String endpoint) {
    final normalized = endpoint.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    return uri;
  }

  String _describeEndpointError(String endpoint) {
    if (endpoint.trim().isEmpty) {
      return _missingEndpointMessage;
    }

    return 'Invalid backend endpoint configured: $endpoint';
  }

  String _describeError(Object error) {
    return describeHttpError(error);
  }

  String _responseBody(Object? data) {
    if (data == null) {
      return '';
    }

    return data is String ? data : data.toString();
  }
}

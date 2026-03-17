import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/delivery_response_model.dart';

class NotificationDeliveryDataSource {
  static const Duration _connectTimeout = Duration(milliseconds: 120000);
  static const Duration _readTimeout = Duration(milliseconds: 120000);
  static const String _missingEndpointMessage =
      'Backend base URL not configured. Set BACKEND_BASE_URL in .env.';

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

    final client = HttpClient()..connectionTimeout = _connectTimeout;

    try {
      final request = await client.putUrl(endpointUri).timeout(_connectTimeout);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=UTF-8',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('X-API-Key', apiKey);
      request.add(utf8.encode(requestBody));

      final response = await request.close().timeout(_readTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_readTimeout);

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
    } finally {
      client.close(force: true);
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
    if (error is SocketException) {
      return error.message;
    }

    if (error is HttpException) {
      return error.message;
    }

    if (error is TimeoutException) {
      final message = error.message;
      return message == null || message.isEmpty ? 'TimeoutException' : message;
    }

    return error.toString();
  }
}

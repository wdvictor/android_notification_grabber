import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/delivery_response_model.dart';

class NotificationDeliveryDataSource {
  static const String endpoint =
      'https://is-that-a-pix-api.onrender.com/add_notification';
  static const Duration _connectTimeout = Duration(milliseconds: 120000);
  static const Duration _readTimeout = Duration(milliseconds: 120000);

  Future<DeliveryResponseModel> send({
    required String app,
    required String text,
    required String apiKey,
  }) async {
    final requestBody = jsonEncode(<String, Object?>{
      'app': app,
      'text': text,
      'is_financial_notification': null,
    });

    final client = HttpClient()..connectionTimeout = _connectTimeout;

    try {
      final request = await client
          .putUrl(Uri.parse(endpoint))
          .timeout(_connectTimeout);
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
        requestBody: requestBody,
        statusCode: response.statusCode,
        body: responseBody,
      );
    } catch (error) {
      return DeliveryResponseModel(
        requestBody: requestBody,
        errorMessage: _describeError(error),
      );
    } finally {
      client.close(force: true);
    }
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

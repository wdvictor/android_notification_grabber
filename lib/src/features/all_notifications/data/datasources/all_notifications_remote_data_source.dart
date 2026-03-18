import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/all_notifications_query.dart';
import '../models/all_notification_model.dart';
import '../models/update_notification_result_model.dart';

class AllNotificationsRemoteDataSource {
  static const Duration _connectTimeout = Duration(milliseconds: 120000);
  static const Duration _readTimeout = Duration(milliseconds: 120000);
  static const String _missingEndpointMessage =
      'Backend base URL not configured. Set BACKEND_BASE_URL in .env.';

  Future<List<AllNotificationModel>> fetch({
    required String endpoint,
    required String apiKey,
    required AllNotificationsQuery query,
  }) async {
    final endpointUri = _buildEndpointUri(endpoint: endpoint, query: query);
    if (endpointUri == null) {
      throw Exception(_describeEndpointError(endpoint));
    }

    final client = HttpClient()..connectionTimeout = _connectTimeout;

    try {
      final request = await client.getUrl(endpointUri).timeout(_connectTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('X-API-Key', apiKey);

      final response = await request.close().timeout(_readTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_readTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'get_all_notifications returned ${response.statusCode}: $responseBody',
        );
      }

      if (responseBody.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! List) {
        throw const FormatException(
          'Invalid payload from get_all_notifications.',
        );
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                AllNotificationModel.fromJson(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(_describeError(error));
    } finally {
      client.close(force: true);
    }
  }

  Future<UpdateNotificationResultModel> update({
    required String endpoint,
    required String apiKey,
    required String id,
    required bool isFinancialTransaction,
  }) async {
    final requestBody = jsonEncode(<String, Object?>{
      'id': id,
      'is_financial_transaction': isFinancialTransaction,
    });
    final endpointUri = _parseEndpoint(endpoint);
    if (endpointUri == null) {
      return UpdateNotificationResultModel(
        notificationId: id,
        isFinancialTransaction: isFinancialTransaction,
        requestMethod: 'PUT',
        requestUrl: endpoint.trim(),
        requestBody: requestBody,
        responseErrorMessage: _describeEndpointError(endpoint),
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

      return UpdateNotificationResultModel(
        notificationId: id,
        isFinancialTransaction: isFinancialTransaction,
        requestMethod: 'PUT',
        requestUrl: endpointUri.toString(),
        requestBody: requestBody,
        responseStatusCode: response.statusCode,
        responseBody: responseBody,
        responseErrorMessage: response.statusCode == 200
            ? null
            : 'update_notification returned ${response.statusCode}',
      );
    } catch (error) {
      return UpdateNotificationResultModel(
        notificationId: id,
        isFinancialTransaction: isFinancialTransaction,
        requestMethod: 'PUT',
        requestUrl: endpointUri.toString(),
        requestBody: requestBody,
        responseErrorMessage: _describeError(error),
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri? _buildEndpointUri({
    required String endpoint,
    required AllNotificationsQuery query,
  }) {
    final uri = _parseEndpoint(endpoint);
    if (uri == null) {
      return null;
    }

    final queryParameters = Map<String, String>.from(uri.queryParameters);
    queryParameters['p'] = query.page.toString();

    final isFinancialTransaction = query.isFinancialTransaction;
    if (isFinancialTransaction == null) {
      queryParameters.remove('isft');
    } else {
      queryParameters['isft'] = isFinancialTransaction.toString();
    }

    final searchText = query.normalizedSearchText;
    if (searchText == null) {
      queryParameters.remove('q');
    } else {
      queryParameters['q'] = searchText;
    }

    return uri.replace(queryParameters: queryParameters);
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

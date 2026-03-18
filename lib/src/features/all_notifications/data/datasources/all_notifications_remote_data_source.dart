import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/app_http_client_factory.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/all_notifications_query.dart';
import '../models/all_notification_model.dart';
import '../models/update_notification_result_model.dart';

class AllNotificationsRemoteDataSource {
  AllNotificationsRemoteDataSource({Dio? httpClient})
    : _httpClient = httpClient ?? AppHttpClientFactory.create();

  static const String _missingEndpointMessage =
      'Backend base URL not configured. Set BACKEND_BASE_URL in .env.';
  final Dio _httpClient;

  Future<List<AllNotificationModel>> fetch({
    required String endpoint,
    required String apiKey,
    required AllNotificationsQuery query,
  }) async {
    final endpointUri = _buildEndpointUri(endpoint: endpoint, query: query);
    if (endpointUri == null) {
      throw Exception(_describeEndpointError(endpoint));
    }

    try {
      final response = await _httpClient.requestUri<String>(
        endpointUri,
        options: Options(
          method: 'GET',
          headers: <String, Object?>{
            Headers.acceptHeader: 'application/json',
            'X-API-Key': apiKey,
          },
        ),
      );
      final statusCode = response.statusCode ?? 0;
      final responseBody = _responseBody(response.data);

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          'get_all_notifications returned $statusCode: $responseBody',
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
    return describeHttpError(error);
  }

  String _responseBody(Object? data) {
    if (data == null) {
      return '';
    }

    return data is String ? data : data.toString();
  }
}

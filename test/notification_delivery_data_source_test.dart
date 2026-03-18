import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/notification_delivery_data_source.dart';

void main() {
  group('NotificationDeliveryDataSource', () {
    late HttpServer server;
    late _CapturedRequest capturedRequest;
    late int responseStatusCode;
    late String responseBody;

    setUp(() async {
      capturedRequest = _CapturedRequest.empty();
      responseStatusCode = 201;
      responseBody = '{"ok":true}';
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final requestBody = await utf8.decoder.bind(request).join();
        capturedRequest = _CapturedRequest(
          method: request.method,
          path: request.uri.path,
          apiKey: request.headers.value('X-API-Key'),
          contentType: request.headers.value(HttpHeaders.contentTypeHeader),
          body: requestBody,
        );

        request.response.statusCode = responseStatusCode;
        request.response.headers.contentType = ContentType.json;
        request.response.write(responseBody);
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('envia PUT com headers e payload json para o backend', () async {
      final dataSource = NotificationDeliveryDataSource();

      final result = await dataSource.send(
        endpoint:
            'http://${server.address.address}:${server.port}/add_notification',
        app: 'Banco XPTO',
        text: 'PIX recebido',
        apiKey: 'secret-key',
      );

      expect(capturedRequest.method, 'PUT');
      expect(capturedRequest.path, '/add_notification');
      expect(capturedRequest.apiKey, 'secret-key');
      expect(capturedRequest.contentType, contains('application/json'));
      expect(
        jsonDecode(capturedRequest.body!) as Map<String, Object?>,
        <String, Object?>{
          'app': 'Banco XPTO',
          'text': 'PIX recebido',
          'is_financial_notification': null,
        },
      );
      expect(result.statusCode, 201);
      expect(result.body, '{"ok":true}');
      expect(result.errorMessage, isNull);
    });

    test('mantem dados da resposta quando backend devolve erro', () async {
      final dataSource = NotificationDeliveryDataSource();
      responseStatusCode = 500;
      responseBody = '{"detail":"failed"}';

      final result = await dataSource.send(
        endpoint:
            'http://${server.address.address}:${server.port}/add_notification',
        app: 'Banco XPTO',
        text: 'falhou',
        apiKey: 'secret-key',
      );

      expect(result.requestUrl, contains('/add_notification'));
      expect(result.requestBody, contains('"app":"Banco XPTO"'));
      expect(result.statusCode, 500);
      expect(result.body, '{"detail":"failed"}');
      expect(result.errorMessage, isNull);
    });
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.apiKey,
    required this.contentType,
    required this.body,
  });

  const _CapturedRequest.empty()
    : method = '',
      path = '',
      apiKey = null,
      contentType = null,
      body = null;

  final String method;
  final String path;
  final String? apiKey;
  final String? contentType;
  final String? body;
}

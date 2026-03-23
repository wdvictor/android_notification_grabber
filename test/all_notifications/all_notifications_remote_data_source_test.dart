import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/all_notifications/data/datasources/all_notifications_remote_data_source.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notifications_query.dart';

void main() {
  group('AllNotificationsRemoteDataSource', () {
    late HttpServer server;
    late _CapturedRequest capturedRequest;
    late int responseStatusCode;
    late String responseBody;

    setUp(() async {
      capturedRequest = _CapturedRequest.empty();
      responseStatusCode = 200;
      responseBody = jsonEncode(<Map<String, Object?>>[
        <String, Object?>{
          'id': 'notification-1',
          'app': 'Banco XPTO',
          'text': 'PIX recebido com sucesso',
          'is_financial_transaction': true,
        },
      ]);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final requestBody = await utf8.decoder.bind(request).join();
        capturedRequest = _CapturedRequest(
          method: request.method,
          path: request.uri.path,
          apiKey: request.headers.value('X-API-Key'),
          queryParameters: Map<String, String>.from(
            request.uri.queryParameters,
          ),
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

    test('envia GET com header X-API-Key e todos os query params', () async {
      final dataSource = AllNotificationsRemoteDataSource();

      final notifications = await dataSource.fetch(
        endpoint:
            'http://${server.address.address}:${server.port}/get_all_notifications',
        apiKey: 'secret-key',
        query: const AllNotificationsQuery(
          page: 2,
          isFinancialTransaction: false,
          searchText: '  pix  ',
        ),
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.apiKey, 'secret-key');
      expect(capturedRequest.queryParameters, <String, String>{
        'p': '2',
        'isft': 'false',
        'q': 'pix',
      });
      expect(capturedRequest.path, '/get_all_notifications');
      expect(notifications.single.app, 'Banco XPTO');
      expect(notifications.single.id, 'notification-1');
      expect(notifications.single.isFinancialTransaction, isTrue);
    });

    test(
      'envia apenas p quando filtros opcionais nao forem informados',
      () async {
        final dataSource = AllNotificationsRemoteDataSource();

        await dataSource.fetch(
          endpoint:
              'http://${server.address.address}:${server.port}/get_all_notifications',
          apiKey: 'secret-key',
          query: const AllNotificationsQuery(page: 1),
        );

        expect(capturedRequest.queryParameters, <String, String>{'p': '1'});
      },
    );

    test(
      'envia PUT para update_notification com body json e trata 200 como sucesso',
      () async {
        final dataSource = AllNotificationsRemoteDataSource();
        responseBody = '{"ok":true}';

        final result = await dataSource.update(
          endpoint:
              'http://${server.address.address}:${server.port}/update_notification',
          apiKey: 'secret-key',
          id: 'notification-9',
          isFinancialTransaction: false,
        );

        expect(capturedRequest.method, 'PUT');
        expect(capturedRequest.path, '/update_notification');
        expect(capturedRequest.apiKey, 'secret-key');
        expect(
          jsonDecode(capturedRequest.body!) as Map<String, Object?>,
          <String, Object?>{
            'id': 'notification-9',
            'is_financial_transaction': false,
          },
        );
        expect(result.responseStatusCode, 200);
        expect(result.responseErrorMessage, isNull);
      },
    );

    test(
      'mantem dados de request e response quando update_notification falha',
      () async {
        final dataSource = AllNotificationsRemoteDataSource();
        responseStatusCode = 500;
        responseBody = '{"detail":"failed"}';

        final result = await dataSource.update(
          endpoint:
              'http://${server.address.address}:${server.port}/update_notification',
          apiKey: 'secret-key',
          id: 'notification-10',
          isFinancialTransaction: true,
        );

        expect(result.requestMethod, 'PUT');
        expect(result.requestUrl, contains('/update_notification'));
        expect(result.requestBody, contains('"id":"notification-10"'));
        expect(result.requestBody, contains('"is_financial_transaction":true'));
        expect(result.responseStatusCode, 500);
        expect(result.responseBody, '{"detail":"failed"}');
        expect(result.responseErrorMessage, 'update_notification returned 500');
      },
    );

    test(
      'envia DELETE para delete_notification com query id e trata 204 como sucesso',
      () async {
        final dataSource = AllNotificationsRemoteDataSource();
        responseStatusCode = 204;
        responseBody = '';

        final result = await dataSource.delete(
          endpoint:
              'http://${server.address.address}:${server.port}/delete_notification',
          apiKey: 'secret-key',
          id: 'notification-11',
        );

        expect(capturedRequest.method, 'DELETE');
        expect(capturedRequest.path, '/delete_notification');
        expect(capturedRequest.apiKey, 'secret-key');
        expect(capturedRequest.queryParameters, <String, String>{
          'id': 'notification-11',
        });
        expect(capturedRequest.body, isEmpty);
        expect(result.responseStatusCode, 204);
        expect(result.responseErrorMessage, isNull);
        expect(result.requestQuery, 'id=notification-11');
      },
    );

    test(
      'mantem dados de request e response quando delete_notification falha',
      () async {
        final dataSource = AllNotificationsRemoteDataSource();
        responseStatusCode = 500;
        responseBody = '{"detail":"failed"}';

        final result = await dataSource.delete(
          endpoint:
              'http://${server.address.address}:${server.port}/delete_notification',
          apiKey: 'secret-key',
          id: 'notification-12',
        );

        expect(result.requestMethod, 'DELETE');
        expect(
          result.requestUrl,
          contains('/delete_notification?id=notification-12'),
        );
        expect(result.requestQuery, 'id=notification-12');
        expect(result.responseStatusCode, 500);
        expect(result.responseBody, '{"detail":"failed"}');
        expect(result.responseErrorMessage, 'delete_notification returned 500');
      },
    );
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.apiKey,
    required this.queryParameters,
    required this.body,
  });

  const _CapturedRequest.empty()
    : method = '',
      path = '',
      apiKey = null,
      queryParameters = const <String, String>{},
      body = null;

  final String method;
  final String path;
  final String? apiKey;
  final Map<String, String> queryParameters;
  final String? body;
}

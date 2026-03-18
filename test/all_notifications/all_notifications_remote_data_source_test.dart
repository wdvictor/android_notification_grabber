import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/all_notifications/data/datasources/all_notifications_remote_data_source.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notifications_query.dart';

void main() {
  group('AllNotificationsRemoteDataSource', () {
    late HttpServer server;
    late _CapturedRequest capturedRequest;

    setUp(() async {
      capturedRequest = _CapturedRequest.empty();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        capturedRequest = _CapturedRequest(
          method: request.method,
          apiKey: request.headers.value('X-API-Key'),
          queryParameters: Map<String, String>.from(
            request.uri.queryParameters,
          ),
        );

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<Map<String, Object?>>[
            <String, Object?>{
              'app': 'Banco XPTO',
              'text': 'PIX recebido com sucesso',
              'is_financial_transaction': true,
            },
          ]),
        );
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
      expect(notifications.single.app, 'Banco XPTO');
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
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.apiKey,
    required this.queryParameters,
  });

  const _CapturedRequest.empty()
    : method = '',
      apiKey = null,
      queryParameters = const <String, String>{};

  final String method;
  final String? apiKey;
  final Map<String, String> queryParameters;
}

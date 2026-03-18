import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/core/network/request_logger_interceptor.dart';

void main() {
  group('RequestLoggerInterceptor', () {
    test('gera log com metodo, url, headers e payload', () {
      final messages = <String>[];
      final interceptor = RequestLoggerInterceptor(logWriter: messages.add);

      interceptor.onRequest(
        RequestOptions(
          path: '/notifications',
          baseUrl: 'https://api.example.com',
          method: 'post',
          headers: <String, Object?>{'X-API-Key': 'secret-key'},
          data: '{"app":"Banco XPTO","text":"PIX"}',
        ),
        RequestInterceptorHandler(),
      );

      expect(messages, hasLength(1));
      expect(messages.single, contains('method: POST'));
      expect(
        messages.single,
        contains('url: https://api.example.com/notifications'),
      );
      expect(messages.single, contains('"X-API-Key": "secret-key"'));
      expect(messages.single, contains('"app": "Banco XPTO"'));
      expect(messages.single, contains('"text": "PIX"'));
    });

    test('omite payload quando a requisicao nao tem corpo', () {
      final interceptor = RequestLoggerInterceptor(logWriter: (_) {});

      final message = interceptor.buildMessage(
        RequestOptions(
          path: '/health',
          baseUrl: 'https://api.example.com',
          method: 'get',
          headers: <String, Object?>{'Accept': 'application/json'},
        ),
      );

      expect(message, contains('method: GET'));
      expect(message, contains('url: https://api.example.com/health'));
      expect(message, contains('"Accept": "application/json"'));
      expect(message, isNot(contains('payload:')));
    });
  });
}

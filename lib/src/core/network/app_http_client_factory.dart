import 'package:dio/dio.dart';

import 'request_logger_interceptor.dart';

class AppHttpClientFactory {
  const AppHttpClientFactory._();

  static const Duration connectTimeout = Duration(milliseconds: 120000);
  static const Duration readTimeout = Duration(milliseconds: 120000);

  static Dio create({RequestLogWriter? logWriter}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        sendTimeout: connectTimeout,
        receiveTimeout: readTimeout,
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    dio.interceptors.add(RequestLoggerInterceptor(logWriter: logWriter));

    return dio;
  }
}

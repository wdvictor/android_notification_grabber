import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef RequestLogWriter = void Function(String message);

class RequestLoggerInterceptor extends Interceptor {
  RequestLoggerInterceptor({RequestLogWriter? logWriter})
    : _logWriter = logWriter ?? debugPrint;

  final RequestLogWriter _logWriter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logWriter(buildMessage(options));
    handler.next(options);
  }

  String buildMessage(RequestOptions options) {
    final buffer = StringBuffer()
      ..writeln('[HTTP REQUEST]')
      ..writeln('method: ${options.method.toUpperCase()}')
      ..writeln('url: ${options.uri}')
      ..writeln('headers: ${_formatValue(options.headers)}');

    if (options.data != null) {
      buffer.writeln('payload: ${_formatValue(options.data)}');
    }

    return buffer.toString().trimRight();
  }

  String _formatValue(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return value;
      }

      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
      } catch (_) {
        return value;
      }
    }

    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }

    return value.toString();
  }
}

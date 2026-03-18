import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

String describeHttpError(Object error) {
  if (error is DioException) {
    final underlyingError = error.error;
    if (underlyingError is SocketException) {
      return underlyingError.message;
    }

    if (underlyingError is HttpException) {
      return underlyingError.message;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return error.message ?? 'Connection error';
      case DioExceptionType.unknown:
        return error.message ?? 'Unknown error';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode == null
            ? 'Bad response'
            : 'Bad response: $statusCode';
    }
  }

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

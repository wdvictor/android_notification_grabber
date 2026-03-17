import '../../domain/entities/offline_notification.dart';

class RequestDetailsModel {
  const RequestDetailsModel({
    required this.method,
    required this.url,
    required this.body,
    required this.attemptedAt,
  });

  factory RequestDetailsModel.fromMap(Map<Object?, Object?> map) {
    return RequestDetailsModel(
      method: map['method'] as String? ?? 'PUT',
      url: map['url'] as String? ?? '',
      body: map['body'] as String? ?? '{}',
      attemptedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['attemptedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  factory RequestDetailsModel.fromEntity(RequestDetails entity) {
    return RequestDetailsModel(
      method: entity.method,
      url: entity.url,
      body: entity.body,
      attemptedAt: entity.attemptedAt,
    );
  }

  final String method;
  final String url;
  final String body;
  final DateTime attemptedAt;

  RequestDetails toEntity() {
    return RequestDetails(
      method: method,
      url: url,
      body: body,
      attemptedAt: attemptedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'method': method,
      'url': url,
      'body': body,
      'attemptedAt': attemptedAt.millisecondsSinceEpoch,
    };
  }
}

class ResponseDetailsModel {
  const ResponseDetailsModel({
    required this.statusCode,
    required this.body,
    required this.errorMessage,
    required this.receivedAt,
  });

  factory ResponseDetailsModel.fromMap(Map<Object?, Object?> map) {
    return ResponseDetailsModel(
      statusCode: (map['statusCode'] as num?)?.toInt(),
      body: map['body'] as String?,
      errorMessage: map['errorMessage'] as String?,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['receivedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  factory ResponseDetailsModel.fromEntity(ResponseDetails entity) {
    return ResponseDetailsModel(
      statusCode: entity.statusCode,
      body: entity.body,
      errorMessage: entity.errorMessage,
      receivedAt: entity.receivedAt,
    );
  }

  final int? statusCode;
  final String? body;
  final String? errorMessage;
  final DateTime receivedAt;

  ResponseDetails toEntity() {
    return ResponseDetails(
      statusCode: statusCode,
      body: body,
      errorMessage: errorMessage,
      receivedAt: receivedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'statusCode': statusCode,
      'body': body,
      'errorMessage': errorMessage,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
    };
  }
}

class OfflineNotificationModel {
  const OfflineNotificationModel({
    required this.id,
    required this.app,
    required this.text,
    required this.isFinancialNotification,
    required this.request,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfflineNotificationModel.fromMap(Map<Object?, Object?> map) {
    return OfflineNotificationModel(
      id: map['id'] as String? ?? '',
      app: map['app'] as String? ?? '',
      text: map['text'] as String? ?? '',
      isFinancialNotification: map['isFinancialNotification'],
      request: RequestDetailsModel.fromMap(_readMap(map['request'])),
      response: ResponseDetailsModel.fromMap(_readMap(map['response'])),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  factory OfflineNotificationModel.fromEntity(OfflineNotification entity) {
    return OfflineNotificationModel(
      id: entity.id,
      app: entity.app,
      text: entity.text,
      isFinancialNotification: entity.isFinancialNotification,
      request: RequestDetailsModel.fromEntity(entity.request),
      response: ResponseDetailsModel.fromEntity(entity.response),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  final String id;
  final String app;
  final String text;
  final Object? isFinancialNotification;
  final RequestDetailsModel request;
  final ResponseDetailsModel response;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfflineNotification toEntity() {
    return OfflineNotification(
      id: id,
      app: app,
      text: text,
      isFinancialNotification: isFinancialNotification,
      request: request.toEntity(),
      response: response.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'app': app,
      'text': text,
      'isFinancialNotification': isFinancialNotification,
      'request': request.toMap(),
      'response': response.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Map<Object?, Object?> _readMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<Object?, Object?>.from(value);
    }

    return const <Object?, Object?>{};
  }
}

import 'package:flutter/services.dart';

import '../features/notifications/application/notifications_background_facade.dart';
import '../features/notifications/data/datasources/platform_bridge_data_source.dart';
import '../features/notifications/data/models/offline_notification_model.dart';
import '../features/notifications/domain/entities/retry_results.dart';

class BackgroundChannelHandler {
  BackgroundChannelHandler(this._facade);

  final NotificationsBackgroundFacade _facade;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'getOfflineNotifications':
        final notifications = await _facade.getOfflineNotifications();
        return notifications
            .map(
              (notification) =>
                  OfflineNotificationModel.fromEntity(notification).toMap(),
            )
            .toList();
      case 'retryOfflineNotification':
        final arguments = _readArguments(call.arguments);
        final id = arguments['id'] as String?;
        if (id == null || id.trim().isEmpty) {
          throw PlatformException(
            code: 'invalid_id',
            message: 'Identificador da notificação não informado.',
          );
        }

        final result = await _facade.retryOfflineNotification(id);
        return _retryNotificationResultToMap(result);
      case 'retryAllOfflineNotifications':
        final result = await _facade.retryAllOfflineNotifications();
        return _retryAllResultToMap(result);
      case 'processCapturedNotification':
        final arguments = _readArguments(call.arguments);
        final app = arguments['app'] as String?;
        final text = arguments['text'] as String?;
        if (app == null ||
            app.trim().isEmpty ||
            text == null ||
            text.trim().isEmpty) {
          throw PlatformException(
            code: 'invalid_notification',
            message: 'Carga inválida recebida do listener Android.',
          );
        }

        final result = await _facade.processCapturedNotification(
          app: app,
          text: text,
        );
        return _retryNotificationResultToMap(result);
      default:
        throw MissingPluginException('Método não suportado: ${call.method}');
    }
  }

  Future<void> notifyReady() async {
    const channel = MethodChannel(PlatformBridgeDataSource.channelName);
    await channel.invokeMethod<void>('backgroundProcessorReady');
  }

  Map<Object?, Object?> _readArguments(Object? arguments) {
    if (arguments is Map<Object?, Object?>) {
      return arguments;
    }

    if (arguments is Map) {
      return Map<Object?, Object?>.from(arguments);
    }

    return const <Object?, Object?>{};
  }

  Map<String, Object?> _retryNotificationResultToMap(
    RetryNotificationResult result,
  ) {
    return <String, Object?>{
      'success': result.success,
      'record': result.record == null
          ? null
          : OfflineNotificationModel.fromEntity(result.record!).toMap(),
    };
  }

  Map<String, Object?> _retryAllResultToMap(RetryAllResult result) {
    return <String, Object?>{
      'successCount': result.successCount,
      'failureCount': result.failureCount,
    };
  }
}

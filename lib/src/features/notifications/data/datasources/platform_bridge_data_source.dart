import 'package:flutter/services.dart';

typedef PlatformBridgeEventHandler =
    Future<void> Function(String method, Object? arguments);

class PlatformBridgeDataSource {
  const PlatformBridgeDataSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'notification_grabber/platform';

  final MethodChannel _channel;

  void setEventHandler(PlatformBridgeEventHandler? handler) {
    if (handler == null) {
      _channel.setMethodCallHandler(null);
      return;
    }

    _channel.setMethodCallHandler(
      (call) => handler(call.method, call.arguments),
    );
  }

  Future<Map<Object?, Object?>> getAppBootstrap() async {
    return await _channel.invokeMapMethod<Object?, Object?>(
          'getAppBootstrap',
        ) ??
        const <Object?, Object?>{};
  }

  Future<List<Map<Object?, Object?>>> getInstalledApplications() async {
    final rawList =
        await _channel.invokeListMethod<Object?>('getInstalledApplications') ??
        const <Object?>[];

    return rawList
        .map((value) => value is Map ? Map<Object?, Object?>.from(value) : null)
        .whereType<Map<Object?, Object?>>()
        .toList(growable: false);
  }

  Future<void> openNotificationAccessSettings() {
    return _channel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<Map<Object?, Object?>> retryAllOfflineNotifications() async {
    return await _channel.invokeMapMethod<Object?, Object?>(
          'retryAllOfflineNotifications',
        ) ??
        const <Object?, Object?>{};
  }

  Future<Map<Object?, Object?>> retryOfflineNotification(String id) async {
    return await _channel.invokeMapMethod<Object?, Object?>(
          'retryOfflineNotification',
          <String, Object?>{'id': id},
        ) ??
        const <Object?, Object?>{};
  }

  Future<String> getApiKey() async {
    return await _channel.invokeMethod<String>('getApiKey') ?? '';
  }

  Future<String> getBackendBaseUrl() async {
    return await _channel.invokeMethod<String>('getBackendBaseUrl') ?? '';
  }

  Future<void> broadcastOfflineNotificationsChanged() {
    return _channel.invokeMethod<void>('broadcastOfflineNotificationsChanged');
  }
}

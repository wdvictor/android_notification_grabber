import 'package:flutter/services.dart';

import '../models/offline_notification.dart';

typedef PlatformEventHandler = Future<void> Function(MethodCall call);

class PlatformBridge {
  const PlatformBridge() : _channel = const MethodChannel(_channelName);

  static const String _channelName = 'notification_graber/platform';

  final MethodChannel _channel;

  void setMethodCallHandler(PlatformEventHandler handler) {
    _channel.setMethodCallHandler(handler);
  }

  Future<AppSnapshot> getSnapshot() async {
    final raw =
        await _channel.invokeMapMethod<Object?, Object?>('getAppBootstrap') ??
        const <Object?, Object?>{};

    return AppSnapshot.fromMap(raw);
  }

  Future<void> openNotificationAccessSettings() {
    return _channel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<bool> requestNotificationPermission() async {
    return await _channel.invokeMethod<bool>('requestNotificationPermission') ??
        true;
  }

  Future<RetryAllResult> retryAllOfflineNotifications() async {
    final raw =
        await _channel.invokeMapMethod<Object?, Object?>(
          'retryAllOfflineNotifications',
        ) ??
        const <Object?, Object?>{};

    return RetryAllResult.fromMap(raw);
  }

  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    final raw =
        await _channel.invokeMapMethod<Object?, Object?>(
          'retryOfflineNotification',
          <String, Object?>{'id': id},
        ) ??
        const <Object?, Object?>{};

    return RetryNotificationResult.fromMap(raw);
  }
}

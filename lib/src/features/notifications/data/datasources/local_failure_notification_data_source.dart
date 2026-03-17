import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalFailureNotificationDataSource {
  LocalFailureNotificationDataSource({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'delivery_failures';
  static const String _channelName = 'Falhas de envio';
  static const String _channelDescription =
      'Exibe falhas ao entregar notificações ao backend';
  static const String _defaultIcon = 'ic_stat_notify_error';
  static const String _notificationTitle = 'Backend não recebeu a notificação';
  static const String _notificationDetailsText =
      'Toque para ver os detalhes da última tentativa com falha.';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _selectedNotificationIds =
      StreamController<String>.broadcast();

  bool _initialized = false;

  Stream<String> get selectedNotificationIds => _selectedNotificationIds.stream;

  Future<String?> initializeForeground() async {
    await _initialize(onDidReceiveNotificationResponse: _handleResponse);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    return _normalizePayload(launchDetails?.notificationResponse?.payload);
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _androidPlugin;
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<bool> requestPermission() async {
    final android = _androidPlugin;
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> showFailureNotification({
    required String id,
    required String app,
  }) async {
    await _initialize();

    await _plugin.show(
      id: id.hashCode,
      title: _notificationTitle,
      body: app,
      payload: id,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: _defaultIcon,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(_notificationDetailsText),
          autoCancel: true,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _selectedNotificationIds.close();
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    if (kIsWeb) {
      return null;
    }

    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  Future<void> _initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    if (_initialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_defaultIcon),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    _initialized = true;
  }

  void _handleResponse(NotificationResponse response) {
    final id = _normalizePayload(response.payload);
    if (id == null || _selectedNotificationIds.isClosed) {
      return;
    }

    _selectedNotificationIds.add(id);
  }

  String? _normalizePayload(String? payload) {
    final value = payload?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}

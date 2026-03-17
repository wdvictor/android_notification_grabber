import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/offline_notification.dart';
import '../services/platform_bridge.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController(this._platformBridge) {
    _platformBridge.setMethodCallHandler(_handlePlatformCall);
  }

  final PlatformBridge _platformBridge;

  bool _initialized = false;
  bool _isLoading = true;
  bool _isRetryingAll = false;
  bool _notificationAccessGranted = false;
  bool _notificationPermissionGranted = true;
  List<OfflineNotification> _offlineNotifications = const [];
  String? _pendingNavigationTargetId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isRetryingAll => _isRetryingAll;
  bool get notificationAccessGranted => _notificationAccessGranted;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  List<OfflineNotification> get offlineNotifications => _offlineNotifications;
  String? get errorMessage => _errorMessage;

  OfflineNotification? findNotificationById(String id) {
    for (final notification in _offlineNotifications) {
      if (notification.id == id) {
        return notification;
      }
    }

    return null;
  }

  String? takePendingNavigationTarget() {
    final target = _pendingNavigationTargetId;
    _pendingNavigationTargetId = null;
    return target;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _platformBridge.getSnapshot();
      _notificationAccessGranted = snapshot.notificationAccessGranted;
      _notificationPermissionGranted = snapshot.notificationPermissionGranted;
      _offlineNotifications = snapshot.offlineNotifications;
      _pendingNavigationTargetId ??= snapshot.pendingFailedNotificationId;
      _errorMessage = null;
    } on PlatformException catch (error) {
      _errorMessage = error.message ?? error.code;
    } on MissingPluginException {
      _errorMessage = 'Integração Android indisponível nesta plataforma.';
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openNotificationAccessSettings() {
    return _platformBridge.openNotificationAccessSettings();
  }

  Future<void> requestNotificationPermission() async {
    final isGranted = await _platformBridge.requestNotificationPermission();
    _notificationPermissionGranted = isGranted;
    notifyListeners();

    unawaited(refresh());
  }

  Future<RetryAllResult> retryAllOfflineNotifications() async {
    _isRetryingAll = true;
    notifyListeners();

    try {
      final result = await _platformBridge.retryAllOfflineNotifications();
      await refresh();
      return result;
    } finally {
      _isRetryingAll = false;
      notifyListeners();
    }
  }

  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    final result = await _platformBridge.retryOfflineNotification(id);
    await refresh();
    return result;
  }

  Future<void> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'offlineNotificationsChanged':
        await refresh();
        return;
      case 'failedNotificationSelected':
        final arguments = call.arguments;
        if (arguments is Map<Object?, Object?>) {
          _pendingNavigationTargetId = arguments['id'] as String?;
        } else if (arguments is String) {
          _pendingNavigationTargetId = arguments;
        }

        notifyListeners();
        return;
      default:
        return;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

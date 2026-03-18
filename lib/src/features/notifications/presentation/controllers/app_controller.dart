import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../application/notifications_presentation_facade.dart';
import '../../domain/entities/app_state_snapshot.dart';
import '../../domain/entities/offline_notification.dart';
import '../../domain/entities/retry_results.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController(this._facade) {
    _facade.setOnOfflineNotificationsChanged(_refreshFromPlatformEvent);
    _selectedNotificationSubscription = _facade.selectedNotificationIds.listen(
      _handleSelectedNotification,
    );
  }

  final NotificationsPresentationFacade _facade;
  late final StreamSubscription<String> _selectedNotificationSubscription;

  bool _initialized = false;
  bool _isLoading = true;
  bool _isRetryingAll = false;
  bool _isDeletingAll = false;
  bool _notificationAccessGranted = false;
  bool _notificationPermissionGranted = true;
  List<OfflineNotification> _offlineNotifications = const [];
  Set<String> _deletingNotificationIds = const <String>{};
  String? _pendingNavigationTargetId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isRetryingAll => _isRetryingAll;
  bool get isDeletingAll => _isDeletingAll;
  bool get isDeletingAnyNotification => _deletingNotificationIds.isNotEmpty;
  bool get notificationAccessGranted => _notificationAccessGranted;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  List<OfflineNotification> get offlineNotifications => _offlineNotifications;
  String? get errorMessage => _errorMessage;

  bool isDeletingNotification(String id) {
    return _deletingNotificationIds.contains(id);
  }

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
    _pendingNavigationTargetId ??= await _facade
        .initializeForegroundNotifications();
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _facade.loadState();
      _applySnapshot(snapshot);
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
    return _facade.openNotificationAccessSettings();
  }

  Future<void> requestNotificationPermission() async {
    final isGranted = await _facade.requestNotificationPermission();
    _notificationPermissionGranted = isGranted;
    notifyListeners();

    unawaited(refresh());
  }

  Future<RetryAllResult> retryAllOfflineNotifications() async {
    _isRetryingAll = true;
    notifyListeners();

    try {
      final result = await _facade.retryAllOfflineNotifications();
      await refresh();
      return result;
    } finally {
      _isRetryingAll = false;
      notifyListeners();
    }
  }

  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    final result = await _facade.retryOfflineNotification(id);
    await refresh();
    return result;
  }

  Future<bool> deleteOfflineNotification(String id) async {
    _deletingNotificationIds = {..._deletingNotificationIds, id};
    notifyListeners();

    try {
      final deleted = await _facade.deleteOfflineNotification(id);
      await refresh();
      return deleted;
    } finally {
      _deletingNotificationIds = {
        for (final currentId in _deletingNotificationIds)
          if (currentId != id) currentId,
      };
      notifyListeners();
    }
  }

  Future<int> deleteAllOfflineNotifications() async {
    _isDeletingAll = true;
    notifyListeners();

    try {
      final deletedCount = await _facade.deleteAllOfflineNotifications();
      await refresh();
      return deletedCount;
    } finally {
      _isDeletingAll = false;
      notifyListeners();
    }
  }

  void _applySnapshot(AppStateSnapshot snapshot) {
    _notificationAccessGranted = snapshot.notificationAccessGranted;
    _notificationPermissionGranted = snapshot.notificationPermissionGranted;
    _offlineNotifications = snapshot.offlineNotifications;
  }

  Future<void> _refreshFromPlatformEvent() async {
    await refresh();
  }

  void _handleSelectedNotification(String id) {
    _pendingNavigationTargetId = id;
    notifyListeners();
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
    _facade.setOnOfflineNotificationsChanged(null);
    _selectedNotificationSubscription.cancel();
    unawaited(_facade.dispose());
    super.dispose();
  }
}

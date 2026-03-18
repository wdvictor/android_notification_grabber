import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../application/notifications_presentation_facade.dart';
import '../../domain/entities/app_state_snapshot.dart';
import '../../domain/entities/installed_app.dart';
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
  bool _isLoadingInstalledApps = false;
  bool _installedAppsLoaded = false;
  bool _notificationAccessGranted = false;
  bool _notificationPermissionGranted = true;
  List<OfflineNotification> _offlineNotifications = const [];
  List<InstalledApp> _installedApps = const [];
  Set<String> _deletingNotificationIds = const <String>{};
  Set<String> _updatingIgnoredAppPackageNames = const <String>{};
  String? _pendingNavigationTargetId;
  String? _errorMessage;
  String? _installedAppsErrorMessage;

  bool get isLoading => _isLoading;
  bool get isRetryingAll => _isRetryingAll;
  bool get isDeletingAll => _isDeletingAll;
  bool get isLoadingInstalledApps => _isLoadingInstalledApps;
  bool get isDeletingAnyNotification => _deletingNotificationIds.isNotEmpty;
  bool get notificationAccessGranted => _notificationAccessGranted;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  List<OfflineNotification> get offlineNotifications => _offlineNotifications;
  List<InstalledApp> get installedApps => _installedApps;
  List<InstalledApp> get ignoredApps =>
      _installedApps.where((app) => app.isIgnored).toList(growable: false);
  String? get errorMessage => _errorMessage;
  String? get installedAppsErrorMessage => _installedAppsErrorMessage;

  bool isDeletingNotification(String id) {
    return _deletingNotificationIds.contains(id);
  }

  bool isUpdatingIgnoredApp(String packageName) {
    return _updatingIgnoredAppPackageNames.contains(packageName);
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

  Future<void> ensureInstalledAppsLoaded() async {
    if (_installedAppsLoaded) {
      return;
    }

    await refreshInstalledApps();
  }

  Future<void> refreshInstalledApps() async {
    _isLoadingInstalledApps = true;
    notifyListeners();

    try {
      final apps = await _facade.loadInstalledApps();
      _installedApps = apps;
      _installedAppsLoaded = true;
      _installedAppsErrorMessage = null;
    } on PlatformException catch (error) {
      _installedAppsErrorMessage = error.message ?? error.code;
    } on MissingPluginException {
      _installedAppsErrorMessage =
          'Integração Android indisponível nesta plataforma.';
    } catch (error) {
      _installedAppsErrorMessage = error.toString();
    } finally {
      _isLoadingInstalledApps = false;
      notifyListeners();
    }
  }

  Future<void> setAppIgnored({
    required String packageName,
    required bool isIgnored,
  }) async {
    _updatingIgnoredAppPackageNames = {
      ..._updatingIgnoredAppPackageNames,
      packageName,
    };
    notifyListeners();

    try {
      if (isIgnored) {
        await _facade.addIgnoredApp(packageName);
      } else {
        await _facade.removeIgnoredApp(packageName);
      }

      _installedApps = _sortInstalledApps(
        _installedApps
            .map((app) {
              if (app.packageName != packageName) {
                return app;
              }

              return app.copyWith(isIgnored: isIgnored);
            })
            .toList(growable: false),
      );
      _installedAppsLoaded = true;
      _installedAppsErrorMessage = null;
    } finally {
      _updatingIgnoredAppPackageNames = {
        for (final currentPackageName in _updatingIgnoredAppPackageNames)
          if (currentPackageName != packageName) currentPackageName,
      };
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
      if (_installedAppsLoaded) {
        unawaited(refreshInstalledApps());
      }
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

  List<InstalledApp> _sortInstalledApps(List<InstalledApp> apps) {
    final sortedApps = apps.toList();
    sortedApps.sort((left, right) {
      if (left.isIgnored != right.isIgnored) {
        return left.isIgnored ? -1 : 1;
      }

      final nameComparison = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );
      if (nameComparison != 0) {
        return nameComparison;
      }

      return left.packageName.toLowerCase().compareTo(
        right.packageName.toLowerCase(),
      );
    });
    return sortedApps;
  }
}

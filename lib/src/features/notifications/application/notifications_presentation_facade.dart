import '../../notifications/data/datasources/platform_bridge_data_source.dart';
import '../domain/entities/app_state_snapshot.dart';
import '../domain/entities/retry_results.dart';
import '../domain/repositories/app_bridge_repository.dart';
import '../domain/repositories/failure_notification_repository.dart';

abstract interface class NotificationsPresentationFacade {
  Stream<String> get selectedNotificationIds;
  void setOnOfflineNotificationsChanged(Future<void> Function()? onChanged);
  Future<String?> initializeForegroundNotifications();
  Future<AppStateSnapshot> loadState();
  Future<void> openNotificationAccessSettings();
  Future<bool> requestNotificationPermission();
  Future<RetryAllResult> retryAllOfflineNotifications();
  Future<RetryNotificationResult> retryOfflineNotification(String id);
  Future<void> dispose();
}

class NotificationsPresentationFacadeImpl
    implements NotificationsPresentationFacade {
  NotificationsPresentationFacadeImpl({
    required PlatformBridgeDataSource platformBridgeDataSource,
    required AppBridgeRepository appBridgeRepository,
    required FailureNotificationRepository failureNotificationRepository,
  }) : _platformBridgeDataSource = platformBridgeDataSource,
       _appBridgeRepository = appBridgeRepository,
       _failureNotificationRepository = failureNotificationRepository;

  final PlatformBridgeDataSource _platformBridgeDataSource;
  final AppBridgeRepository _appBridgeRepository;
  final FailureNotificationRepository _failureNotificationRepository;

  @override
  Stream<String> get selectedNotificationIds =>
      _failureNotificationRepository.selectedNotificationIds;

  @override
  void setOnOfflineNotificationsChanged(Future<void> Function()? onChanged) {
    _platformBridgeDataSource.setEventHandler(
      onChanged == null
          ? null
          : (method, _) async {
              if (method == 'offlineNotificationsChanged') {
                await onChanged();
              }
            },
    );
  }

  @override
  Future<String?> initializeForegroundNotifications() {
    return _failureNotificationRepository.initializeForeground();
  }

  @override
  Future<AppStateSnapshot> loadState() async {
    final bridgeSnapshotFuture = _appBridgeRepository.getBridgeSnapshot();
    final permissionFuture = _failureNotificationRepository
        .areNotificationsEnabled();

    final bridgeSnapshot = await bridgeSnapshotFuture;
    final notificationPermissionGranted = await permissionFuture;

    return AppStateSnapshot(
      notificationAccessGranted: bridgeSnapshot.notificationAccessGranted,
      notificationPermissionGranted: notificationPermissionGranted,
      offlineNotifications: bridgeSnapshot.offlineNotifications,
    );
  }

  @override
  Future<void> openNotificationAccessSettings() {
    return _appBridgeRepository.openNotificationAccessSettings();
  }

  @override
  Future<bool> requestNotificationPermission() {
    return _failureNotificationRepository.requestPermission();
  }

  @override
  Future<RetryAllResult> retryAllOfflineNotifications() {
    return _appBridgeRepository.retryAllOfflineNotifications();
  }

  @override
  Future<RetryNotificationResult> retryOfflineNotification(String id) {
    return _appBridgeRepository.retryOfflineNotification(id);
  }

  @override
  Future<void> dispose() {
    return _failureNotificationRepository.dispose();
  }
}

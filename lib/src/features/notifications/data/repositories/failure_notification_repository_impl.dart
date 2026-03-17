import '../../domain/entities/offline_notification.dart';
import '../../domain/repositories/failure_notification_repository.dart';
import '../datasources/local_failure_notification_data_source.dart';

class FailureNotificationRepositoryImpl
    implements FailureNotificationRepository {
  FailureNotificationRepositoryImpl(this._localFailureNotificationDataSource);

  final LocalFailureNotificationDataSource _localFailureNotificationDataSource;

  @override
  Stream<String> get selectedNotificationIds =>
      _localFailureNotificationDataSource.selectedNotificationIds;

  @override
  Future<String?> initializeForeground() {
    return _localFailureNotificationDataSource.initializeForeground();
  }

  @override
  Future<bool> areNotificationsEnabled() {
    return _localFailureNotificationDataSource.areNotificationsEnabled();
  }

  @override
  Future<bool> requestPermission() {
    return _localFailureNotificationDataSource.requestPermission();
  }

  @override
  Future<void> showFailureNotification(OfflineNotification notification) {
    return _localFailureNotificationDataSource.showFailureNotification(
      id: notification.id,
      app: notification.app,
    );
  }

  @override
  Future<void> dispose() {
    return _localFailureNotificationDataSource.dispose();
  }
}

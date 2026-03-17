import '../domain/entities/offline_notification.dart';
import '../domain/entities/retry_results.dart';
import '../domain/repositories/notification_processing_repository.dart';

abstract interface class NotificationsBackgroundFacade {
  Future<List<OfflineNotification>> getOfflineNotifications();
  Future<RetryNotificationResult> retryOfflineNotification(String id);
  Future<RetryAllResult> retryAllOfflineNotifications();
  Future<RetryNotificationResult> processCapturedNotification({
    required String app,
    required String text,
  });
}

class NotificationsBackgroundFacadeImpl
    implements NotificationsBackgroundFacade {
  NotificationsBackgroundFacadeImpl(this._notificationProcessingRepository);

  final NotificationProcessingRepository _notificationProcessingRepository;

  @override
  Future<List<OfflineNotification>> getOfflineNotifications() {
    return _notificationProcessingRepository.getOfflineNotifications();
  }

  @override
  Future<RetryNotificationResult> retryOfflineNotification(String id) {
    return _notificationProcessingRepository.retryOfflineNotification(id);
  }

  @override
  Future<RetryAllResult> retryAllOfflineNotifications() {
    return _notificationProcessingRepository.retryAllOfflineNotifications();
  }

  @override
  Future<RetryNotificationResult> processCapturedNotification({
    required String app,
    required String text,
  }) {
    return _notificationProcessingRepository.processCapturedNotification(
      app: app,
      text: text,
    );
  }
}

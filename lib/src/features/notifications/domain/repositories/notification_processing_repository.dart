import '../entities/offline_notification.dart';
import '../entities/retry_results.dart';

abstract interface class NotificationProcessingRepository {
  Future<List<OfflineNotification>> getOfflineNotifications();
  Future<RetryAllResult> retryAllOfflineNotifications();
  Future<RetryNotificationResult> retryOfflineNotification(String id);
  Future<RetryNotificationResult> processCapturedNotification({
    required String app,
    required String text,
  });
}

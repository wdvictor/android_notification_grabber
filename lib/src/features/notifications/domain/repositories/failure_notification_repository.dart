import '../entities/offline_notification.dart';

abstract interface class FailureNotificationRepository {
  Stream<String> get selectedNotificationIds;
  Future<String?> initializeForeground();
  Future<bool> areNotificationsEnabled();
  Future<bool> requestPermission();
  Future<void> showFailureNotification(OfflineNotification notification);
  Future<void> dispose();
}

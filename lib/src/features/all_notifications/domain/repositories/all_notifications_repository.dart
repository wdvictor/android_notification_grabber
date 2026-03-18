import '../entities/all_notification.dart';
import '../entities/all_notifications_query.dart';
import '../entities/update_notification_result.dart';

abstract interface class AllNotificationsRepository {
  Future<List<AllNotification>> getAllNotifications(
    AllNotificationsQuery query,
  );

  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  });
}

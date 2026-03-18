import '../entities/all_notification.dart';
import '../entities/all_notifications_query.dart';

abstract interface class AllNotificationsRepository {
  Future<List<AllNotification>> getAllNotifications(
    AllNotificationsQuery query,
  );
}

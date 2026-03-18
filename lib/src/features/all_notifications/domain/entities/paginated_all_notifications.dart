import 'all_notification.dart';
import 'all_notifications_query.dart';

class PaginatedAllNotifications {
  const PaginatedAllNotifications({required this.query, required this.items});

  final AllNotificationsQuery query;
  final List<AllNotification> items;

  bool get hasNextPage => items.length >= 100;
}

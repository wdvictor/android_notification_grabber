import '../domain/entities/all_notifications_query.dart';
import '../domain/entities/delete_notification_result.dart';
import '../domain/entities/paginated_all_notifications.dart';
import '../domain/entities/update_notification_result.dart';
import '../domain/repositories/all_notifications_repository.dart';

abstract interface class AllNotificationsFacade {
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query);
  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  });
  Future<DeleteNotificationResult> deleteNotification({required String id});
}

class AllNotificationsFacadeImpl implements AllNotificationsFacade {
  const AllNotificationsFacadeImpl(this._repository);

  final AllNotificationsRepository _repository;

  @override
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query) async {
    final normalizedQuery = query.page > 0 ? query : query.copyWith(page: 1);
    final items = await _repository.getAllNotifications(normalizedQuery);

    return PaginatedAllNotifications(query: normalizedQuery, items: items);
  }

  @override
  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  }) {
    return _repository.updateNotification(
      id: id,
      isFinancialTransaction: isFinancialTransaction,
    );
  }

  @override
  Future<DeleteNotificationResult> deleteNotification({required String id}) {
    return _repository.deleteNotification(id: id);
  }
}

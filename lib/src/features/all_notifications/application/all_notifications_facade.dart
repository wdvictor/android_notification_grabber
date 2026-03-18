import '../domain/entities/all_notifications_query.dart';
import '../domain/entities/paginated_all_notifications.dart';
import '../domain/repositories/all_notifications_repository.dart';

abstract interface class AllNotificationsFacade {
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query);
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
}

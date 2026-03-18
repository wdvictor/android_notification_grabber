import 'package:flutter/foundation.dart';

import '../../application/all_notifications_facade.dart';
import '../../domain/entities/all_notification.dart';
import '../../domain/entities/all_notifications_query.dart';
import '../../domain/entities/paginated_all_notifications.dart';
import '../../domain/entities/update_notification_result.dart';

enum FinancialTransactionFilterOption {
  any('Todos', null),
  onlyTrue('True', true),
  onlyFalse('False', false);

  const FinancialTransactionFilterOption(this.label, this.value);

  final String label;
  final bool? value;
}

class AllNotificationsController extends ChangeNotifier {
  AllNotificationsController(this._facade);

  final AllNotificationsFacade _facade;

  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _updatingNotificationIds = const <String>{};
  FinancialTransactionFilterOption _selectedFilter =
      FinancialTransactionFilterOption.any;
  PaginatedAllNotifications _page = const PaginatedAllNotifications(
    query: AllNotificationsQuery(),
    items: [],
  );

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _page.query.page;
  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage => _page.hasNextPage;
  bool get isUpdatingAnyNotification => _updatingNotificationIds.isNotEmpty;
  String get currentSearchText => _page.query.normalizedSearchText ?? '';
  FinancialTransactionFilterOption get selectedFilter => _selectedFilter;
  List<AllNotification> get notifications => _page.items;

  bool isUpdatingNotification(String id) {
    return _updatingNotificationIds.contains(id);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _load(const AllNotificationsQuery(page: 1));
  }

  Future<void> refresh() {
    return _load(_page.query);
  }

  Future<void> applyFilters({
    required String searchText,
    required FinancialTransactionFilterOption filter,
  }) async {
    _selectedFilter = filter;
    await _load(
      AllNotificationsQuery(
        page: 1,
        isFinancialTransaction: filter.value,
        searchText: searchText,
      ),
    );
  }

  Future<void> goToNextPage() async {
    if (_isLoading || !hasNextPage) {
      return;
    }

    await _load(_page.query.copyWith(page: currentPage + 1));
  }

  Future<void> goToPreviousPage() async {
    if (_isLoading || !hasPreviousPage) {
      return;
    }

    await _load(_page.query.copyWith(page: currentPage - 1));
  }

  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  }) async {
    _updatingNotificationIds = {..._updatingNotificationIds, id};
    notifyListeners();

    try {
      final result = await _facade.updateNotification(
        id: id,
        isFinancialTransaction: isFinancialTransaction,
      );

      if (result.isSuccess) {
        _page = PaginatedAllNotifications(
          query: _page.query,
          items: _page.items
              .map((notification) {
                if (notification.id != id) {
                  return notification;
                }

                return AllNotification(
                  id: notification.id,
                  app: notification.app,
                  text: notification.text,
                  isFinancialTransaction: isFinancialTransaction,
                );
              })
              .toList(growable: false),
        );
        notifyListeners();
      }

      return result;
    } finally {
      _updatingNotificationIds = {
        for (final currentId in _updatingNotificationIds)
          if (currentId != id) currentId,
      };
      notifyListeners();
    }
  }

  Future<void> _load(AllNotificationsQuery query) async {
    _isLoading = true;
    _errorMessage = null;
    _page = PaginatedAllNotifications(query: query, items: const []);
    notifyListeners();

    try {
      _page = await _facade.load(query);
      _selectedFilter = _mapFilter(_page.query.isFinancialTransaction);
    } catch (error) {
      _errorMessage = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  FinancialTransactionFilterOption _mapFilter(bool? value) {
    if (value == true) {
      return FinancialTransactionFilterOption.onlyTrue;
    }

    if (value == false) {
      return FinancialTransactionFilterOption.onlyFalse;
    }

    return FinancialTransactionFilterOption.any;
  }

  String _describeError(Object error) {
    final message = error.toString();
    const prefix = 'Exception: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }

    return message;
  }
}

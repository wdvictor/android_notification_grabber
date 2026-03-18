import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/all_notifications/application/all_notifications_facade.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notification.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notifications_query.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/paginated_all_notifications.dart';
import 'package:notification_grabber/src/features/all_notifications/presentation/controllers/all_notifications_controller.dart';

void main() {
  group('AllNotificationsController', () {
    test(
      'carrega pagina 1 por padrao e habilita proxima pagina com lote de 100 itens',
      () async {
        final facade = _FakeAllNotificationsFacade(
          responsesByPage: <int, List<AllNotification>>{
            1: _buildNotifications(100),
          },
        );
        final controller = AllNotificationsController(facade);

        await controller.initialize();

        expect(controller.currentPage, 1);
        expect(controller.notifications, hasLength(100));
        expect(controller.hasNextPage, isTrue);
        expect(controller.hasPreviousPage, isFalse);
        expect(facade.receivedQueries.single.page, 1);
      },
    );

    test('aplicar filtros reseta para pagina 1 e envia q e isft', () async {
      final facade = _FakeAllNotificationsFacade(
        responsesByPage: <int, List<AllNotification>>{
          1: _buildNotifications(100),
          2: _buildNotifications(12),
        },
      );
      final controller = AllNotificationsController(facade);

      await controller.initialize();
      await controller.goToNextPage();
      await controller.applyFilters(
        searchText: '  pix recebido  ',
        filter: FinancialTransactionFilterOption.onlyFalse,
      );

      final lastQuery = facade.receivedQueries.last;

      expect(controller.currentPage, 1);
      expect(
        controller.selectedFilter,
        FinancialTransactionFilterOption.onlyFalse,
      );
      expect(lastQuery.page, 1);
      expect(lastQuery.normalizedSearchText, 'pix recebido');
      expect(lastQuery.isFinancialTransaction, isFalse);
    });
  });
}

class _FakeAllNotificationsFacade implements AllNotificationsFacade {
  _FakeAllNotificationsFacade({
    required Map<int, List<AllNotification>> responsesByPage,
  }) : _responsesByPage = responsesByPage;

  final Map<int, List<AllNotification>> _responsesByPage;
  final List<AllNotificationsQuery> receivedQueries = <AllNotificationsQuery>[];

  @override
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query) async {
    receivedQueries.add(query);
    return PaginatedAllNotifications(
      query: query,
      items: _responsesByPage[query.page] ?? const <AllNotification>[],
    );
  }
}

List<AllNotification> _buildNotifications(int count) {
  return List<AllNotification>.generate(
    count,
    (index) => AllNotification(
      app: 'Banco $index',
      text: 'Mensagem da notificacao $index',
      isFinancialTransaction: index.isEven,
    ),
    growable: false,
  );
}

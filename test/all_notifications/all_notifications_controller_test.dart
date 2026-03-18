import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/all_notifications/application/all_notifications_facade.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notification.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notifications_query.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/paginated_all_notifications.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/update_notification_result.dart';
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

    test(
      'atualiza o cache local quando update_notification retorna 200 sem recarregar a lista',
      () async {
        final facade = _FakeAllNotificationsFacade(
          responsesByPage: <int, List<AllNotification>>{
            1: _buildNotifications(2),
          },
          updateResult: const UpdateNotificationResult(
            notificationId: 'notification-0',
            isFinancialTransaction: true,
            requestMethod: 'PUT',
            requestUrl: 'https://example.com/update_notification',
            requestBody:
                '{"id":"notification-0","is_financial_transaction":true}',
            responseStatusCode: 200,
            responseBody: '{"ok":true}',
          ),
        );
        final controller = AllNotificationsController(facade);

        await controller.initialize();
        final result = await controller.updateNotification(
          id: 'notification-0',
          isFinancialTransaction: true,
        );

        expect(result.isSuccess, isTrue);
        expect(controller.notifications.first.id, 'notification-0');
        expect(controller.notifications.first.isFinancialTransaction, isTrue);
        expect(facade.receivedQueries, hasLength(1));
        expect(facade.updateCalls, 1);
      },
    );

    test(
      'atualiza o cache local para false quando update_notification retorna 200 sem recarregar a lista',
      () async {
        final facade = _FakeAllNotificationsFacade(
          responsesByPage: <int, List<AllNotification>>{
            1: _buildNotifications(2),
          },
          updateResult: const UpdateNotificationResult(
            notificationId: 'notification-0',
            isFinancialTransaction: false,
            requestMethod: 'PUT',
            requestUrl: 'https://example.com/update_notification',
            requestBody:
                '{"id":"notification-0","is_financial_transaction":false}',
            responseStatusCode: 200,
            responseBody: '{"ok":true}',
          ),
        );
        final controller = AllNotificationsController(facade);

        await controller.initialize();
        final result = await controller.updateNotification(
          id: 'notification-0',
          isFinancialTransaction: false,
        );

        expect(result.isSuccess, isTrue);
        expect(controller.notifications.first.id, 'notification-0');
        expect(controller.notifications.first.isFinancialTransaction, isFalse);
        expect(facade.receivedQueries, hasLength(1));
        expect(facade.updateCalls, 1);
      },
    );

    test(
      'mantem o cache local e nao recarrega a lista quando update_notification falha',
      () async {
        final facade = _FakeAllNotificationsFacade(
          responsesByPage: <int, List<AllNotification>>{
            1: _buildNotifications(2),
          },
          updateResult: const UpdateNotificationResult(
            notificationId: 'notification-0',
            isFinancialTransaction: false,
            requestMethod: 'PUT',
            requestUrl: 'https://example.com/update_notification',
            requestBody:
                '{"id":"notification-0","is_financial_transaction":false}',
            responseStatusCode: 500,
            responseBody: '{"detail":"failed"}',
            responseErrorMessage: 'update_notification returned 500',
          ),
        );
        final controller = AllNotificationsController(facade);

        await controller.initialize();
        final result = await controller.updateNotification(
          id: 'notification-0',
          isFinancialTransaction: false,
        );

        expect(result.isSuccess, isFalse);
        expect(controller.notifications.first.id, 'notification-0');
        expect(controller.notifications.first.isFinancialTransaction, isTrue);
        expect(facade.receivedQueries, hasLength(1));
        expect(facade.updateCalls, 1);
      },
    );
  });
}

class _FakeAllNotificationsFacade implements AllNotificationsFacade {
  _FakeAllNotificationsFacade({
    required Map<int, List<AllNotification>> responsesByPage,
    UpdateNotificationResult? updateResult,
  }) : _responsesByPage = responsesByPage,
       _updateResult =
           updateResult ??
           const UpdateNotificationResult(
             notificationId: '',
             isFinancialTransaction: false,
             requestMethod: 'PUT',
             requestUrl: 'https://example.com/update_notification',
             requestBody: '{}',
             responseStatusCode: 200,
           );

  final Map<int, List<AllNotification>> _responsesByPage;
  final UpdateNotificationResult _updateResult;
  final List<AllNotificationsQuery> receivedQueries = <AllNotificationsQuery>[];
  int updateCalls = 0;

  @override
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query) async {
    receivedQueries.add(query);
    return PaginatedAllNotifications(
      query: query,
      items: _responsesByPage[query.page] ?? const <AllNotification>[],
    );
  }

  @override
  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  }) async {
    updateCalls += 1;
    return _updateResult;
  }
}

List<AllNotification> _buildNotifications(int count) {
  return List<AllNotification>.generate(
    count,
    (index) => AllNotification(
      id: 'notification-$index',
      app: 'Banco $index',
      text: 'Mensagem da notificacao $index',
      isFinancialTransaction: index.isEven,
    ),
    growable: false,
  );
}

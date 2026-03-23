import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/all_notifications/application/all_notifications_facade.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notification.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/all_notifications_query.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/delete_notification_result.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/paginated_all_notifications.dart';
import 'package:notification_grabber/src/features/all_notifications/domain/entities/update_notification_result.dart';
import 'package:notification_grabber/src/features/all_notifications/presentation/controllers/all_notifications_controller.dart';
import 'package:notification_grabber/src/features/all_notifications/presentation/pages/all_notifications_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AllNotificationsPage', () {
    testWidgets(
      'ao confirmar transacao financeira atualiza o chip, envia update e nao reabre get_all_notifications',
      (tester) async {
        final facade = _FakeAllNotificationsFacade(
          initialNotifications: const <AllNotification>[
            AllNotification(
              id: 'notification-1',
              app: 'Banco XPTO',
              text: 'PIX recebido',
              isFinancialTransaction: null,
            ),
          ],
          updateResultBuilder:
              ({required String id, required bool isFinancialTransaction}) =>
                  _buildUpdateResult(
                    id: id,
                    isFinancialTransaction: isFinancialTransaction,
                    responseStatusCode: 200,
                    responseBody: '{"ok":true}',
                  ),
          deleteResultBuilder: ({required String id}) =>
              _buildDeleteResult(id: id),
        );

        await _pumpPage(tester, facade);
        await _scrollUntilVisible(
          tester,
          find.widgetWithText(FilledButton, 'Confirmar transação financeira'),
        );

        expect(facade.loadCalls, 1);
        expect(find.text('Classificar'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Confirmar transação financeira'),
        );
        await tester.pumpAndSettle();

        expect(facade.loadCalls, 1);
        expect(facade.updateCalls, hasLength(1));
        expect(
          facade.updateCalls.single,
          const _UpdateCall(id: 'notification-1', isFinancialTransaction: true),
        );
        expect(find.text('Classificar'), findsNothing);
        expect(find.text('Transação financeira'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'ao marcar como nao financeira atualiza o chip, envia update e nao reabre get_all_notifications',
      (tester) async {
        final facade = _FakeAllNotificationsFacade(
          initialNotifications: const <AllNotification>[
            AllNotification(
              id: 'notification-2',
              app: 'Banco XPTO',
              text: 'Compra no cartao',
              isFinancialTransaction: null,
            ),
          ],
          updateResultBuilder:
              ({required String id, required bool isFinancialTransaction}) =>
                  _buildUpdateResult(
                    id: id,
                    isFinancialTransaction: isFinancialTransaction,
                    responseStatusCode: 200,
                    responseBody: '{"ok":true}',
                  ),
          deleteResultBuilder: ({required String id}) =>
              _buildDeleteResult(id: id),
        );

        await _pumpPage(tester, facade);
        await _scrollUntilVisible(
          tester,
          find.widgetWithText(OutlinedButton, 'Não é transação financeira'),
        );

        expect(facade.loadCalls, 1);
        expect(find.text('Classificar'), findsOneWidget);
        expect(find.text('Não é transação financeira'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Não é transação financeira'),
        );
        await tester.pumpAndSettle();

        expect(facade.loadCalls, 1);
        expect(facade.updateCalls, hasLength(1));
        expect(
          facade.updateCalls.single,
          const _UpdateCall(
            id: 'notification-2',
            isFinancialTransaction: false,
          ),
        );
        expect(find.text('Classificar'), findsNothing);
        expect(find.text('Não é transação financeira'), findsNWidgets(2));
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'ao falhar update como nao financeira exibe o popup sem recarregar get_all_notifications',
      (tester) async {
        final facade = _FakeAllNotificationsFacade(
          initialNotifications: const <AllNotification>[
            AllNotification(
              id: 'notification-3',
              app: 'Banco XPTO',
              text: 'Mensagem pendente',
              isFinancialTransaction: null,
            ),
          ],
          updateResultBuilder:
              ({required String id, required bool isFinancialTransaction}) =>
                  _buildUpdateResult(
                    id: id,
                    isFinancialTransaction: isFinancialTransaction,
                    responseStatusCode: 500,
                    responseBody: '{"detail":"failed"}',
                    responseErrorMessage: 'update_notification returned 500',
                  ),
          deleteResultBuilder: ({required String id}) =>
              _buildDeleteResult(id: id),
        );

        await _pumpPage(tester, facade);
        await _scrollUntilVisible(
          tester,
          find.widgetWithText(OutlinedButton, 'Não é transação financeira'),
        );

        expect(facade.loadCalls, 1);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Não é transação financeira'),
        );
        await tester.pumpAndSettle();

        expect(facade.loadCalls, 1);
        expect(facade.updateCalls, hasLength(1));
        expect(
          facade.updateCalls.single,
          const _UpdateCall(
            id: 'notification-3',
            isFinancialTransaction: false,
          ),
        );
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Falha ao atualizar notificação'), findsOneWidget);
        expect(
          find.text('A requisição para `update_notification` falhou.'),
          findsOneWidget,
        );
        expect(find.text('Classificar'), findsOneWidget);
      },
    );

    testWidgets(
      'ao deletar remove o card, envia delete e nao reabre get_all_notifications',
      (tester) async {
        final facade = _FakeAllNotificationsFacade(
          initialNotifications: const <AllNotification>[
            AllNotification(
              id: 'notification-4',
              app: 'Banco XPTO',
              text: 'Mensagem para deletar',
              isFinancialTransaction: true,
            ),
          ],
          updateResultBuilder:
              ({required String id, required bool isFinancialTransaction}) =>
                  _buildUpdateResult(
                    id: id,
                    isFinancialTransaction: isFinancialTransaction,
                    responseStatusCode: 200,
                    responseBody: '{"ok":true}',
                  ),
          deleteResultBuilder: ({required String id}) =>
              _buildDeleteResult(id: id, responseStatusCode: 204),
        );

        await _pumpPage(tester, facade);
        await _scrollUntilVisible(
          tester,
          find.widgetWithText(OutlinedButton, 'Deletar notificação'),
        );

        expect(facade.loadCalls, 1);
        expect(find.text('Mensagem para deletar'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Deletar notificação'),
        );
        await tester.pumpAndSettle();

        expect(facade.loadCalls, 1);
        expect(facade.deleteCalls, <String>['notification-4']);
        expect(find.text('Mensagem para deletar'), findsNothing);
        expect(find.text('Nenhum dado retornado'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('ao falhar delete exibe o popup e mantem o card na lista', (
      tester,
    ) async {
      final facade = _FakeAllNotificationsFacade(
        initialNotifications: const <AllNotification>[
          AllNotification(
            id: 'notification-5',
            app: 'Banco XPTO',
            text: 'Mensagem que falha ao deletar',
            isFinancialTransaction: true,
          ),
        ],
        updateResultBuilder:
            ({required String id, required bool isFinancialTransaction}) =>
                _buildUpdateResult(
                  id: id,
                  isFinancialTransaction: isFinancialTransaction,
                  responseStatusCode: 200,
                  responseBody: '{"ok":true}',
                ),
        deleteResultBuilder: ({required String id}) => _buildDeleteResult(
          id: id,
          responseStatusCode: 500,
          responseBody: '{"detail":"failed"}',
          responseErrorMessage: 'delete_notification returned 500',
        ),
      );

      await _pumpPage(tester, facade);
      await _scrollUntilVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Deletar notificação'),
      );

      expect(facade.loadCalls, 1);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Deletar notificação'),
      );
      await tester.pumpAndSettle();

      expect(facade.loadCalls, 1);
      expect(facade.deleteCalls, <String>['notification-5']);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Falha ao deletar notificação'), findsOneWidget);
      expect(
        find.text('A requisição para `delete_notification` falhou.'),
        findsOneWidget,
      );
      expect(find.text('Mensagem que falha ao deletar'), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeAllNotificationsFacade facade,
) async {
  final controller = AllNotificationsController(facade);

  await tester.pumpWidget(
    MaterialApp(home: AllNotificationsPage(controller: controller)),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _FakeAllNotificationsFacade implements AllNotificationsFacade {
  _FakeAllNotificationsFacade({
    required this.initialNotifications,
    required this.updateResultBuilder,
    required this.deleteResultBuilder,
  });

  final List<AllNotification> initialNotifications;
  final UpdateNotificationResult Function({
    required String id,
    required bool isFinancialTransaction,
  })
  updateResultBuilder;
  final DeleteNotificationResult Function({required String id})
  deleteResultBuilder;

  int loadCalls = 0;
  final List<_UpdateCall> updateCalls = <_UpdateCall>[];
  final List<String> deleteCalls = <String>[];

  @override
  Future<PaginatedAllNotifications> load(AllNotificationsQuery query) async {
    loadCalls += 1;

    return PaginatedAllNotifications(query: query, items: initialNotifications);
  }

  @override
  Future<UpdateNotificationResult> updateNotification({
    required String id,
    required bool isFinancialTransaction,
  }) async {
    updateCalls.add(
      _UpdateCall(id: id, isFinancialTransaction: isFinancialTransaction),
    );

    return updateResultBuilder(
      id: id,
      isFinancialTransaction: isFinancialTransaction,
    );
  }

  @override
  Future<DeleteNotificationResult> deleteNotification({
    required String id,
  }) async {
    deleteCalls.add(id);
    return deleteResultBuilder(id: id);
  }
}

class _UpdateCall {
  const _UpdateCall({required this.id, required this.isFinancialTransaction});

  final String id;
  final bool isFinancialTransaction;

  @override
  bool operator ==(Object other) {
    return other is _UpdateCall &&
        other.id == id &&
        other.isFinancialTransaction == isFinancialTransaction;
  }

  @override
  int get hashCode => Object.hash(id, isFinancialTransaction);
}

UpdateNotificationResult _buildUpdateResult({
  required String id,
  required bool isFinancialTransaction,
  required int responseStatusCode,
  String? responseBody,
  String? responseErrorMessage,
}) {
  return UpdateNotificationResult(
    notificationId: id,
    isFinancialTransaction: isFinancialTransaction,
    requestMethod: 'PUT',
    requestUrl: 'https://example.com/update_notification',
    requestBody:
        '{"id":"$id","is_financial_transaction":$isFinancialTransaction}',
    responseStatusCode: responseStatusCode,
    responseBody: responseBody,
    responseErrorMessage: responseErrorMessage,
  );
}

DeleteNotificationResult _buildDeleteResult({
  required String id,
  int responseStatusCode = 200,
  String? responseBody,
  String? responseErrorMessage,
}) {
  return DeleteNotificationResult(
    notificationId: id,
    requestMethod: 'DELETE',
    requestUrl: 'https://example.com/delete_notification?id=$id',
    requestQuery: 'id=$id',
    responseStatusCode: responseStatusCode,
    responseBody: responseBody,
    responseErrorMessage: responseErrorMessage,
  );
}

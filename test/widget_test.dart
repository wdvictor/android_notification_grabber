import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notification_grabber/app.dart';
import 'package:notification_grabber/src/features/notifications/application/notifications_presentation_facade.dart';
import 'package:notification_grabber/src/features/notifications/domain/entities/app_state_snapshot.dart';
import 'package:notification_grabber/src/features/notifications/domain/entities/installed_app.dart';
import 'package:notification_grabber/src/features/notifications/domain/entities/offline_notification.dart';
import 'package:notification_grabber/src/features/notifications/domain/entities/retry_results.dart';
import 'package:notification_grabber/src/features/notifications/presentation/controllers/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renderiza estado vazio da fila offline', (tester) async {
    final controller = AppController(_FakeNotificationsPresentationFacade());

    await tester.pumpWidget(NotificationGrabberApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Notification Grabber'), findsOneWidget);
    expect(find.text('Fila offline'), findsOneWidget);
    expect(find.text('Nenhuma falha pendente'), findsOneWidget);
  });

  testWidgets('exibe acoes de apagar com notificacao offline', (tester) async {
    final controller = AppController(
      _FakeNotificationsPresentationFacade(
        AppStateSnapshot(
          notificationAccessGranted: true,
          notificationPermissionGranted: true,
          offlineNotifications: [
            OfflineNotification(
              id: '1',
              app: 'Banco XPTO',
              text: 'Compra aprovada no cartao final 1234',
              isFinancialNotification: true,
              request: RequestDetails(
                method: 'PUT',
                url: 'https://example.com/notifications',
                body: '{"app":"Banco XPTO"}',
                attemptedAt: DateTime(2026, 3, 18, 10, 30),
              ),
              response: ResponseDetails(
                statusCode: 500,
                body: '{"error":"failed"}',
                errorMessage: 'Falha no backend',
                receivedAt: DateTime(2026, 3, 18, 10, 31),
              ),
              createdAt: DateTime(2026, 3, 18, 10, 30),
              updatedAt: DateTime(2026, 3, 18, 10, 31),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(NotificationGrabberApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Apagar tudo'), findsOneWidget);
    expect(find.text('Apagar'), findsOneWidget);
  });
}

class _FakeNotificationsPresentationFacade
    implements NotificationsPresentationFacade {
  _FakeNotificationsPresentationFacade([AppStateSnapshot? snapshot])
    : _snapshot =
          snapshot ??
          const AppStateSnapshot(
            notificationAccessGranted: true,
            notificationPermissionGranted: true,
            offlineNotifications: [],
          );

  final AppStateSnapshot _snapshot;

  @override
  Stream<String> get selectedNotificationIds => const Stream<String>.empty();

  @override
  void setOnOfflineNotificationsChanged(Future<void> Function()? onChanged) {}

  @override
  Future<String?> initializeForegroundNotifications() async {
    return null;
  }

  @override
  Future<AppStateSnapshot> loadState() async {
    return _snapshot;
  }

  @override
  Future<void> openNotificationAccessSettings() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<RetryAllResult> retryAllOfflineNotifications() async {
    return const RetryAllResult(successCount: 0, failureCount: 0);
  }

  @override
  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    return const RetryNotificationResult(success: true, record: null);
  }

  @override
  Future<bool> deleteOfflineNotification(String id) async => true;

  @override
  Future<int> deleteAllOfflineNotifications() async => 0;

  @override
  Future<List<InstalledApp>> loadInstalledApps() async => const [];

  @override
  Future<void> addIgnoredApp(String packageName) async {}

  @override
  Future<void> removeIgnoredApp(String packageName) async {}

  @override
  Future<void> dispose() async {}
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notification_grabber/app.dart';
import 'package:notification_grabber/src/features/notifications/application/notifications_presentation_facade.dart';
import 'package:notification_grabber/src/features/notifications/domain/entities/app_state_snapshot.dart';
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
}

class _FakeNotificationsPresentationFacade implements NotificationsPresentationFacade {
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
    return const AppStateSnapshot(
      notificationAccessGranted: true,
      notificationPermissionGranted: true,
      offlineNotifications: [],
    );
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
  Future<void> dispose() async {}
}

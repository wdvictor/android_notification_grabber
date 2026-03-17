import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notification_graber/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('notification_graber/platform');

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getAppBootstrap':
              return <String, Object?>{
                'notificationAccessGranted': true,
                'notificationPermissionGranted': true,
                'offlineNotifications': <Object?>[],
                'pendingFailedNotificationId': null,
              };
            case 'retryAllOfflineNotifications':
              return <String, Object?>{'successCount': 0, 'failureCount': 0};
            case 'requestNotificationPermission':
              return true;
            case 'openNotificationAccessSettings':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('renderiza estado vazio da fila offline', (tester) async {
    await tester.pumpWidget(const NotificationGrabberApp());
    await tester.pumpAndSettle();

    expect(find.text('Notification Grabber'), findsOneWidget);
    expect(find.text('Fila offline'), findsOneWidget);
    expect(find.text('Nenhuma falha pendente'), findsOneWidget);
  });
}

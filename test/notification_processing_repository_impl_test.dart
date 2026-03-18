import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/ignored_app_store_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/local_failure_notification_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/notification_delivery_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/offline_notification_store_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/platform_bridge_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/models/delivery_response_model.dart';
import 'package:notification_grabber/src/features/notifications/data/models/offline_notification_model.dart';
import 'package:notification_grabber/src/features/notifications/data/repositories/ignored_app_repository_impl.dart';
import 'package:notification_grabber/src/features/notifications/data/repositories/notification_processing_repository_impl.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_shared_preferences_async_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        FakeSharedPreferencesAsyncPlatform();
  });

  group('NotificationProcessingRepositoryImpl delete', () {
    test('deleta uma unica notificacao offline', () async {
      final store = OfflineNotificationStoreDataSource();
      await store.upsert(_record('1'));
      await store.upsert(_record('2'));
      var notificationsChangedCount = 0;
      final repository = NotificationProcessingRepositoryImpl(
        platformBridgeDataSource: _FakePlatformBridgeDataSource(),
        offlineNotificationStoreDataSource: store,
        notificationDeliveryDataSource: _FakeNotificationDeliveryDataSource(),
        ignoredAppRepository: _createIgnoredAppRepository(),
        localFailureNotificationDataSource:
            _FakeLocalFailureNotificationDataSource(),
        notifyOfflineNotificationsChanged: () async {
          notificationsChangedCount += 1;
        },
      );

      final deleted = await repository.deleteOfflineNotification('1');
      final remainingRecords = await store.getAll();

      expect(deleted, isTrue);
      expect(remainingRecords.map((record) => record.id), ['2']);
      expect(notificationsChangedCount, 1);
    });

    test('deleta todas as notificacoes offline', () async {
      final store = OfflineNotificationStoreDataSource();
      await store.upsert(_record('1'));
      await store.upsert(_record('2'));
      await store.upsert(_record('3'));
      var notificationsChangedCount = 0;
      final repository = NotificationProcessingRepositoryImpl(
        platformBridgeDataSource: _FakePlatformBridgeDataSource(),
        offlineNotificationStoreDataSource: store,
        notificationDeliveryDataSource: _FakeNotificationDeliveryDataSource(),
        ignoredAppRepository: _createIgnoredAppRepository(),
        localFailureNotificationDataSource:
            _FakeLocalFailureNotificationDataSource(),
        notifyOfflineNotificationsChanged: () async {
          notificationsChangedCount += 1;
        },
      );

      final deletedCount = await repository.deleteAllOfflineNotifications();
      final remainingRecords = await store.getAll();

      expect(deletedCount, 3);
      expect(remainingRecords, isEmpty);
      expect(notificationsChangedCount, 1);
    });
  });

  group('NotificationProcessingRepositoryImpl process', () {
    test(
      'nao envia notificacao recebida por app ignorado para a API',
      () async {
        final ignoredAppRepository = _createIgnoredAppRepository();
        await ignoredAppRepository.addIgnoredApp('com.alpha.bank');
        final deliveryDataSource = _CountingNotificationDeliveryDataSource();
        final repository = NotificationProcessingRepositoryImpl(
          platformBridgeDataSource: _FakePlatformBridgeDataSource(),
          offlineNotificationStoreDataSource:
              OfflineNotificationStoreDataSource(),
          notificationDeliveryDataSource: deliveryDataSource,
          ignoredAppRepository: ignoredAppRepository,
          localFailureNotificationDataSource:
              _FakeLocalFailureNotificationDataSource(),
        );

        final result = await repository.processCapturedNotification(
          app: 'com.alpha.bank',
          text: 'Compra aprovada no cartao final 1234',
        );

        expect(result.success, isTrue);
        expect(result.record, isNull);
        expect(deliveryDataSource.sendCount, 0);
        expect(await repository.getOfflineNotifications(), isEmpty);
      },
    );
  });
}

IgnoredAppRepositoryImpl _createIgnoredAppRepository() {
  return IgnoredAppRepositoryImpl(
    platformBridgeDataSource: _FakePlatformBridgeDataSource(),
    ignoredAppStoreDataSource: IgnoredAppStoreDataSource(),
  );
}

OfflineNotificationModel _record(String id) {
  final timestamp = DateTime(2026, 3, 18, 10, id.length);
  return OfflineNotificationModel(
    id: id,
    app: 'Banco XPTO $id',
    text: 'Notificacao offline $id',
    isFinancialNotification: true,
    request: RequestDetailsModel(
      method: 'PUT',
      url: 'https://example.com/notifications',
      body: '{"id":"$id"}',
      attemptedAt: timestamp,
    ),
    response: ResponseDetailsModel(
      statusCode: 500,
      body: '{"error":"failed"}',
      errorMessage: 'Falha no backend',
      receivedAt: timestamp,
    ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

class _FakePlatformBridgeDataSource extends PlatformBridgeDataSource {
  @override
  Future<String> getApiKey() async => 'test-api-key';

  @override
  Future<String> getBackendBaseUrl() async => 'https://example.com';

  @override
  Future<void> broadcastOfflineNotificationsChanged() async {}
}

class _FakeNotificationDeliveryDataSource
    extends NotificationDeliveryDataSource {
  @override
  Future<DeliveryResponseModel> send({
    required String endpoint,
    required String app,
    required String text,
    required String apiKey,
  }) {
    throw UnimplementedError('Nao deve enviar notificacoes neste teste.');
  }
}

class _CountingNotificationDeliveryDataSource
    extends NotificationDeliveryDataSource {
  int sendCount = 0;

  @override
  Future<DeliveryResponseModel> send({
    required String endpoint,
    required String app,
    required String text,
    required String apiKey,
  }) async {
    sendCount += 1;
    return DeliveryResponseModel(
      requestUrl: endpoint,
      requestBody: '{"app":"$app","text":"$text"}',
      statusCode: 201,
      body: '{"ok":true}',
      errorMessage: null,
    );
  }
}

class _FakeLocalFailureNotificationDataSource
    extends LocalFailureNotificationDataSource {
  @override
  Future<void> showFailureNotification({
    required String id,
    required String app,
  }) async {}
}

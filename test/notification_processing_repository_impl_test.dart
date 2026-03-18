import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/local_failure_notification_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/notification_delivery_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/offline_notification_store_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/platform_bridge_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/models/delivery_response_model.dart';
import 'package:notification_grabber/src/features/notifications/data/models/offline_notification_model.dart';
import 'package:notification_grabber/src/features/notifications/data/repositories/notification_processing_repository_impl.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _FakeSharedPreferencesAsyncPlatform();
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

class _FakeLocalFailureNotificationDataSource
    extends LocalFailureNotificationDataSource {
  @override
  Future<void> showFailureNotification({
    required String id,
    required String app,
  }) async {}
}

final class _FakeSharedPreferencesAsyncPlatform
    extends SharedPreferencesAsyncPlatform {
  final Map<String, Object> _storage = <String, Object>{};

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      _storage.clear();
      return;
    }

    _storage.removeWhere((key, _) => allowList.contains(key));
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    return _storage[key] as bool?;
  }

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _storage[key] as double?;
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async {
    return _storage[key] as int?;
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      return Map<String, Object>.from(_storage);
    }

    return Map<String, Object>.fromEntries(
      _storage.entries.where((entry) => allowList.contains(entry.key)),
    );
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      return _storage.keys.toSet();
    }

    return _storage.keys.where(allowList.contains).toSet();
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _storage[key] as String?;
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return (_storage[key] as List<Object?>?)?.cast<String>();
  }

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    _storage[key] = value;
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) async {
    _storage[key] = value;
  }

  @override
  Future<void> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    _storage[key] = value;
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    _storage[key] = value;
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    _storage[key] = List<String>.from(value);
  }
}

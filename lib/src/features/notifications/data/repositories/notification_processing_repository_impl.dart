import 'package:uuid/uuid.dart';

import '../../../../core/config/backend_endpoints.dart';
import '../../domain/entities/offline_notification.dart';
import '../../domain/entities/retry_results.dart';
import '../../domain/repositories/notification_processing_repository.dart';
import '../datasources/local_failure_notification_data_source.dart';
import '../datasources/notification_delivery_data_source.dart';
import '../datasources/offline_notification_store_data_source.dart';
import '../datasources/platform_bridge_data_source.dart';
import '../models/offline_notification_model.dart';

class NotificationProcessingRepositoryImpl
    implements NotificationProcessingRepository {
  NotificationProcessingRepositoryImpl({
    required PlatformBridgeDataSource platformBridgeDataSource,
    required OfflineNotificationStoreDataSource
    offlineNotificationStoreDataSource,
    required NotificationDeliveryDataSource notificationDeliveryDataSource,
    required LocalFailureNotificationDataSource
    localFailureNotificationDataSource,
    Uuid? uuid,
  }) : _platformBridgeDataSource = platformBridgeDataSource,
       _offlineNotificationStoreDataSource = offlineNotificationStoreDataSource,
       _notificationDeliveryDataSource = notificationDeliveryDataSource,
       _localFailureNotificationDataSource = localFailureNotificationDataSource,
       _uuid = uuid ?? const Uuid();

  final PlatformBridgeDataSource _platformBridgeDataSource;
  final OfflineNotificationStoreDataSource _offlineNotificationStoreDataSource;
  final NotificationDeliveryDataSource _notificationDeliveryDataSource;
  final LocalFailureNotificationDataSource _localFailureNotificationDataSource;
  final Uuid _uuid;

  String? _cachedApiKey;
  String? _cachedBackendBaseUrl;

  @override
  Future<List<OfflineNotification>> getOfflineNotifications() async {
    final records = await _offlineNotificationStoreDataSource.getAll();
    return records.map((record) => record.toEntity()).toList();
  }

  @override
  Future<RetryAllResult> retryAllOfflineNotifications() async {
    final snapshot = await _offlineNotificationStoreDataSource.getAll();
    var successCount = 0;
    var failureCount = 0;

    for (final record in snapshot) {
      final result = await _dispatch(
        app: record.app,
        text: record.text,
        existingId: record.id,
        notifyOnFailure: true,
      );

      if (result.success) {
        successCount += 1;
      } else {
        failureCount += 1;
      }
    }

    return RetryAllResult(
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  @override
  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    final record = await _offlineNotificationStoreDataSource.getById(id);
    if (record == null) {
      return const RetryNotificationResult(success: true, record: null);
    }

    return _dispatch(
      app: record.app,
      text: record.text,
      existingId: record.id,
      notifyOnFailure: true,
    );
  }

  @override
  Future<RetryNotificationResult> processCapturedNotification({
    required String app,
    required String text,
  }) {
    return _dispatch(app: app, text: text, notifyOnFailure: true);
  }

  Future<RetryNotificationResult> _dispatch({
    required String app,
    required String text,
    String? existingId,
    required bool notifyOnFailure,
  }) async {
    final previousRecord = existingId == null
        ? null
        : await _offlineNotificationStoreDataSource.getById(existingId);
    final attemptedAt = DateTime.now();
    final endpoints = BackendEndpoints(await _getBackendBaseUrl());
    final delivery = await _notificationDeliveryDataSource.send(
      endpoint: endpoints.addNotification,
      app: app,
      text: text,
      apiKey: await _getApiKey(),
    );

    if (delivery.statusCode == 201) {
      if (existingId != null) {
        await _offlineNotificationStoreDataSource.delete(existingId);
        await _platformBridgeDataSource.broadcastOfflineNotificationsChanged();
      }

      return const RetryNotificationResult(success: true, record: null);
    }

    final updatedAt = DateTime.now();
    final record = OfflineNotificationModel(
      id: existingId ?? _uuid.v4(),
      app: app,
      text: text,
      isFinancialNotification: null,
      request: RequestDetailsModel(
        method: 'PUT',
        url: delivery.requestUrl,
        body: delivery.requestBody,
        attemptedAt: attemptedAt,
      ),
      response: ResponseDetailsModel(
        statusCode: delivery.statusCode,
        body: delivery.body,
        errorMessage: delivery.errorMessage,
        receivedAt: updatedAt,
      ),
      createdAt: previousRecord?.createdAt ?? updatedAt,
      updatedAt: updatedAt,
    );

    await _offlineNotificationStoreDataSource.upsert(record);
    await _platformBridgeDataSource.broadcastOfflineNotificationsChanged();

    if (notifyOnFailure) {
      await _localFailureNotificationDataSource.showFailureNotification(
        id: record.id,
        app: record.app,
      );
    }

    return RetryNotificationResult(success: false, record: record.toEntity());
  }

  Future<String> _getApiKey() async {
    final cachedApiKey = _cachedApiKey;
    if (cachedApiKey != null) {
      return cachedApiKey;
    }

    final apiKey = await _platformBridgeDataSource.getApiKey();
    _cachedApiKey = apiKey;
    return apiKey;
  }

  Future<String> _getBackendBaseUrl() async {
    final cachedBackendBaseUrl = _cachedBackendBaseUrl;
    if (cachedBackendBaseUrl != null) {
      return cachedBackendBaseUrl;
    }

    final backendBaseUrl = await _platformBridgeDataSource.getBackendBaseUrl();
    _cachedBackendBaseUrl = backendBaseUrl;
    return backendBaseUrl;
  }
}

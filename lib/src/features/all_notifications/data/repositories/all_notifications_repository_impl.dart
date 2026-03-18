import '../../../../core/config/backend_endpoints.dart';
import '../../../notifications/data/datasources/platform_bridge_data_source.dart';
import '../../domain/entities/all_notification.dart';
import '../../domain/entities/all_notifications_query.dart';
import '../../domain/repositories/all_notifications_repository.dart';
import '../datasources/all_notifications_remote_data_source.dart';

class AllNotificationsRepositoryImpl implements AllNotificationsRepository {
  AllNotificationsRepositoryImpl({
    required PlatformBridgeDataSource platformBridgeDataSource,
    required AllNotificationsRemoteDataSource remoteDataSource,
  }) : _platformBridgeDataSource = platformBridgeDataSource,
       _remoteDataSource = remoteDataSource;

  final PlatformBridgeDataSource _platformBridgeDataSource;
  final AllNotificationsRemoteDataSource _remoteDataSource;

  String? _cachedApiKey;
  String? _cachedBackendBaseUrl;

  @override
  Future<List<AllNotification>> getAllNotifications(
    AllNotificationsQuery query,
  ) async {
    final endpoints = BackendEndpoints(await _getBackendBaseUrl());
    final models = await _remoteDataSource.fetch(
      endpoint: endpoints.getAllNotifications,
      apiKey: await _getApiKey(),
      query: query,
    );

    return models.map((model) => model.toEntity()).toList(growable: false);
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

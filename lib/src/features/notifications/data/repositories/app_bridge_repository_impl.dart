import '../../domain/entities/bridge_snapshot.dart';
import '../../domain/entities/retry_results.dart';
import '../../domain/repositories/app_bridge_repository.dart';
import '../datasources/platform_bridge_data_source.dart';
import '../models/bridge_snapshot_model.dart';
import '../models/retry_results_model.dart';

class AppBridgeRepositoryImpl implements AppBridgeRepository {
  AppBridgeRepositoryImpl(this._platformBridgeDataSource);

  final PlatformBridgeDataSource _platformBridgeDataSource;

  @override
  Future<BridgeSnapshot> getBridgeSnapshot() async {
    final raw = await _platformBridgeDataSource.getAppBootstrap();
    return BridgeSnapshotModel.fromMap(raw).toEntity();
  }

  @override
  Future<void> openNotificationAccessSettings() {
    return _platformBridgeDataSource.openNotificationAccessSettings();
  }

  @override
  Future<RetryAllResult> retryAllOfflineNotifications() async {
    final raw = await _platformBridgeDataSource.retryAllOfflineNotifications();
    return RetryAllResultModel.fromMap(raw).toEntity();
  }

  @override
  Future<RetryNotificationResult> retryOfflineNotification(String id) async {
    final raw = await _platformBridgeDataSource.retryOfflineNotification(id);
    return RetryNotificationResultModel.fromMap(raw).toEntity();
  }
}

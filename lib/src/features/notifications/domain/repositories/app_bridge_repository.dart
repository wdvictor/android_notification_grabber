import '../entities/bridge_snapshot.dart';
import '../entities/retry_results.dart';

abstract interface class AppBridgeRepository {
  Future<BridgeSnapshot> getBridgeSnapshot();
  Future<void> openNotificationAccessSettings();
  Future<RetryAllResult> retryAllOfflineNotifications();
  Future<RetryNotificationResult> retryOfflineNotification(String id);
}

import 'offline_notification.dart';

class RetryNotificationResult {
  const RetryNotificationResult({required this.success, required this.record});

  final bool success;
  final OfflineNotification? record;
}

class RetryAllResult {
  const RetryAllResult({
    required this.successCount,
    required this.failureCount,
  });

  final int successCount;
  final int failureCount;
}

import 'offline_notification.dart';

class BridgeSnapshot {
  const BridgeSnapshot({
    required this.notificationAccessGranted,
    required this.offlineNotifications,
  });

  final bool notificationAccessGranted;
  final List<OfflineNotification> offlineNotifications;
}

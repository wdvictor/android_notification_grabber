import 'offline_notification.dart';

class AppStateSnapshot {
  const AppStateSnapshot({
    required this.notificationAccessGranted,
    required this.notificationPermissionGranted,
    required this.offlineNotifications,
  });

  final bool notificationAccessGranted;
  final bool notificationPermissionGranted;
  final List<OfflineNotification> offlineNotifications;
}

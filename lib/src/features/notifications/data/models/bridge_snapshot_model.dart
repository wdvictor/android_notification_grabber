import '../../domain/entities/bridge_snapshot.dart';
import 'offline_notification_model.dart';

class BridgeSnapshotModel {
  const BridgeSnapshotModel({
    required this.notificationAccessGranted,
    required this.offlineNotifications,
  });

  factory BridgeSnapshotModel.fromMap(Map<Object?, Object?> map) {
    final rawNotifications =
        (map['offlineNotifications'] as List<Object?>?) ?? const [];

    return BridgeSnapshotModel(
      notificationAccessGranted:
          map['notificationAccessGranted'] as bool? ?? false,
      offlineNotifications: rawNotifications
          .map(
            (value) => value is Map ? Map<Object?, Object?>.from(value) : null,
          )
          .whereType<Map<Object?, Object?>>()
          .map(OfflineNotificationModel.fromMap)
          .toList(),
    );
  }

  final bool notificationAccessGranted;
  final List<OfflineNotificationModel> offlineNotifications;

  BridgeSnapshot toEntity() {
    return BridgeSnapshot(
      notificationAccessGranted: notificationAccessGranted,
      offlineNotifications: offlineNotifications
          .map((notification) => notification.toEntity())
          .toList(),
    );
  }
}

import '../../domain/entities/retry_results.dart';
import 'offline_notification_model.dart';

class RetryNotificationResultModel {
  const RetryNotificationResultModel({
    required this.success,
    required this.record,
  });

  factory RetryNotificationResultModel.fromMap(Map<Object?, Object?> map) {
    final rawRecord = map['record'];

    return RetryNotificationResultModel(
      success: map['success'] as bool? ?? false,
      record: rawRecord is Map
          ? OfflineNotificationModel.fromMap(
              Map<Object?, Object?>.from(rawRecord),
            )
          : null,
    );
  }

  final bool success;
  final OfflineNotificationModel? record;

  RetryNotificationResult toEntity() {
    return RetryNotificationResult(
      success: success,
      record: record?.toEntity(),
    );
  }
}

class RetryAllResultModel {
  const RetryAllResultModel({
    required this.successCount,
    required this.failureCount,
  });

  factory RetryAllResultModel.fromMap(Map<Object?, Object?> map) {
    return RetryAllResultModel(
      successCount: (map['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (map['failureCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int successCount;
  final int failureCount;

  RetryAllResult toEntity() {
    return RetryAllResult(
      successCount: successCount,
      failureCount: failureCount,
    );
  }
}

import '../../domain/entities/all_notification.dart';

class AllNotificationModel {
  const AllNotificationModel({
    required this.app,
    required this.text,
    required this.isFinancialTransaction,
  });

  factory AllNotificationModel.fromJson(Map<String, Object?> json) {
    return AllNotificationModel(
      app: json['app'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isFinancialTransaction: _readBool(json['is_financial_transaction']),
    );
  }

  final String app;
  final String text;
  final bool? isFinancialTransaction;

  AllNotification toEntity() {
    return AllNotification(
      app: app,
      text: text,
      isFinancialTransaction: isFinancialTransaction,
    );
  }

  static bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }

      if (normalized == 'false') {
        return false;
      }
    }

    return null;
  }
}

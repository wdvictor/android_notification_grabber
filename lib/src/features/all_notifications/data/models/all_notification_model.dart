import '../../domain/entities/all_notification.dart';

class AllNotificationModel {
  const AllNotificationModel({
    required this.id,
    required this.app,
    required this.text,
    required this.isFinancialTransaction,
  });

  factory AllNotificationModel.fromJson(Map<String, Object?> json) {
    return AllNotificationModel(
      id: json['id']?.toString() ?? '',
      app: json['app'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isFinancialTransaction: _readBool(json['is_financial_transaction']),
    );
  }

  final String id;
  final String app;
  final String text;
  final bool? isFinancialTransaction;

  AllNotification toEntity() {
    return AllNotification(
      id: id,
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

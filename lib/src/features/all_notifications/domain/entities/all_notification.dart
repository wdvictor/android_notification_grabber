class AllNotification {
  const AllNotification({
    required this.id,
    required this.app,
    required this.text,
    required this.isFinancialTransaction,
  });

  final String id;
  final String app;
  final String text;
  final bool? isFinancialTransaction;

  String get preview {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= 140) {
      return normalized;
    }

    return '${normalized.substring(0, 137)}...';
  }
}

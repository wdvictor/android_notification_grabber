import 'dart:convert';

String formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute:$second';
}

String prettyJsonIfPossible(String raw) {
  try {
    final decoded = jsonDecode(raw);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(decoded);
  } catch (_) {
    return raw;
  }
}

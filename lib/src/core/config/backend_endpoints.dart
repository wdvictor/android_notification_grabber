class BackendEndpoints {
  BackendEndpoints(String baseUrl) : _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String addNotificationPath = 'add_notification';

  final String _baseUrl;

  String get addNotification => _build(addNotificationPath);

  String _build(String path) {
    final normalizedPath = path.trim().replaceFirst(RegExp(r'^/+'), '');
    if (_baseUrl.isEmpty || normalizedPath.isEmpty) {
      return '';
    }

    return '$_baseUrl/$normalizedPath';
  }

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }

    return normalized.replaceFirst(RegExp(r'/+$'), '');
  }
}

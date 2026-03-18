class BackendEndpoints {
  BackendEndpoints(String baseUrl) : _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String addNotificationPath = 'add_notification';
  static const String getAllNotificationsPath = 'get_all_notifications';
  static const String updateNotificationPath = 'update_notification';

  final String _baseUrl;

  String get addNotification => _build(addNotificationPath);
  String get getAllNotifications => _build(getAllNotificationsPath);
  String get updateNotification => _build(updateNotificationPath);

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

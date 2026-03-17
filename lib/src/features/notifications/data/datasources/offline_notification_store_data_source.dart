import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import '../models/offline_notification_model.dart';

class OfflineNotificationStoreDataSource {
  OfflineNotificationStoreDataSource({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync(options: _androidOptions);

  static const String keyOfflineNotifications = 'offline_notifications';
  static const SharedPreferencesAsyncAndroidOptions _androidOptions =
      SharedPreferencesAsyncAndroidOptions(
        backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
          fileName: 'notification_grabber_store',
        ),
      );

  final SharedPreferencesAsync _preferences;

  Future<List<OfflineNotificationModel>> getAll() async {
    final raw = await _preferences.getString(keyOfflineNotifications);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final records = decoded
          .map((value) => value is Map ? Map<Object?, Object?>.from(value) : null)
          .whereType<Map<Object?, Object?>>()
          .map(OfflineNotificationModel.fromMap)
          .toList();

      records.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  Future<OfflineNotificationModel?> getById(String id) async {
    final records = await getAll();
    for (final record in records) {
      if (record.id == id) {
        return record;
      }
    }

    return null;
  }

  Future<void> upsert(OfflineNotificationModel record) async {
    final records = (await getAll()).toList();
    final index = records.indexWhere((current) => current.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }

    await _save(records);
  }

  Future<void> delete(String id) async {
    final updated = (await getAll()).where((record) => record.id != id).toList();
    await _save(updated);
  }

  Future<void> _save(List<OfflineNotificationModel> records) async {
    records.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    final payload = jsonEncode(records.map((record) => record.toMap()).toList());
    await _preferences.setString(keyOfflineNotifications, payload);
  }
}

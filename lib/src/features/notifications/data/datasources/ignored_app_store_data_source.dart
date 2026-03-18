import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

class IgnoredAppStoreDataSource {
  IgnoredAppStoreDataSource({SharedPreferencesAsync? preferences})
    : _preferences =
          preferences ?? SharedPreferencesAsync(options: _androidOptions);

  static const String keyIgnoredApps = 'ignored_app_packages';
  static const SharedPreferencesAsyncAndroidOptions _androidOptions =
      SharedPreferencesAsyncAndroidOptions(
        backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
          fileName: 'notification_grabber_store',
        ),
      );

  final SharedPreferencesAsync _preferences;

  Future<Set<String>> getIgnoredPackages() async {
    final packages = await _preferences.getStringList(keyIgnoredApps);
    if (packages == null || packages.isEmpty) {
      return const <String>{};
    }

    return {
      for (final packageName in packages)
        if (_normalize(packageName).isNotEmpty) _normalize(packageName),
    };
  }

  Future<void> add(String packageName) async {
    final normalizedPackageName = _normalize(packageName);
    if (normalizedPackageName.isEmpty) {
      return;
    }

    final packages = {...await getIgnoredPackages(), normalizedPackageName};
    await _save(packages);
  }

  Future<void> remove(String packageName) async {
    final normalizedPackageName = _normalize(packageName);
    if (normalizedPackageName.isEmpty) {
      return;
    }

    final packages = await getIgnoredPackages();
    packages.remove(normalizedPackageName);
    await _save(packages);
  }

  Future<bool> contains(String packageName) async {
    final normalizedPackageName = _normalize(packageName);
    if (normalizedPackageName.isEmpty) {
      return false;
    }

    return (await getIgnoredPackages()).contains(normalizedPackageName);
  }

  Future<void> _save(Set<String> packages) async {
    final values = packages.where((value) => value.isNotEmpty).toList()..sort();
    await _preferences.setStringList(keyIgnoredApps, values);
  }

  String _normalize(String packageName) {
    return packageName.trim().toLowerCase();
  }
}

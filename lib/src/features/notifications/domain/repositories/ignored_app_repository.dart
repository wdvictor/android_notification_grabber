import '../entities/installed_app.dart';

abstract interface class IgnoredAppRepository {
  Future<List<InstalledApp>> getInstalledApps();
  Future<void> addIgnoredApp(String packageName);
  Future<void> removeIgnoredApp(String packageName);
  Future<bool> isIgnoredApp(String packageName);
}

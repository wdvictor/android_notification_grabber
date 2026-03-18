import '../../domain/entities/installed_app.dart';
import '../../domain/repositories/ignored_app_repository.dart';
import '../datasources/ignored_app_store_data_source.dart';
import '../datasources/platform_bridge_data_source.dart';
import '../models/installed_app_model.dart';

class IgnoredAppRepositoryImpl implements IgnoredAppRepository {
  IgnoredAppRepositoryImpl({
    required PlatformBridgeDataSource platformBridgeDataSource,
    required IgnoredAppStoreDataSource ignoredAppStoreDataSource,
  }) : _platformBridgeDataSource = platformBridgeDataSource,
       _ignoredAppStoreDataSource = ignoredAppStoreDataSource;

  final PlatformBridgeDataSource _platformBridgeDataSource;
  final IgnoredAppStoreDataSource _ignoredAppStoreDataSource;

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    final rawApps = await _platformBridgeDataSource.getInstalledApplications();
    final ignoredPackages = await _ignoredAppStoreDataSource
        .getIgnoredPackages();
    final appsByPackageName = <String, InstalledApp>{};

    for (final rawApp in rawApps) {
      final model = InstalledAppModel.fromMap(rawApp);
      final normalizedPackageName = _normalize(model.packageName);
      if (normalizedPackageName.isEmpty) {
        continue;
      }

      appsByPackageName[normalizedPackageName] = model.toEntity(
        isIgnored: ignoredPackages.contains(normalizedPackageName),
      );
    }

    for (final ignoredPackageName in ignoredPackages) {
      appsByPackageName.putIfAbsent(
        ignoredPackageName,
        () => InstalledApp(
          name: ignoredPackageName,
          packageName: ignoredPackageName,
          isIgnored: true,
        ),
      );
    }

    final apps = appsByPackageName.values.toList();
    apps.sort(_compareApps);
    return apps;
  }

  @override
  Future<void> addIgnoredApp(String packageName) {
    return _ignoredAppStoreDataSource.add(packageName);
  }

  @override
  Future<void> removeIgnoredApp(String packageName) {
    return _ignoredAppStoreDataSource.remove(packageName);
  }

  @override
  Future<bool> isIgnoredApp(String packageName) {
    return _ignoredAppStoreDataSource.contains(packageName);
  }

  int _compareApps(InstalledApp left, InstalledApp right) {
    if (left.isIgnored != right.isIgnored) {
      return left.isIgnored ? -1 : 1;
    }

    final nameComparison = left.name.toLowerCase().compareTo(
      right.name.toLowerCase(),
    );
    if (nameComparison != 0) {
      return nameComparison;
    }

    return left.packageName.toLowerCase().compareTo(
      right.packageName.toLowerCase(),
    );
  }

  String _normalize(String packageName) {
    return packageName.trim().toLowerCase();
  }
}

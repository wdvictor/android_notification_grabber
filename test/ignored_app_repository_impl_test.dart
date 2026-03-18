import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/ignored_app_store_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/datasources/platform_bridge_data_source.dart';
import 'package:notification_grabber/src/features/notifications/data/repositories/ignored_app_repository_impl.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_shared_preferences_async_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        FakeSharedPreferencesAsyncPlatform();
  });

  group('IgnoredAppRepositoryImpl', () {
    test('adiciona um app à lista de ignorados', () async {
      final repository = IgnoredAppRepositoryImpl(
        platformBridgeDataSource: _FakePlatformBridgeDataSource(),
        ignoredAppStoreDataSource: IgnoredAppStoreDataSource(),
      );

      await repository.addIgnoredApp('com.alpha.bank');
      final apps = await repository.getInstalledApps();

      expect(apps.map((app) => (app.name, app.isIgnored)), [
        ('Alpha Bank', true),
        ('Beta Wallet', false),
        ('Zeta Mail', false),
      ]);
    });

    test('remove um app da lista de ignorados', () async {
      final repository = IgnoredAppRepositoryImpl(
        platformBridgeDataSource: _FakePlatformBridgeDataSource(),
        ignoredAppStoreDataSource: IgnoredAppStoreDataSource(),
      );

      await repository.addIgnoredApp('com.alpha.bank');
      await repository.removeIgnoredApp('com.alpha.bank');
      final apps = await repository.getInstalledApps();

      final alphaBank = apps.firstWhere(
        (app) => app.packageName == 'com.alpha.bank',
      );

      expect(alphaBank.isIgnored, isFalse);
      expect(await repository.isIgnoredApp('com.alpha.bank'), isFalse);
    });
  });
}

class _FakePlatformBridgeDataSource extends PlatformBridgeDataSource {
  @override
  Future<List<Map<Object?, Object?>>> getInstalledApplications() async {
    return [
      <Object?, Object?>{
        'name': 'Beta Wallet',
        'packageName': 'com.beta.wallet',
        'icon': Uint8List.fromList([1, 2, 3]),
      },
      <Object?, Object?>{
        'name': 'Alpha Bank',
        'packageName': 'com.alpha.bank',
        'icon': Uint8List.fromList([4, 5, 6]),
      },
      <Object?, Object?>{
        'name': 'Zeta Mail',
        'packageName': 'com.zeta.mail',
        'icon': Uint8List.fromList([7, 8, 9]),
      },
    ];
  }
}

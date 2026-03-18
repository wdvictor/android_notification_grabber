import 'package:uuid/uuid.dart';

import '../core/network/app_http_client_factory.dart';
import '../features/all_notifications/application/all_notifications_facade.dart';
import '../features/all_notifications/data/datasources/all_notifications_remote_data_source.dart';
import '../features/all_notifications/data/repositories/all_notifications_repository_impl.dart';
import '../features/all_notifications/presentation/controllers/all_notifications_controller.dart';
import '../features/notifications/application/notifications_background_facade.dart';
import '../features/notifications/application/notifications_presentation_facade.dart';
import '../features/notifications/data/datasources/ignored_app_store_data_source.dart';
import '../features/notifications/data/datasources/local_failure_notification_data_source.dart';
import '../features/notifications/data/datasources/notification_delivery_data_source.dart';
import '../features/notifications/data/datasources/offline_notification_store_data_source.dart';
import '../features/notifications/data/datasources/platform_bridge_data_source.dart';
import '../features/notifications/data/repositories/app_bridge_repository_impl.dart';
import '../features/notifications/data/repositories/failure_notification_repository_impl.dart';
import '../features/notifications/data/repositories/ignored_app_repository_impl.dart';
import '../features/notifications/data/repositories/notification_processing_repository_impl.dart';
import '../features/notifications/presentation/controllers/app_controller.dart';
import 'background_channel_handler.dart';

class DependencyContainer {
  const DependencyContainer._();

  static AllNotificationsController createAllNotificationsController() {
    final platformBridgeDataSource = const PlatformBridgeDataSource();
    final httpClient = AppHttpClientFactory.create();
    final repository = AllNotificationsRepositoryImpl(
      platformBridgeDataSource: platformBridgeDataSource,
      remoteDataSource: AllNotificationsRemoteDataSource(
        httpClient: httpClient,
      ),
    );
    final facade = AllNotificationsFacadeImpl(repository);

    return AllNotificationsController(facade);
  }

  static AppController createAppController() {
    final platformBridgeDataSource = const PlatformBridgeDataSource();
    final httpClient = AppHttpClientFactory.create();
    final offlineNotificationStoreDataSource =
        OfflineNotificationStoreDataSource();
    final ignoredAppRepository = IgnoredAppRepositoryImpl(
      platformBridgeDataSource: platformBridgeDataSource,
      ignoredAppStoreDataSource: IgnoredAppStoreDataSource(),
    );
    final localFailureNotificationDataSource =
        LocalFailureNotificationDataSource();
    final notificationProcessingRepository =
        NotificationProcessingRepositoryImpl(
          platformBridgeDataSource: platformBridgeDataSource,
          offlineNotificationStoreDataSource:
              offlineNotificationStoreDataSource,
          notificationDeliveryDataSource: NotificationDeliveryDataSource(
            httpClient: httpClient,
          ),
          ignoredAppRepository: ignoredAppRepository,
          localFailureNotificationDataSource:
              localFailureNotificationDataSource,
          uuid: const Uuid(),
          notifyOfflineNotificationsChanged: () async {},
        );

    final appBridgeRepository = AppBridgeRepositoryImpl(
      platformBridgeDataSource,
    );
    final failureNotificationRepository = FailureNotificationRepositoryImpl(
      localFailureNotificationDataSource,
    );

    final facade = NotificationsPresentationFacadeImpl(
      platformBridgeDataSource: platformBridgeDataSource,
      appBridgeRepository: appBridgeRepository,
      notificationProcessingRepository: notificationProcessingRepository,
      ignoredAppRepository: ignoredAppRepository,
      failureNotificationRepository: failureNotificationRepository,
    );

    return AppController(facade);
  }

  static BackgroundChannelHandler createBackgroundChannelHandler() {
    final platformBridgeDataSource = const PlatformBridgeDataSource();
    final httpClient = AppHttpClientFactory.create();
    final ignoredAppRepository = IgnoredAppRepositoryImpl(
      platformBridgeDataSource: platformBridgeDataSource,
      ignoredAppStoreDataSource: IgnoredAppStoreDataSource(),
    );
    final backgroundFacade = NotificationsBackgroundFacadeImpl(
      NotificationProcessingRepositoryImpl(
        platformBridgeDataSource: platformBridgeDataSource,
        offlineNotificationStoreDataSource:
            OfflineNotificationStoreDataSource(),
        notificationDeliveryDataSource: NotificationDeliveryDataSource(
          httpClient: httpClient,
        ),
        ignoredAppRepository: ignoredAppRepository,
        localFailureNotificationDataSource:
            LocalFailureNotificationDataSource(),
        uuid: const Uuid(),
      ),
    );

    return BackgroundChannelHandler(backgroundFacade);
  }
}

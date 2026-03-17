import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'src/app/dependency_container.dart';
import 'src/features/notifications/data/datasources/platform_bridge_data_source.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotificationGrabberApp());
}

@pragma('vm:entry-point')
void notificationBackgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final backgroundHandler =
      DependencyContainer.createBackgroundChannelHandler();
  const channel = MethodChannel(PlatformBridgeDataSource.channelName);

  channel.setMethodCallHandler(backgroundHandler.handle);
  backgroundHandler.notifyReady();
}

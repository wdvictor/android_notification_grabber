import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app/dependency_container.dart';
import 'src/features/notifications/presentation/controllers/app_controller.dart';
import 'src/features/notifications/presentation/pages/home_page.dart';

class NotificationGrabberApp extends StatefulWidget {
  const NotificationGrabberApp({super.key, AppController? controller})
    : _controller = controller;

  final AppController? _controller;

  @override
  State<NotificationGrabberApp> createState() => _NotificationGrabberAppState();
}

class _NotificationGrabberAppState extends State<NotificationGrabberApp> {
  late final AppController _controller =
      widget._controller ?? DependencyContainer.createAppController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme();

    return MaterialApp(
      title: 'Notification Grabber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E7490),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF0E7490),
              secondary: const Color(0xFFEA580C),
              surface: const Color(0xFFF8FAFC),
            ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        textTheme: baseTextTheme.copyWith(
          bodySmall: GoogleFonts.ibmPlexMono(
            textStyle: baseTextTheme.bodySmall,
          ),
          labelSmall: GoogleFonts.ibmPlexMono(
            textStyle: baseTextTheme.labelSmall,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F766E),
          contentTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: HomePage(controller: _controller),
    );
  }
}

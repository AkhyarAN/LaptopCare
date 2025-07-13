import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/laptop_provider.dart';
import 'data/providers/task_provider.dart';
import 'data/providers/reminder_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/guide_provider.dart';
import 'data/providers/history_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optimize for performance
  _optimizePerformance();

  // Initialize app (including guide seeding)
  try {
    await AppInitializer.initialize();
    debugPrint('✅ App initialization successful');
  } catch (e) {
    debugPrint('⚠️ App initialization error: $e');
    // Continue anyway - app should work with limited functionality
  }

  // Initialize timezone database
  try {
    tz.initializeTimeZones();
    debugPrint('✅ Timezone initialization successful');
  } catch (e) {
    debugPrint('⚠️ Timezone initialization error: $e');
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
    debugPrint('✅ Notification service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to initialize notifications: $e');
    // Continue anyway - app should work without notifications
  }

  // Handle mouse tracker errors on Windows
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore errors related to mouse tracker
    if (details.exception.toString().contains('MouseTracker') ||
        details.exception.toString().contains('Cannot hit test') ||
        details.exception.toString().contains('render box with no size')) {
      // Ignore these errors
      return;
    }

    // Show other errors as usual
    FlutterError.presentError(details);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LaptopProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => GuideProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

void _optimizePerformance() {
  // Enable immersive UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
}

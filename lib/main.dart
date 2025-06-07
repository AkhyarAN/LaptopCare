import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/laptop_provider.dart';
import 'data/providers/task_provider.dart';
import 'data/providers/reminder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Mengatasi masalah mouse tracker error di Windows
  FlutterError.onError = (FlutterErrorDetails details) {
    // Abaikan error yang terkait dengan mouse tracker
    if (details.exception.toString().contains('MouseTracker') ||
        details.exception.toString().contains('Cannot hit test') ||
        details.exception.toString().contains('render box with no size')) {
      // Ignore these errors
      return;
    }

    // Tampilkan error lainnya seperti biasa
    FlutterError.presentError(details);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LaptopProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

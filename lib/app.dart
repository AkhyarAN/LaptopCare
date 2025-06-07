import 'package:flutter/material.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/home/add_laptop_screen.dart';
import 'ui/screens/home/add_task_screen.dart';
import 'ui/screens/home/add_reminder_screen.dart';
import 'ui/screens/auth/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaptopCare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/add_laptop': (context) => const AddLaptopScreen(),
        '/add_task': (context) => const AddTaskScreen(),
        '/add_reminder': (context) => const AddReminderScreen(),
      },
    );
  }
}

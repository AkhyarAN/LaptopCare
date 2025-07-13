import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/home/add_laptop_screen.dart';
import 'ui/screens/home/add_task_screen.dart';
import 'ui/screens/home/add_reminder_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'data/providers/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
    return MaterialApp(
      title: 'LaptopCare',
      debugShowCheckedModeBanner: false,

          // Optimize for high refresh rate displays (90Hz, 120Hz)
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),

          // Smooth page transitions for high refresh rate
          theme: themeProvider.isDarkMode
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,

          // Enhanced page transition animations
          onGenerateRoute: (settings) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) {
                return _getScreenForRoute(settings.name ?? '/');
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                // Use curves optimized for high refresh rate displays
                const curve = Curves.easeInOutCubicEmphasized;
                const duration = Duration(milliseconds: 350);

                var fadeAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: curve,
                ));

                var scaleAnimation = Tween<double>(
                  begin: 0.95,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: curve,
                ));

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
              reverseTransitionDuration: const Duration(milliseconds: 300),
            );
          },

          home: const SplashScreen(),
      routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/add_laptop': (context) => const AddLaptopScreen(),
        '/add_task': (context) => const AddTaskScreen(),
        '/add_reminder': (context) => const AddReminderScreen(),
      },
    );
      },
    );
  }

  Widget _getScreenForRoute(String route) {
    switch (route) {
      case '/login':
        return const LoginScreen();
      case '/register':
        return const RegisterScreen();
      case '/home':
        return const HomeScreen();
      case '/add_laptop':
        return const AddLaptopScreen();
      case '/add_task':
        return const AddTaskScreen();
      case '/add_reminder':
        return const AddReminderScreen();
      default:
        return const SplashScreen();
    }
  }
}

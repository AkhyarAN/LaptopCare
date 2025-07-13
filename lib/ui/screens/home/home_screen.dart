import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/reminder_provider.dart';
import '../../../data/providers/guide_provider.dart';
import '../../../data/providers/history_provider.dart';
import 'laptop_list_screen.dart';
import 'task_list_screen.dart';
import 'reminder_list_screen.dart';
import 'guide_list_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _lastUserId; // Track user terakhir yang load data

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.currentUser != null) {
      final currentUserId = authProvider.currentUser!.id;

      // Cek apakah user berubah
      if (_lastUserId != currentUserId) {
        debugPrint(
            'User berubah dari $_lastUserId ke $currentUserId - clear semua data');

        _handleUserChange(currentUserId);
      } else {
        // Cek apakah perlu load data initial
        _checkAndLoadInitialData(currentUserId);
      }
    }
  }

  void _checkAndLoadInitialData(String currentUserId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final laptopProvider =
          Provider.of<LaptopProvider>(context, listen: false);
      final guideProvider = Provider.of<GuideProvider>(context, listen: false);

      // Load data jika list kosong untuk user yang sama
      if (laptopProvider.laptops.isEmpty) {
        debugPrint('Load initial data untuk user $currentUserId');
        laptopProvider.fetchLaptops(currentUserId);
      }

      // Load guides jika belum ada (guides tidak user-specific)
      if (guideProvider.guides.isEmpty) {
        debugPrint('Load guides data');
        guideProvider.fetchGuides();
      }
    });
  }

  void _handleUserChange(String currentUserId) {
    // Gunakan post frame callback untuk avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final laptopProvider =
          Provider.of<LaptopProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final reminderProvider =
          Provider.of<ReminderProvider>(context, listen: false);
      final guideProvider = Provider.of<GuideProvider>(context, listen: false);
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);

      // Clear data lama dari semua provider
      laptopProvider.clearData();
      taskProvider.clearData();
      reminderProvider.clearData();
      guideProvider.clearData();
      historyProvider.clearData();

      // Load data user baru
      laptopProvider.fetchLaptops(currentUserId);

      _lastUserId = currentUserId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaptopCare'),
        actions: [
          if (_currentIndex < 3)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to add screen based on current index
                switch (_currentIndex) {
                  case 0:
                    Navigator.pushNamed(context, '/add_laptop');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/add_task');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/add_reminder');
                    break;
                }
              },
            ),
          // Add statistics quick access
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              // Refresh HistoryProvider sebelum membuka StatisticsScreen
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final historyProvider =
                  Provider.of<HistoryProvider>(context, listen: false);

              if (authProvider.currentUser != null) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await historyProvider
                      .fetchHistory(authProvider.currentUser!.id);
                  if (mounted) Navigator.pop(context); // Close loading dialog
                } catch (e) {
                  if (mounted) Navigator.pop(context); // Close loading dialog
                  debugPrint('Error refreshing history: $e');
                }
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
            tooltip: 'Statistik',
          ),
        ],
      ),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.laptop),
            label: 'Laptops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Fetch guides ketika tab Panduan diklik
          if (index == 3) {
            final guideProvider =
                Provider.of<GuideProvider>(context, listen: false);
            guideProvider.fetchGuides();
          }
        },
      ),
    );
  }

  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return const LaptopListScreen();
      case 1:
        return const TaskListScreen();
      case 2:
        return const ReminderListScreen();
      case 3:
        return const GuideListScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const LaptopListScreen();
    }
  }
}

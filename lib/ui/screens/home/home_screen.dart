import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import 'laptop_list_screen.dart';
import 'task_list_screen.dart';
import 'reminder_list_screen.dart';
import 'profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final laptopProvider = Provider.of<LaptopProvider>(context);

    if (authProvider.currentUser == null) {
      return const LoginScreen();
    }

    // Load user data
    if (laptopProvider.laptops.isEmpty) {
      // Load laptops for current user
      final userId = authProvider.currentUser!.id;
      laptopProvider.fetchLaptops(userId);
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
        ],
      ),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
        return const ProfileScreen();
      default:
        return const LaptopListScreen();
    }
  }
}
 
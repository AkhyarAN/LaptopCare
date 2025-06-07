import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laptop_care/data/providers/task_provider.dart';
import 'package:laptop_care/data/providers/auth_provider.dart';
import 'package:laptop_care/ui/components/task_list_item.dart';
import 'package:laptop_care/ui/screens/add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tasks when screen loads
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<TaskProvider>(context, listen: false)
            .fetchTasks(userId: authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${taskProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authProvider.currentUser != null
                        ? taskProvider.fetchTasks(
                            userId: authProvider.currentUser!.id)
                        : null,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToAddTask(context),
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => authProvider.currentUser != null
                ? taskProvider.fetchTasks(userId: authProvider.currentUser!.id)
                : Future.value(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: taskProvider.tasks.length,
              itemBuilder: (context, index) {
                final task = taskProvider.tasks[index];
                return TaskListItem(
                  task: task,
                  onToggleComplete: () =>
                      taskProvider.toggleTaskCompletion(task),
                  onDelete: () => taskProvider.deleteTask(task.taskId),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddTask(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );

    if (result == true) {
      if (!mounted) return;
      // Task added successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully')),
      );
    }
  }
}

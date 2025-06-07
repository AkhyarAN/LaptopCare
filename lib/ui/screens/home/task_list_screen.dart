import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/models/maintenance_task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final laptopProvider = Provider.of<LaptopProvider>(context);

    if (taskProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (laptopProvider.selectedLaptop == null) {
      return const Center(
        child: Text('Please select a laptop first'),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Physical'),
            Tab(text: 'Software'),
            Tab(text: 'Security'),
          ],
          onTap: (index) {
            setState(() {
              if (index == 0) {
                taskProvider.setSelectedCategory(null);
              } else {
                taskProvider
                    .setSelectedCategory(TaskCategory.values[index - 1]);
              }
            });
          },
        ),
        Expanded(
          child: taskProvider.tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add maintenance tasks for your laptop',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to add task screen
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: taskProvider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = taskProvider.tasks[index];

                    // If a category is selected, filter tasks
                    if (taskProvider.selectedCategory != null &&
                        task.category != taskProvider.selectedCategory) {
                      return const SizedBox.shrink();
                    }

                    return TaskListItem(task: task);
                  },
                ),
        ),
      ],
    );
  }
}

class TaskListItem extends StatelessWidget {
  final MaintenanceTask task;

  const TaskListItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCategoryIcon(task.category),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(task.frequency.name),
                  backgroundColor: _getFrequencyColor(task.frequency),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                Chip(
                  label: Text(task.priority.name),
                  backgroundColor: _getPriorityColor(task.priority),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(TaskCategory category) {
    IconData iconData;
    Color color;

    switch (category) {
      case TaskCategory.physical:
        iconData = Icons.build;
        color = Colors.orange;
        break;
      case TaskCategory.software:
        iconData = Icons.code;
        color = Colors.blue;
        break;
      case TaskCategory.security:
        iconData = Icons.security;
        color = Colors.red;
        break;
      case TaskCategory.performance:
        iconData = Icons.speed;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  Color _getFrequencyColor(TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return Colors.red;
      case TaskFrequency.weekly:
        return Colors.orange;
      case TaskFrequency.monthly:
        return Colors.blue;
      case TaskFrequency.quarterly:
        return Colors.green;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

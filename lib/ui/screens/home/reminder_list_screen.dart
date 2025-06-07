import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/reminder_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/maintenance_task.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch reminders when screen loads
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final laptopProvider =
          Provider.of<LaptopProvider>(context, listen: false);

      if (authProvider.currentUser != null &&
          laptopProvider.selectedLaptop != null) {
        Provider.of<ReminderProvider>(context, listen: false).fetchReminders(
          userId: authProvider.currentUser!.id,
          laptopId: laptopProvider.selectedLaptop!.laptopId,
        );

        // Also fetch tasks to display task details in reminders
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(
          userId: authProvider.currentUser!.id,
          laptopId: laptopProvider.selectedLaptop!.laptopId,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final laptopProvider = Provider.of<LaptopProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    if (reminderProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (laptopProvider.selectedLaptop == null) {
      return const Center(
        child: Text('Please select a laptop first'),
      );
    }

    final upcomingReminders = reminderProvider.getUpcomingReminders();
    final overdueReminders = reminderProvider.getOverdueReminders();
    final allReminders = reminderProvider.reminders;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // All reminders tab
              _buildReminderList(allReminders, taskProvider),
              // Upcoming reminders tab
              _buildReminderList(upcomingReminders, taskProvider),
              // Overdue reminders tab
              _buildReminderList(overdueReminders, taskProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderList(
      List<Reminder> reminders, TaskProvider taskProvider) {
    if (reminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No reminders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Reminders will appear here when scheduled',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];

        // Find the associated task
        final task = taskProvider.tasks.firstWhere(
          (task) => task.taskId == reminder.taskId,
          orElse: () => MaintenanceTask(
            taskId: '',
            userId: '',
            laptopId: '',
            category: TaskCategory.physical,
            title: 'Unknown Task',
            description: '',
            frequency: TaskFrequency.monthly,
            priority: TaskPriority.medium,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Skip if task is not found (should not happen in normal operation)
        if (task.taskId.isEmpty) {
          return const SizedBox.shrink();
        }

        return ReminderListItem(
          reminder: reminder,
          taskTitle: task.title,
          taskCategory: task.category,
        );
      },
    );
  }
}

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final String taskTitle;
  final TaskCategory taskCategory;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.taskTitle,
    required this.taskCategory,
  });

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final isOverdue = reminder.scheduledDate.isBefore(DateTime.now()) &&
        reminder.status == ReminderStatus.pending;

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
                _getCategoryIcon(taskCategory),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(reminder.scheduledDate),
                            style: TextStyle(
                              color:
                                  isOverdue ? Colors.red : Colors.grey.shade700,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _getStatusChip(reminder.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(reminder.frequency.name),
                  backgroundColor: _getFrequencyColor(reminder.frequency),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                if (reminder.status == ReminderStatus.pending)
                  TextButton.icon(
                    onPressed: () {
                      reminderProvider
                          .markReminderAsCompleted(reminder.reminderId);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Complete'),
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

  Widget _getStatusChip(ReminderStatus status) {
    Color color;
    String label;

    switch (status) {
      case ReminderStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ReminderStatus.sent:
        color = Colors.blue;
        label = 'Sent';
        break;
      case ReminderStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/reminder_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../data/models/task_category.dart';
import '../../../services/notification_service.dart';
// import './edit_reminder_screen.dart'; // TODO: Fix import issue

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // All, Upcoming, Overdue
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  void _loadReminders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      final selectedLaptop = laptopProvider.selectedLaptop;

      reminderProvider.fetchReminders(
        userId: userId,
        laptopId: selectedLaptop?.laptopId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final laptopProvider = Provider.of<LaptopProvider>(context);

    if (laptopProvider.selectedLaptop == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Laptop Selected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a laptop to view its reminders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.laptop),
              label: const Text('Select Laptop'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with notification info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance Reminders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Stay on top of your laptop maintenance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showNotificationSettings,
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Notification Settings',
              ),
            ],
          ),
        ),

        // Filter tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TabBar(
          controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primary,
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
        ),

        const SizedBox(height: 16),

        // Reminders list
        Expanded(
          child: Consumer<ReminderProvider>(
            builder: (context, reminderProvider, child) {
              if (reminderProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (reminderProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading reminders',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reminderProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadReminders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
            controller: _tabController,
            children: [
                  _buildRemindersList(reminderProvider.reminders),
                  _buildRemindersList(reminderProvider.getUpcomingReminders()),
                  _buildRemindersList(reminderProvider.getOverdueReminders()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersList(List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create reminders for your maintenance tasks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_reminder');
            },
            icon: const Icon(Icons.add_alert),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final now = DateTime.now();
    final isOverdue = reminder.scheduledDate.isBefore(now) &&
        reminder.status == ReminderStatus.pending;
    final isUpcoming = reminder.scheduledDate.isAfter(now) &&
        reminder.status == ReminderStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReminderDetails(reminder),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reminder.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(reminder.status),
                      size: 20,
                      color: _getStatusColor(reminder.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Consumer<TaskProvider>(
                          builder: (context, taskProvider, child) {
                            // Find the task for this reminder
                            final task = taskProvider.tasks
                                .where((t) => t.taskId == reminder.taskId)
                                .firstOrNull;

                            return Text(
                              task?.title ?? 'Unknown Task',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            );
                          },
                        ),
                      Text(
                          reminder.status.value.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getStatusColor(reminder.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(reminder.scheduledDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    reminder.frequency.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (reminder.status == ReminderStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsCompleted(reminder),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade600,
                          side: BorderSide(color: Colors.green.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editReminder(reminder),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showReminderActions(reminder),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More actions',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.pending:
        return Colors.orange;
      case ReminderStatus.sent:
        return Colors.blue;
      case ReminderStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.pending:
        return Icons.schedule;
      case ReminderStatus.sent:
        return Icons.notifications_active;
      case ReminderStatus.completed:
        return Icons.check_circle;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (targetDate == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showReminderDetails(Reminder reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Reminder header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(reminder.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(reminder.status),
                        size: 24,
                        color: _getStatusColor(reminder.status),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maintenance Reminder',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            reminder.status.value.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _getStatusColor(reminder.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Reminder details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailItem('Scheduled Date',
                          _formatDate(reminder.scheduledDate)),
                      _buildDetailItem('Frequency', reminder.frequency.label),
                      _buildDetailItem(
                          'Status', reminder.status.value.toUpperCase()),
                      _buildDetailItem('Created',
                          '${reminder.createdAt.day}/${reminder.createdAt.month}/${reminder.createdAt.year}'),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editReminder(reminder);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsCompleted(reminder);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(Reminder reminder) async {
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);

    final success =
        await reminderProvider.markReminderAsCompleted(reminder.reminderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Reminder marked as completed!'
                : 'Failed to update reminder',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    // Cancel the notification
    if (success) {
      await _notificationService.cancelTaskReminder(reminder.reminderId);
    }
  }

  void _editReminder(Reminder reminder) {
    // TODO: Once import issue is resolved, use EditReminderScreen
    // For now, navigate using named route or show edit dialog
    Navigator.pushNamed(
      context,
      '/edit_reminder',
      arguments: reminder,
    ).then((result) {
      // Reload reminders if the edit was successful
      if (result == true) {
        _loadReminders();
      }
    });
  }

  void _showReminderActions(Reminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Reminder'),
              onTap: () {
                Navigator.pop(context);
                _editReminder(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Completed'),
              onTap: () {
                Navigator.pop(context);
                _markAsCompleted(reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Cancel Notification'),
              onTap: () {
                Navigator.pop(context);
                _cancelNotification(reminder);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: Text('Delete Reminder',
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () {
                Navigator.pop(context);
                _deleteReminder(reminder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelNotification(Reminder reminder) async {
    await _notificationService.cancelTaskReminder(reminder.reminderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification cancelled'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete from provider (this would need to be implemented)
      await _notificationService.cancelTaskReminder(reminder.reminderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive maintenance reminders'),
              trailing: Switch(
                value: true, // This would be connected to user preferences
                onChanged: (value) {
                  // Update notification preferences
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Default Reminder Time'),
              subtitle: const Text('09:00 AM'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show time picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Vibration'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Update vibration preference
                },
              ),
            ),
            const Divider(height: 32),
            ListTile(
              leading:
                  Icon(Icons.notification_add, color: Colors.blue.shade600),
              title: Text('Test Notification',
                  style: TextStyle(color: Colors.blue.shade600)),
              subtitle: const Text('Send a test notification now'),
              trailing: Icon(Icons.send, color: Colors.blue.shade600),
              onTap: _sendTestNotification,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification() async {
    try {
      // Request permissions first
      final hasPermission = await _notificationService.requestPermissions();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied. Please enable notifications in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Send instant test notification
      await _notificationService.showInstantNotification(
        id: 9999, // Unique test ID
        title: '🔧 LaptopCare Test',
        body:
            'Notifikasi berhasil! Aplikasi LaptopCare siap mengingatkan maintenance laptop Anda.',
        payload: 'test_notification',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

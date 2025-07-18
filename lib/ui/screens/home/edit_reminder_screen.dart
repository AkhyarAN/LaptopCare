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

class EditReminderScreen extends StatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({
    super.key,
    required this.reminder,
  });

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final NotificationService _notificationService = NotificationService();

  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  late TaskFrequency _frequency;
  late String _selectedTaskId;
  late ReminderStatus _status;

  bool _isLoading = false;
  List<MaintenanceTask> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadTasks();
  }

  void _initializeFields() {
    _scheduledDate = DateTime(
      widget.reminder.scheduledDate.year,
      widget.reminder.scheduledDate.month,
      widget.reminder.scheduledDate.day,
    );
    _scheduledTime = TimeOfDay.fromDateTime(widget.reminder.scheduledDate);
    _frequency = widget.reminder.frequency;
    _selectedTaskId = widget.reminder.taskId;
    _status = widget.reminder.status;
  }

  void _loadTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (authProvider.currentUser != null &&
        laptopProvider.selectedLaptop != null) {
      final userId = authProvider.currentUser!.id;
      final laptopId = laptopProvider.selectedLaptop!.laptopId;

      taskProvider.fetchTasks(userId: userId, laptopId: laptopId).then((_) {
        setState(() {
          _availableTasks = taskProvider.tasks;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveReminder,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current reminder info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editing Reminder',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${_formatDate(widget.reminder.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Task selection
            _buildSectionHeader('Maintenance Task'),
            const SizedBox(height: 8),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading && _availableTasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (_availableTasks.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No maintenance tasks available',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create some tasks first before setting reminders',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedTaskId,
                  decoration: InputDecoration(
                    labelText: 'Select Task',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.assignment),
                  ),
                  items: _availableTasks.map((task) {
                    return DropdownMenuItem<String>(
                      value: task.taskId,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (task.description.isNotEmpty)
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTaskId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a maintenance task';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Date and time
            _buildSectionHeader('Schedule'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(_formatDate(_scheduledDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(_scheduledTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Frequency
            _buildSectionHeader('Frequency'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskFrequency>(
              value: _frequency,
              decoration: InputDecoration(
                labelText: 'Repeat Frequency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: TaskFrequency.values.map((frequency) {
                return DropdownMenuItem<TaskFrequency>(
                  value: frequency,
                  child: Text(frequency.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequency = value;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Status
            _buildSectionHeader('Status'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderStatus>(
              value: _status,
              decoration: InputDecoration(
                labelText: 'Reminder Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.flag),
              ),
              items: ReminderStatus.values.map((status) {
                return DropdownMenuItem<ReminderStatus>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Text(status.value.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveReminder,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );

    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderProvider =
          Provider.of<ReminderProvider>(context, listen: false);

      // Combine date and time
      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      // Update the reminder
      final success = await reminderProvider.updateReminder(
        reminderId: widget.reminder.reminderId,
        taskId: _selectedTaskId,
        scheduledDate: scheduledDateTime,
        frequency: _frequency,
        status: _status,
      );

      if (success) {
        // Update notification if the reminder is still pending
        if (_status == ReminderStatus.pending) {
          // Cancel old notification
          await _notificationService
              .cancelTaskReminder(widget.reminder.reminderId);

          // Schedule new notification
          final selectedTask = _availableTasks.firstWhere(
            (task) => task.taskId == _selectedTaskId,
          );

          await _notificationService.scheduleTaskReminder(
            reminder: widget.reminder.copyWith(
              taskId: _selectedTaskId,
              scheduledDate: scheduledDateTime,
              frequency: _frequency,
              status: _status,
            ),
            task: selectedTask,
            laptopName: Provider.of<LaptopProvider>(context, listen: false)
                    .selectedLaptop
                    ?.name ??
                'Unknown Laptop',
          );
        } else {
          // Cancel notification if status is not pending
          await _notificationService
              .cancelTaskReminder(widget.reminder.reminderId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update reminder. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

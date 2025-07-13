import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/reminder_provider.dart';
import '../../../data/models/maintenance_task.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTaskId;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  TaskFrequency _frequency = TaskFrequency.weekly;
  String? _selectedLaptopId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final laptopProvider = Provider.of<LaptopProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final reminderProvider = Provider.of<ReminderProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Create reminder form
              if (laptopProvider.laptops.isEmpty)
                const Center(
                  child: Text('Please add a laptop first'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Laptop dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Laptop',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedLaptopId,
                      items: laptopProvider.laptops.map((laptop) {
                        return DropdownMenuItem<String>(
                          value: laptop.laptopId,
                          child: Text(laptop.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLaptopId = value;
                          _selectedTaskId = null;
                        });
                        if (value != null) {
                          final userId = authProvider.currentUser!.id;
                          taskProvider.loadTasks(userId, laptopId: value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a laptop';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Task dropdown (only show if laptop is selected)
                    if (_selectedLaptopId != null)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Task',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedTaskId,
                        items: taskProvider.tasks
                            .where((task) => task.laptopId == _selectedLaptopId)
                            .map((task) {
                          return DropdownMenuItem<String>(
                            value: task.taskId,
                            child: Text(task.title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a task';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    // Date and Time pickers
                    Row(
                      children: [
                    // Date picker
                        Expanded(
                          flex: 2,
                          child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != _scheduledDate) {
                          setState(() {
                            _scheduledDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                                labelText: 'Date',
                          border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_scheduledDate),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Time picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _scheduledTime,
                              );
                              if (picked != null && picked != _scheduledTime) {
                                setState(() {
                                  _scheduledTime = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _scheduledTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quick time presets
                    Text(
                      'Quick Time Presets:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTimePreset(
                            '06:00', const TimeOfDay(hour: 6, minute: 0)),
                        _buildTimePreset(
                            '08:00', const TimeOfDay(hour: 8, minute: 0)),
                        _buildTimePreset(
                            '12:00', const TimeOfDay(hour: 12, minute: 0)),
                        _buildTimePreset(
                            '18:00', const TimeOfDay(hour: 18, minute: 0)),
                        _buildTimePreset(
                            '20:00', const TimeOfDay(hour: 20, minute: 0)),
                        _buildTimePreset(
                            '00:00', const TimeOfDay(hour: 0, minute: 0)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Preview scheduled time
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reminder akan dikirim pada:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(_scheduledDate)} at ${_scheduledTime.format(context)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Frequency dropdown
                    DropdownButtonFormField<TaskFrequency>(
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      value: _frequency,
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

                    // Submit button
                    ElevatedButton(
                      onPressed: reminderProvider.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                // Validate scheduled time is not in the past
                                final scheduledDateTime = DateTime(
                                  _scheduledDate.year,
                                  _scheduledDate.month,
                                  _scheduledDate.day,
                                  _scheduledTime.hour,
                                  _scheduledTime.minute,
                                );

                                if (scheduledDateTime
                                    .isBefore(DateTime.now())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Cannot schedule reminder for past time!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                _createReminder(
                                  context,
                                  authProvider,
                                  reminderProvider,
                                );
                              }
                            },
                      child: reminderProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create Reminder'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createReminder(
    BuildContext context,
    AuthProvider authProvider,
    ReminderProvider reminderProvider,
  ) async {
    if (_selectedTaskId == null || _selectedLaptopId == null) return;

    final userId = authProvider.currentUser!.id;

    // Combine date and time
    final scheduledDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final success = await reminderProvider.createReminder(
      userId: userId,
      laptopId: _selectedLaptopId!,
      taskId: _selectedTaskId!,
      scheduledDate: scheduledDateTime,
      frequency: _frequency,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reminder created successfully ✅'),
              Text(
                  'Scheduled for: ${scheduledDateTime.toString().substring(0, 16)}'),
              const Text(
                  'Notification akan dikirim sesuai jadwal yang ditentukan'),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildTimePreset(String label, TimeOfDay time) {
    final isSelected = _scheduledTime.hour == time.hour &&
        _scheduledTime.minute == time.minute;

    return InkWell(
      onTap: () {
        setState(() {
          _scheduledTime = time;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

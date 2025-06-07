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

                    // Date picker
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != _scheduledDate) {
                          setState(() {
                            _scheduledDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Scheduled Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_scheduledDate),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
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

    final success = await reminderProvider.createReminder(
      userId: userId,
      laptopId: _selectedLaptopId!,
      taskId: _selectedTaskId!,
      scheduledDate: _scheduledDate,
      frequency: _frequency,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder created successfully')),
      );
      Navigator.pop(context);
    }
  }
}

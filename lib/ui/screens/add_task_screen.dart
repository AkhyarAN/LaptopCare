import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laptop_care/data/providers/task_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:laptop_care/data/providers/auth_provider.dart';
import 'package:laptop_care/data/providers/laptop_provider.dart';
import 'package:laptop_care/data/models/maintenance_task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'Medium';
  final _uuid = const Uuid();
  bool _isLoading = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dueDate == null
                                ? 'No due date set'
                                : 'Due date: ${_formatDate(_dueDate!)}',
                          ),
                        ),
                        TextButton(
                          onPressed: _selectDueDate,
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: _priority,
                      items: _priorities
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final laptopProvider =
            Provider.of<LaptopProvider>(context, listen: false);

        if (authProvider.currentUser == null ||
            laptopProvider.selectedLaptop == null) {
          throw Exception("User or laptop not selected");
        }

        final userId = authProvider.currentUser!.id;
        final laptopId = laptopProvider.selectedLaptop!.laptopId;

        await Provider.of<TaskProvider>(context, listen: false).createTask(
          userId: userId,
          laptopId: laptopId,
          category: TaskCategory.physical, // Default category
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? ""
              : _descriptionController.text,
          frequency: TaskFrequency.monthly, // Default frequency
          priority: _priority == "Low"
              ? TaskPriority.low
              : _priority == "High"
                  ? TaskPriority.high
                  : TaskPriority.medium,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/history_provider.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../data/models/task_category.dart';
import '../../../utils/extensions/colors.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: TaskCategories.categories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      final selectedLaptop = laptopProvider.selectedLaptop;

      taskProvider.fetchTasks(
        userId: userId,
        laptopId: selectedLaptop?.laptopId,
        category: _selectedCategory,
      );
    }
  }

  void _onTabChanged() {
    setState(() {
      _selectedCategory =
          TaskCategories.categories[_tabController.index].category;
    });
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final laptopProvider = Provider.of<LaptopProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    if (laptopProvider.selectedLaptop == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.laptop_mac,
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
              'Please select a laptop to view its maintenance tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context)
                    ?.animateTo(0); // Navigate to laptops tab
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
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
            setState(() {
                _searchQuery = value;
            });
          },
        ),
        ),

        // Category tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            onTap: (_) => _onTabChanged(),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primary,
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            isScrollable: true,
            tabs: TaskCategories.categories.map((category) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      category.title.split(' ').first, // Show first word only
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Tasks list
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (taskProvider.error != null) {
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
                        'Error loading tasks',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        taskProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredTasks = _filterTasks(taskProvider.tasks);

              if (filteredTasks.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return _buildTaskCard(task, taskProvider);
                },
              );
                  },
                ),
        ),
      ],
    );
  }

  List<MaintenanceTask> _filterTasks(List<MaintenanceTask> tasks) {
    var filteredTasks = tasks;

    // Filter by selected category
    if (_selectedCategory != null) {
      filteredTasks = filteredTasks
          .where((task) => task.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) =>
              task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              task.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filteredTasks;
  }

  Widget _buildEmptyState() {
    final categoryInfo = _selectedCategory != null
        ? TaskCategories.getCategoryInfo(_selectedCategory!)
        : null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            categoryInfo?.icon ?? Icons.task_alt,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : categoryInfo != null
                    ? 'Add ${categoryInfo.title.toLowerCase()} tasks for this laptop'
                    : 'Add maintenance tasks for this laptop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_task');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(MaintenanceTask task, TaskProvider taskProvider) {
    final categoryInfo = TaskCategories.getCategoryInfo(task.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(task),
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
                      color: categoryInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryInfo.icon,
                      size: 20,
                      color: categoryInfo.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                          categoryInfo.title,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: categoryInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
                  _buildPriorityChip(task.priority),
              ],
            ),
            const SizedBox(height: 12),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
              children: [
                  _buildFrequencyChip(task.frequency),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _completeTask(task, taskProvider),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showTaskActions(task, taskProvider),
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

  Widget _buildPriorityChip(TaskPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(TaskFrequency frequency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            frequency.label,
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(MaintenanceTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final categoryInfo = TaskCategories.getCategoryInfo(task.category);

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

                // Task header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: categoryInfo.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
                        categoryInfo.icon,
        size: 24,
                        color: categoryInfo.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            categoryInfo.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: categoryInfo.color,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Task details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailItem('Description', task.description),
                      _buildDetailItem('Frequency', task.frequency.label),
                      _buildDetailItem(
                          'Priority', task.priority.value.toUpperCase()),
                      _buildDetailItem('Category', categoryInfo.title),
                      _buildDetailItem('Created',
                          '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}'),
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
                          // Navigate to edit task
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
                          _completeTask(
                              task,
                              Provider.of<TaskProvider>(context,
                                  listen: false));
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

  void _completeTask(MaintenanceTask task, TaskProvider taskProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: Text('Mark "${task.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await taskProvider.completeTask(
        userId: task.userId,
        laptopId: task.laptopId,
        taskId: task.taskId,
        notes: 'Completed via mobile app',
      );

      if (mounted) {
        if (success) {
          // Refresh HistoryProvider setelah task selesai
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final historyProvider =
              Provider.of<HistoryProvider>(context, listen: false);

          if (authProvider.currentUser != null) {
            await historyProvider.fetchHistory(authProvider.currentUser!.id);
            debugPrint('Task completed and history refreshed for statistics');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Task completed successfully! Check Statistics for updated data.'
                  : 'Failed to complete task',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showTaskActions(MaintenanceTask task, TaskProvider taskProvider) {
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
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit task
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Complete'),
              onTap: () {
                Navigator.pop(context);
                _completeTask(task, taskProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Set Reminder'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to add reminder
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: Text('Delete Task',
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () {
                Navigator.pop(context);
                _deleteTask(task, taskProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(MaintenanceTask task, TaskProvider taskProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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
      final success = await taskProvider.deleteTask(task.taskId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Task deleted successfully!' : 'Failed to delete task',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

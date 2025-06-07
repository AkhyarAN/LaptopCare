import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:appwrite_flutter_starter_kit/data/models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggleComplete(),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${DateFormat('MMM dd, yyyy').format(task.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (task.dueDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: _isDueDatePassed(task.dueDate!)
                            ? Colors.red
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDueDatePassed(task.dueDate!)
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: task.priority != null
                ? _buildPriorityBadge(task.priority!)
                : null,
          ),
        ),
      ),
    );
  }

  bool _isDueDatePassed(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

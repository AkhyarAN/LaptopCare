import 'package:flutter/material.dart';
import 'maintenance_task.dart';

class TaskCategoryInfo {
  final TaskCategory category;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<TaskTemplate> defaultTasks;

  const TaskCategoryInfo({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.defaultTasks,
  });
}

class TaskTemplate {
  final String title;
  final String description;
  final TaskFrequency defaultFrequency;
  final TaskPriority defaultPriority;

  const TaskTemplate({
    required this.title,
    required this.description,
    required this.defaultFrequency,
    required this.defaultPriority,
  });
}

class TaskCategories {
  static const List<TaskCategoryInfo> categories = [
    TaskCategoryInfo(
      category: TaskCategory.physical,
      title: 'Physical Maintenance',
      description: 'Hardware cleaning and physical care tasks',
      icon: Icons.cleaning_services,
      color: Color(0xFF2196F3), // Blue
      defaultTasks: [
        TaskTemplate(
          title: 'Clean keyboard and screen',
          description:
              'Use microfiber cloth to clean keyboard and screen surfaces',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Clean laptop vents and fans',
          description: 'Remove dust from vents and fans using compressed air',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Check and clean ports',
          description: 'Clean USB, HDMI, and other ports from dust and debris',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Inspect battery condition',
          description: 'Check battery health and charging performance',
          defaultFrequency: TaskFrequency.quarterly,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Check cable connections',
          description: 'Inspect power and data cables for wear or damage',
          defaultFrequency: TaskFrequency.quarterly,
          defaultPriority: TaskPriority.medium,
        ),
      ],
    ),
    TaskCategoryInfo(
      category: TaskCategory.software,
      title: 'Software Maintenance',
      description: 'Operating system and application maintenance',
      icon: Icons.computer,
      color: Color(0xFF4CAF50), // Green
      defaultTasks: [
        TaskTemplate(
          title: 'Install system updates',
          description: 'Check and install operating system updates',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Update installed applications',
          description: 'Update all installed software to latest versions',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Clean temporary files',
          description: 'Delete temporary files and clear system cache',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Defragment hard drive',
          description: 'Optimize hard drive performance (HDD only)',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Check startup programs',
          description: 'Review and optimize programs that start with Windows',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.low,
        ),
      ],
    ),
    TaskCategoryInfo(
      category: TaskCategory.security,
      title: 'Security & Privacy',
      description: 'Security updates and privacy protection tasks',
      icon: Icons.security,
      color: Color(0xFFFF9800), // Orange
      defaultTasks: [
        TaskTemplate(
          title: 'Run antivirus scan',
          description: 'Perform full system antivirus scan',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Update antivirus definitions',
          description: 'Ensure antivirus has latest threat definitions',
          defaultFrequency: TaskFrequency.daily,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Check firewall settings',
          description: 'Verify firewall is enabled and configured properly',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Review installed programs',
          description: 'Check for suspicious or unwanted software',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Update passwords',
          description: 'Change important passwords and check for breaches',
          defaultFrequency: TaskFrequency.quarterly,
          defaultPriority: TaskPriority.high,
        ),
        TaskTemplate(
          title: 'Backup important data',
          description: 'Create backup of important files and documents',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.high,
        ),
      ],
    ),
    TaskCategoryInfo(
      category: TaskCategory.performance,
      title: 'Performance Optimization',
      description: 'Tasks to maintain and improve system performance',
      icon: Icons.speed,
      color: Color(0xFF9C27B0), // Purple
      defaultTasks: [
        TaskTemplate(
          title: 'Monitor CPU and RAM usage',
          description: 'Check system resource usage and identify issues',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Check disk space',
          description: 'Monitor available storage space and clean if needed',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Optimize storage',
          description: 'Run disk cleanup and remove unnecessary files',
          defaultFrequency: TaskFrequency.weekly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Update device drivers',
          description: 'Check and update hardware drivers',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
        TaskTemplate(
          title: 'Test system performance',
          description: 'Run benchmarks to check overall system performance',
          defaultFrequency: TaskFrequency.quarterly,
          defaultPriority: TaskPriority.low,
        ),
        TaskTemplate(
          title: 'Check system temperature',
          description: 'Monitor CPU and GPU temperatures',
          defaultFrequency: TaskFrequency.monthly,
          defaultPriority: TaskPriority.medium,
        ),
      ],
    ),
  ];

  static TaskCategoryInfo getCategoryInfo(TaskCategory category) {
    return categories.firstWhere(
      (info) => info.category == category,
      orElse: () => categories.first,
    );
  }

  static List<TaskTemplate> getDefaultTasks(TaskCategory category) {
    return getCategoryInfo(category).defaultTasks;
  }

  static IconData getCategoryIcon(TaskCategory category) {
    return getCategoryInfo(category).icon;
  }

  static Color getCategoryColor(TaskCategory category) {
    return getCategoryInfo(category).color;
  }

  static String getCategoryTitle(TaskCategory category) {
    return getCategoryInfo(category).title;
  }

  static String getCategoryDescription(TaskCategory category) {
    return getCategoryInfo(category).description;
  }
}

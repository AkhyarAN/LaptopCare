
enum TaskCategory {
  physical('physical'),
  software('software'),
  security('security'),
  performance('performance');

  final String value;
  const TaskCategory(this.value);

  factory TaskCategory.fromString(String value) {
    return TaskCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskCategory.physical,
    );
  }
}

enum TaskFrequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  quarterly('quarterly');

  final String value;
  const TaskFrequency(this.value);

  String get label {
    switch (this) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.monthly:
        return 'Monthly';
      case TaskFrequency.quarterly:
        return 'Quarterly';
    }
  }

  factory TaskFrequency.fromString(String value) {
    return TaskFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskFrequency.monthly,
    );
  }
}

enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const TaskPriority(this.value);

  factory TaskPriority.fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class MaintenanceTask {
  final String taskId;
  final String userId;
  final String laptopId;
  final TaskCategory category;
  final String title;
  final String description;
  final TaskFrequency frequency;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceTask({
    required this.taskId,
    required this.userId,
    required this.laptopId,
    required this.category,
    required this.title,
    required this.description,
    required this.frequency,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      taskId: json['task_id'],
      userId: json['user_id'],
      laptopId: json['laptop_id'],
      category: TaskCategory.fromString(json['category']),
      title: json['title'],
      description: json['description'],
      frequency: TaskFrequency.fromString(json['frequency']),
      priority: TaskPriority.fromString(json['priority']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'laptop_id': laptopId,
      'category': category.value,
      'title': title,
      'description': description,
      'frequency': frequency.value,
      'priority': priority.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaintenanceTask copyWith({
    String? taskId,
    String? userId,
    String? laptopId,
    TaskCategory? category,
    String? title,
    String? description,
    TaskFrequency? frequency,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceTask(
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      laptopId: laptopId ?? this.laptopId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

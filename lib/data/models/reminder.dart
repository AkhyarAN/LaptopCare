import 'maintenance_task.dart';

enum ReminderStatus {
  pending('pending'),
  sent('sent'),
  completed('completed');

  final String value;
  const ReminderStatus(this.value);

  factory ReminderStatus.fromString(String value) {
    return ReminderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReminderStatus.pending,
    );
  }
}

class Reminder {
  final String reminderId;
  final String userId;
  final String laptopId;
  final String taskId;
  final DateTime scheduledDate;
  final TaskFrequency frequency;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.reminderId,
    required this.userId,
    required this.laptopId,
    required this.taskId,
    required this.scheduledDate,
    required this.frequency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      reminderId: json['reminder_id'],
      userId: json['user_id'],
      laptopId: json['laptop_id'],
      taskId: json['task_id'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      frequency: TaskFrequency.fromString(json['frequency']),
      status: ReminderStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminder_id': reminderId,
      'user_id': userId,
      'laptop_id': laptopId,
      'task_id': taskId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'frequency': frequency.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? reminderId,
    String? userId,
    String? laptopId,
    String? taskId,
    DateTime? scheduledDate,
    TaskFrequency? frequency,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      reminderId: reminderId ?? this.reminderId,
      userId: userId ?? this.userId,
      laptopId: laptopId ?? this.laptopId,
      taskId: taskId ?? this.taskId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

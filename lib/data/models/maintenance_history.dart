
class MaintenanceHistory {
  final String historyId;
  final String userId;
  final String laptopId;
  final String taskId;
  final DateTime completionDate;
  final String? notes;
  final DateTime createdAt;

  MaintenanceHistory({
    required this.historyId,
    required this.userId,
    required this.laptopId,
    required this.taskId,
    required this.completionDate,
    this.notes,
    required this.createdAt,
  });

  factory MaintenanceHistory.fromJson(Map<String, dynamic> json) {
    return MaintenanceHistory(
      historyId: json['history_id'],
      userId: json['user_id'],
      laptopId: json['laptop_id'],
      taskId: json['task_id'],
      completionDate: DateTime.parse(json['completion_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'history_id': historyId,
      'user_id': userId,
      'laptop_id': laptopId,
      'task_id': taskId,
      'completion_date': completionDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MaintenanceHistory copyWith({
    String? historyId,
    String? userId,
    String? laptopId,
    String? taskId,
    DateTime? completionDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return MaintenanceHistory(
      historyId: historyId ?? this.historyId,
      userId: userId ?? this.userId,
      laptopId: laptopId ?? this.laptopId,
      taskId: taskId ?? this.taskId,
      completionDate: completionDate ?? this.completionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

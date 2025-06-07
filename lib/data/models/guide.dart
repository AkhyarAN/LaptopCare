import 'maintenance_task.dart';

enum GuideDifficulty { easy, medium, advanced }

extension GuideDifficultyExtension on GuideDifficulty {
  String get name {
    switch (this) {
      case GuideDifficulty.easy:
        return 'Easy';
      case GuideDifficulty.medium:
        return 'Medium';
      case GuideDifficulty.advanced:
        return 'Advanced';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static GuideDifficulty fromString(String value) {
    return GuideDifficulty.values.firstWhere(
      (difficulty) => difficulty.value == value,
      orElse: () => GuideDifficulty.medium,
    );
  }
}

class Guide {
  final String guideId;
  final TaskCategory category;
  final String title;
  final String content;
  final GuideDifficulty difficulty;
  final int estimatedTime; // in minutes
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  Guide({
    required this.guideId,
    required this.category,
    required this.title,
    required this.content,
    required this.difficulty,
    required this.estimatedTime,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      guideId: json['guide_id'] ?? json['\$id'] ?? '',
      category: TaskCategory.fromString(json['category'] ?? 'physical'),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      difficulty:
          GuideDifficultyExtension.fromString(json['difficulty'] ?? 'medium'),
      estimatedTime:
          int.tryParse(json['estimated_time']?.toString() ?? '0') ?? 0,
      isPremium: json['is_premium'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guide_id': guideId,
      'category': category.value,
      'title': title,
      'content': content,
      'difficulty': difficulty.value,
      'estimated_time': estimatedTime,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Guide copyWith({
    String? guideId,
    TaskCategory? category,
    String? title,
    String? content,
    GuideDifficulty? difficulty,
    int? estimatedTime,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guide(
      guideId: guideId ?? this.guideId,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

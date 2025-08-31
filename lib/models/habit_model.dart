import 'package:flutter/material.dart';

enum HabitCategory {
  health,
  study,
  fitness,
  productivity,
  mentalHealth,
  others;

  String get displayName {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.study:
        return 'Study';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.mentalHealth:
        return 'Mental Health';
      case HabitCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.health:
        return Icons.favorite;
      case HabitCategory.study:
        return Icons.school;
      case HabitCategory.fitness:
        return Icons.fitness_center;
      case HabitCategory.productivity:
        return Icons.work;
      case HabitCategory.mentalHealth:
        return Icons.psychology;
      case HabitCategory.others:
        return Icons.more_horiz;
    }
  }
}

enum HabitFrequency {
  daily,
  weekly,
}

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime? startDate;
  final String? notes;
  final DateTime createdAt;
  final int currentStreak;
  final List<DateTime> completionHistory;
  final bool isActive;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.frequency,
    this.startDate,
    this.notes,
    required this.createdAt,
    this.currentStreak = 0,
    this.completionHistory = const [],
    this.isActive = true,
  });

  factory HabitModel.fromMap(Map<String, dynamic> map, String id) {
    return HabitModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: HabitCategory.values.firstWhere(
        (e) => e.toString() == 'HabitCategory.${map['category']}',
        orElse: () => HabitCategory.others,
      ),
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == 'HabitFrequency.${map['frequency']}',
        orElse: () => HabitFrequency.daily,
      ),
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : null,
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      currentStreak: map['currentStreak'] ?? 0,
      completionHistory: (map['completionHistory'] as List<dynamic>?)
          ?.map((date) => DateTime.parse(date))
          .toList() ?? [],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category.toString().split('.').last,
      'frequency': frequency.toString().split('.').last,
      'startDate': startDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'currentStreak': currentStreak,
      'completionHistory': completionHistory
          .map((date) => date.toIso8601String())
          .toList(),
      'isActive': isActive,
    };
  }

  HabitModel copyWith({
    String? title,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? startDate,
    String? notes,
    int? currentStreak,
    List<DateTime>? completionHistory,
    bool? isActive,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      completionHistory: completionHistory ?? this.completionHistory,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isCompletedForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return completionHistory.any((completionDate) {
      final normalizedCompletion = DateTime(
        completionDate.year,
        completionDate.month,
        completionDate.day,
      );
      return normalizedCompletion.isAtSameMomentAs(normalizedDate);
    });
  }

  bool canCompleteForDate(DateTime date) {
    final now = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    if (frequency == HabitFrequency.daily) {
      return normalizedDate.isBefore(normalizedNow) || 
             normalizedDate.isAtSameMomentAs(normalizedNow);
    } else {
      // Weekly frequency - can complete within the same week
      final startOfWeek = normalizedNow.subtract(Duration(days: normalizedNow.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return normalizedDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             normalizedDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }
  }


}

import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  
  List<HabitModel> _habits = [];
  List<HabitModel> _filteredHabits = [];
  HabitCategory? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  List<HabitModel> get habits => _habits;
  List<HabitModel> get filteredHabits => _filteredHabits;
  HabitCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get habits for a user
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _habitService.getUserHabits(userId);
  }

  // Get habits by category
  Stream<List<HabitModel>> getHabitsByCategory(
    String userId,
    HabitCategory category,
  ) {
    return _habitService.getHabitsByCategory(userId, category);
  }

  // Set habits
  void setHabits(List<HabitModel> habits) {
    _habits = habits;
    _applyFilter();
    notifyListeners();
  }

  // Filter habits by category
  void filterByCategory(HabitCategory? category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  // Apply current filter
  void _applyFilter() {
    if (_selectedCategory == null) {
      _filteredHabits = List.from(_habits);
    } else {
      _filteredHabits = _habits
          .where((habit) => habit.category == _selectedCategory)
          .toList();
    }
  }

  // Create a new habit
  Future<bool> createHabit({
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    DateTime? startDate,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final habit = await _habitService.createHabit(
        userId: userId,
        title: title,
        category: category,
        frequency: frequency,
        startDate: startDate,
        notes: notes,
      );

      // Don't add to local list since it will be loaded from Firestore stream
      // _habits.add(habit);
      // _applyFilter();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update habit
  Future<bool> updateHabit(HabitModel habit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _habitService.updateHabit(habit);
      
      // Don't manually update local list since it will be updated from Firestore stream
      // final index = _habits.indexWhere((h) => h.id == habit.id);
      // if (index != -1) {
      //   _habits[index] = habit;
      //   _applyFilter();
      // }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete habit
  Future<bool> deleteHabit(String userId, String habitId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _habitService.deleteHabit(userId, habitId);
      
      // Don't manually remove from local list since it will be updated from Firestore stream
      // _habits.removeWhere((habit) => habit.id == habitId);
      // _applyFilter();

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark habit as completed
  Future<bool> markHabitCompleted(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    try {
      await _habitService.markHabitCompleted(userId, habitId, date);
      
      // Don't manually update local habit data since it will be updated from Firestore stream
      // final index = _habits.indexWhere((habit) => habit.id == habitId);
      // if (index != -1) {
      //   final habit = _habits[index];
      //   final newCompletionHistory = [...habit.completionHistory, date];
      //   final newStreak = _calculateStreak(newCompletionHistory, habit.frequency);
      //   
      //   _habits[index] = habit.copyWith(
      //     completionHistory: newCompletionHistory,
      //       currentStreak: newStreak,
      //     );
      //   _applyFilter();
      //   notifyListeners();
      // }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark habit as not completed
  Future<bool> markHabitNotCompleted(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    try {
      await _habitService.markHabitNotCompleted(userId, habitId, date);
      
      // Don't manually update local habit data since it will be updated from Firestore stream
      // final index = _habits.indexWhere((habit) => habit.id == habitId);
      // if (index != -1) {
      //   final habit = _habits[index];
      //   final newCompletionHistory = habit.completionHistory
      //       .where((completionDate) {
      //     final normalizedCompletion = DateTime(
      //       completionDate.year,
      //       completionDate.month,
      //       completionDate.day,
      //     );
      //     final normalizedDate = DateTime(date.year, date.month, date.day);
      //     return !normalizedCompletion.isAtSameMomentAs(normalizedDate);
      //   }).toList();
      //   
      //   final newStreak = _calculateStreak(newCompletionHistory, habit.frequency);
      //   
      //   _habits[index] = habit.copyWith(
      //     completionHistory: newCompletionHistory,
      //       currentStreak: newStreak,
      //     );
      //   _applyFilter();
      //   notifyListeners();
      // }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Calculate streak (simplified version for local updates)
  int _calculateStreak(List<DateTime> completionHistory, HabitFrequency frequency) {
    if (completionHistory.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    
    if (frequency == HabitFrequency.daily) {
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = DateTime(
          sortedDates[i].year,
          sortedDates[i].month,
          sortedDates[i].day,
        );
        
        if (i == 0) {
          if (currentDate.difference(completionDate).inDays <= 1) {
            streak = 1;
            currentDate = completionDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else {
          if (currentDate.difference(completionDate).inDays == 1) {
            streak++;
            currentDate = completionDate;
          } else {
            break;
          }
        }
      }
    }
    
    return streak;
  }

  // Get habit statistics
  Map<String, dynamic> getHabitStats(HabitModel habit) {
    return _habitService.getHabitStats(habit);
  }

  // Get today's habits
  List<HabitModel> getTodayHabits() {
    final today = DateTime.now();
    return _habits.where((habit) {
      return habit.isActive && habit.canCompleteForDate(today);
    }).toList();
  }

  // Get habits for a specific date
  List<HabitModel> getHabitsForDate(DateTime date) {
    return _habits.where((habit) {
      return habit.isActive && habit.canCompleteForDate(date);
    }).toList();
  }

  // Get habits by frequency
  List<HabitModel> getHabitsByFrequency(HabitFrequency frequency) {
    return _habits.where((habit) => habit.frequency == frequency).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh habits
  void refreshHabits() {
    _applyFilter();
    notifyListeners();
  }
}

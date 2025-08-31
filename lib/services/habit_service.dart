import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new habit
  Future<HabitModel> createHabit({
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    DateTime? startDate,
    String? notes,
  }) async {
    try {
      final String habitId = _uuid.v4();
      final HabitModel habit = HabitModel(
        id: habitId,
        userId: userId,
        title: title,
        category: category,
        frequency: frequency,
        startDate: startDate,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .set(habit.toMap());

      return habit;
    } catch (e) {
      throw 'Error creating habit: $e';
    }
  }

  // Get all habits for a user
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get habits by category
  Stream<List<HabitModel>> getHabitsByCategory(
    String userId,
    HabitCategory category,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update habit
  Future<void> updateHabit(HabitModel habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id)
          .update(habit.toMap());
    } catch (e) {
      throw 'Error updating habit: $e';
    }
  }

  // Delete habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      throw 'Error deleting habit: $e';
    }
  }

  // Mark habit as completed for a specific date
  Future<void> markHabitCompleted(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    try {
      final DocumentReference habitRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId);

      final DocumentSnapshot habitDoc = await habitRef.get();
      if (!habitDoc.exists) {
        throw 'Habit not found';
      }

      final HabitModel habit = HabitModel.fromMap(
        habitDoc.data() as Map<String, dynamic>,
        habitId,
      );

      // Check if habit can be completed for this date
      if (!habit.canCompleteForDate(date)) {
        throw 'Cannot complete habit for this date';
      }

      // Check if already completed
      if (habit.isCompletedForDate(date)) {
        throw 'Habit already completed for this date';
      }

      // Add completion date
      final List<DateTime> newCompletionHistory = [...habit.completionHistory, date];
      
      // Calculate new streak
      final int newStreak = _calculateStreak(newCompletionHistory, habit.frequency);

      // Update habit
      await habitRef.update({
        'completionHistory': newCompletionHistory
            .map((date) => date.toIso8601String())
            .toList(),
        'currentStreak': newStreak,
      });
    } catch (e) {
      throw 'Error marking habit completed: $e';
    }
  }

  // Mark habit as not completed for a specific date
  Future<void> markHabitNotCompleted(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    try {
      final DocumentReference habitRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId);

      final DocumentSnapshot habitDoc = await habitRef.get();
      if (!habitDoc.exists) {
        throw 'Habit not found';
      }

      final HabitModel habit = HabitModel.fromMap(
        habitDoc.data() as Map<String, dynamic>,
        habitId,
      );

      // Remove completion date
      final List<DateTime> newCompletionHistory = habit.completionHistory
          .where((completionDate) {
        final normalizedCompletion = DateTime(
          completionDate.year,
          completionDate.month,
          completionDate.day,
        );
        final normalizedDate = DateTime(date.year, date.month, date.day);
        return !normalizedCompletion.isAtSameMomentAs(normalizedDate);
      }).toList();

      // Calculate new streak
      final int newStreak = _calculateStreak(newCompletionHistory, habit.frequency);

      // Update habit
      await habitRef.update({
        'completionHistory': newCompletionHistory
            .map((date) => date.toIso8601String())
            .toList(),
        'currentStreak': newStreak,
      });
    } catch (e) {
      throw 'Error marking habit not completed: $e';
    }
  }

  // Calculate streak based on completion history
  int _calculateStreak(List<DateTime> completionHistory, HabitFrequency frequency) {
    if (completionHistory.isEmpty) return 0;

    // Sort completion dates in descending order
    final sortedDates = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    
    if (frequency == HabitFrequency.daily) {
      // Calculate daily streak
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = DateTime(
          sortedDates[i].year,
          sortedDates[i].month,
          sortedDates[i].day,
        );
        
        if (i == 0) {
          // Check if the first completion is today or yesterday
          if (currentDate.difference(completionDate).inDays <= 1) {
            streak = 1;
            currentDate = completionDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else {
          // Check if consecutive
          if (currentDate.difference(completionDate).inDays == 1) {
            streak++;
            currentDate = completionDate;
          } else {
            break;
          }
        }
      }
    } else {
      // Calculate weekly streak
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      // Check if current week is completed
      bool currentWeekCompleted = false;
      for (final completionDate in sortedDates) {
        if (completionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            completionDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          currentWeekCompleted = true;
          break;
        }
      }
      
      if (currentWeekCompleted) {
        streak = 1;
        DateTime currentWeekStart = startOfWeek.subtract(const Duration(days: 7));
        
        for (int i = 0; i < sortedDates.length; i++) {
          final completionDate = sortedDates[i];
          final weekStart = DateTime(
            completionDate.year,
            completionDate.month,
            completionDate.day,
          ).subtract(Duration(days: completionDate.weekday - 1));
          
          if (currentWeekStart.difference(weekStart).inDays == 7) {
            streak++;
            currentWeekStart = weekStart.subtract(const Duration(days: 7));
          } else if (currentWeekStart.difference(weekStart).inDays > 7) {
            break;
          }
        }
      }
    }
    
    return streak;
  }

  // Get completion statistics for a habit
  Map<String, dynamic> getHabitStats(HabitModel habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Last 7 days completion
    final last7Days = List.generate(7, (index) {
      return today.subtract(Duration(days: index));
    }).reversed.toList();
    
    final last7DaysCompletion = last7Days.map((date) {
      return {
        'date': date,
        'completed': habit.isCompletedForDate(date),
      };
    }).toList();
    
          // Current week completion
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final weekDays = List.generate(7, (index) {
        return startOfWeek.add(Duration(days: index));
      });
    
    final weekCompletion = weekDays.map((date) {
      return {
        'date': date,
        'completed': habit.isCompletedForDate(date),
      };
    }).toList();
    
    return {
      'last7Days': last7DaysCompletion,
      'currentWeek': weekCompletion,
      'totalCompletions': habit.completionHistory.length,
      'currentStreak': habit.currentStreak,
    };
  }
}

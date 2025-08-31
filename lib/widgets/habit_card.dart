import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import 'progress_chart.dart';

class HabitCard extends StatefulWidget {
  final HabitModel habit;
  final VoidCallback? onTap;
  final bool showChart;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
    this.showChart = false,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: const Color(0xFF6750A4),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap != null) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        widget.onTap!();
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 4 + (_isExpanded ? 2 : 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    isDark ? const Color(0xFF3A3A3A) : Colors.grey[50]!,
                  ],
                ),
                border: Border.all(
                  color: _colorAnimation.value ?? Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: _onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with category and streak
                      Row(
                        children: [
                          // Category Icon with animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(widget.habit.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getCategoryColor(widget.habit.category).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.habit.category.icon,
                              color: _getCategoryColor(widget.habit.category),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Category Label
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(widget.habit.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.habit.category.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getCategoryColor(widget.habit.category),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          
                          // Streak with flame animation
                          if (widget.habit.currentStreak > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 1500),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.habit.currentStreak}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Habit Title
                      Text(
                        widget.habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Frequency and Date
                      Row(
                        children: [
                          Icon(
                            widget.habit.frequency == HabitFrequency.daily
                                ? Icons.calendar_today
                                : Icons.calendar_view_week,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.habit.frequency == HabitFrequency.daily
                                ? 'Daily'
                                : 'Weekly',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.habit.startDate != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Started ${DateFormat('MMM dd').format(widget.habit.startDate!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (widget.habit.notes != null && widget.habit.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100]?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.habit.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Completion Section
                      _buildCompletionSection(theme, isDark),
                      
                      // Expandable Chart Section
                      if (widget.showChart) ...[
                        const SizedBox(height: 16),
                        _buildExpandableChart(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionSection(ThemeData theme, bool isDark) {
    final today = DateTime.now();
    final isCompleted = widget.habit.isCompletedForDate(today);
    final canComplete = widget.habit.canCompleteForDate(today);
    
    return Column(
      children: [
        // Progress Bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widget.habit.completionHistory.length / 30, // Last 30 days
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Completion Button
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [Colors.green, Colors.green.shade600]
                        : canComplete
                            ? [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]
                            : [Colors.grey, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted ? Colors.green : theme.colorScheme.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canComplete ? _toggleHabitCompletion : null,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              isCompleted ? Icons.check_circle : Icons.circle_outlined,
                              key: ValueKey(isCompleted),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted ? 'Completed!' : 'Mark Complete',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Expand Button
            if (widget.showChart)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: _toggleExpanded,
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableChart(ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isExpanded
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ProgressChart(
                  habit: widget.habit,
                  title: 'Progress Overview',
                  showWeekView: true,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _toggleHabitCompletion() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final today = DateTime.now();
      final isCompleted = widget.habit.isCompletedForDate(today);
      
      try {
        if (isCompleted) {
          await habitProvider.markHabitNotCompleted(
            authProvider.user!.uid,
            widget.habit.id,
            today,
          );
        } else {
          await habitProvider.markHabitCompleted(
            authProvider.user!.uid,
            widget.habit.id,
            today,
          );
          
          // Add haptic feedback
          HapticFeedback.lightImpact();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Colors.red;
      case HabitCategory.study:
        return Colors.blue;
      case HabitCategory.fitness:
        return Colors.green;
      case HabitCategory.productivity:
        return Colors.orange;
      case HabitCategory.mentalHealth:
        return Colors.purple;
      case HabitCategory.others:
        return Colors.grey;
    }
  }
}

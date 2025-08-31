import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';

class ProgressChart extends StatefulWidget {
  final HabitModel habit;
  final String title;
  final bool showWeekView;

  const ProgressChart({
    super.key,
    required this.habit,
    required this.title,
    this.showWeekView = true,
  });

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isWeekView = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _isWeekView = widget.showWeekView;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _isWeekView = !_isWeekView;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _prepareChartData();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (chartData.isEmpty) {
      return _buildEmptyState(theme);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      isDark ? const Color(0xFF3A3A3A) : Colors.grey[50]!,
                    ],
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with toggle
                      Row(
                        children: [
                          Icon(
                            _isWeekView ? Icons.calendar_view_week : Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          // View Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToggleButton(
                                  'Week',
                                  true,
                                  theme,
                                  isDark,
                                ),
                                _buildToggleButton(
                                  '7 Days',
                                  false,
                                  theme,
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Chart
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 1.0,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(12),
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final date = chartData[group.x.toInt()]['date'] as DateTime;
                                  final completed = chartData[group.x.toInt()]['completed'] as bool;
                                  final formattedDate = DateFormat('MMM d').format(date);
                                  
                                  return BarTooltipItem(
                                    '$formattedDate\n',
                                    TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: completed ? '✅ Completed' : '❌ Not completed',
                                        style: TextStyle(
                                          color: completed 
                                              ? Colors.green[600] 
                                              : Colors.red[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                                      final date = chartData[value.toInt()]['date'] as DateTime;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Text(
                                          _isWeekView 
                                              ? DateFormat('E').format(date)
                                              : DateFormat('MMM d').format(date),
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: chartData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final completed = data['completed'] as bool;
                              
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: completed ? 1.0 : 0.0,
                                    color: completed 
                                        ? theme.colorScheme.primary
                                        : Colors.grey[300],
                                    width: 24,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 1.0,
                                      color: isDark 
                                          ? Colors.grey[800] 
                                          : Colors.grey[100],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            gridData: FlGridData(
                              show: false,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Legend and Stats
                      _buildLegendAndStats(theme, isDark, chartData),
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

  Widget _buildToggleButton(String text, bool isSelected, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (isSelected != _isWeekView) {
          _toggleView();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : isDark ? Colors.white70 : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendAndStats(ThemeData theme, bool isDark, List<Map<String, dynamic>> chartData) {
    final completedCount = chartData.where((data) => data['completed'] as bool).length;
    final totalCount = chartData.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;
    
    return Row(
      children: [
        // Legend
        Expanded(
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Completed',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Not Completed',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            '$completionRate%',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No data available yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your first habit to see progress here!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _prepareChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_isWeekView) {
      // Show current week
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final weekDays = List.generate(7, (index) {
        return startOfWeek.add(Duration(days: index));
      });
      
      return weekDays.map((date) {
        return {
          'date': date,
          'completed': widget.habit.isCompletedForDate(date),
        };
      }).toList();
    } else {
      // Show last 7 days
      final last7Days = List.generate(7, (index) {
        return today.subtract(Duration(days: 6 - index));
      });
      
      return last7Days.map((date) {
        return {
          'date': date,
          'completed': widget.habit.isCompletedForDate(date),
        };
      }).toList();
    }
  }
}

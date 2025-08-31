import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  HabitCategory _selectedCategory = HabitCategory.health;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  DateTime? _selectedStartDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _createHabit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);

        if (authProvider.user != null) {
          final success = await habitProvider.createHabit(
            userId: authProvider.user!.uid,
            title: _titleController.text.trim(),
            category: _selectedCategory,
            frequency: _selectedFrequency,
            startDate: _selectedStartDate,
            notes: _notesController.text.trim().isEmpty 
                ? null 
                : _notesController.text.trim(),
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Habit created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(habitProvider.error ?? 'Failed to create habit'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Habit'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.add_task,
                  size: 60,
                  color: Color(0xFF6750A4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create a New Habit',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF6750A4),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start building positive habits today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Habit Title
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Habit Title *',
                  hintText: 'e.g., Drink 8 glasses of water',
                  prefixIcon: Icons.edit,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a habit title';
                    }
                    if (value.length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Selection
                DropdownButtonFormField<HabitCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    hintText: 'Select a category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[50]
                        : Colors.grey[900],
                  ),
                  items: HabitCategory.values.map((HabitCategory category) {
                    return DropdownMenuItem<HabitCategory>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            category.icon,
                            color: _getCategoryColor(category),
                          ),
                          const SizedBox(width: 12),
                          Text(category.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (HabitCategory? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Frequency Selection
                DropdownButtonFormField<HabitFrequency>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency *',
                    hintText: 'Select frequency',
                    prefixIcon: const Icon(Icons.schedule_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[50]
                        : Colors.grey[900],
                  ),
                  items: HabitFrequency.values.map((HabitFrequency frequency) {
                    return DropdownMenuItem<HabitFrequency>(
                      value: frequency,
                      child: Text(
                        frequency == HabitFrequency.daily ? 'Daily' : 'Weekly',
                      ),
                    );
                  }).toList(),
                  onChanged: (HabitFrequency? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFrequency = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select frequency';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Start Date
                InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      hintText: _selectedStartDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedStartDate!)
                          : 'Select start date (optional)',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[50]
                          : Colors.grey[900],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _selectedStartDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedStartDate!)
                            : 'Select start date (optional)',
                        style: TextStyle(
                          color: _selectedStartDate != null 
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes
                CustomTextField(
                  controller: _notesController,
                  labelText: 'Notes',
                  hintText: 'Add any additional details (optional)',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 32),

                // Create Button
                CustomButton(
                  onPressed: _isLoading ? null : _createHabit,
                  text: _isLoading ? 'Creating Habit...' : 'Create Habit',
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

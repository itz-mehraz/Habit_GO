import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/quote_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'package:flutter/services.dart';


import '../../widgets/habit_card.dart';
import '../../widgets/quote_card.dart';

import '../habits/create_habit_screen.dart';
import '../habits/habits_screen.dart';
import '../quotes/favorites_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToFavoriteQuotes();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Load habits
      habitProvider.getUserHabits(authProvider.user!.uid).listen((habits) {
        habitProvider.setHabits(habits);
      });

      // Load favorite quotes
      quoteProvider.getFavoriteQuotes(authProvider.user!.uid).listen((favorites) {
        quoteProvider.setFavoriteQuotes(favorites);
      });
    }
  }

  void _listenToFavoriteQuotes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    if (authProvider.user != null) {
      quoteProvider.getFavoriteQuotes(authProvider.user!.uid).listen((favorites) {
        quoteProvider.setFavoriteQuotes(favorites);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildFuturisticHeader(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
          await quoteProvider.refreshQuotes();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 100), // More top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Extra space to ensure Today's Progress is never hidden
              const SizedBox(height: 8),
              _buildTodayProgress(),
              const SizedBox(height: 16),
              _buildQuotesSection(),
              const SizedBox(height: 16),
              _buildTodayHabits(),
              const SizedBox(height: 16),
              _buildHabitSuggestions(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateHabitScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Habit'),
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFuturisticHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);
    ImageProvider? avatarImage;
    if (user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty) {
      avatarImage = CachedNetworkImageProvider(user.profilePictureUrl!);
    }
    final streak = Random().nextInt(10) + 1;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6750A4), Color(0xFF3A2D6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6750A4),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 24, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user != null ? '$greeting, ${user.displayName}!' : greeting,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          'Streak: $streak days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22),
                tooltip: 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final greeting = _getGreeting(now.hour);
        final formattedDate = DateFormat('EEEE, MMMM d').format(now);

        ImageProvider? avatarImage;
        if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
          avatarImage = CachedNetworkImageProvider(user.profilePictureUrl!);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF6750A4).withOpacity(0.1),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(
                              Icons.person,
                              size: 30,
                              color: const Color(0xFF6750A4),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, ${user.displayName}!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayProgress() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final todayHabits = habitProvider.getTodayHabits();
        final completedHabits = todayHabits.where((habit) => 
          habit.isCompletedForDate(DateTime.now())
        ).length;
        final totalHabits = todayHabits.length;
        final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: progress),
          builder: (context, value, child) {
            return Card(
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
                      const Color(0xFF6750A4).withOpacity(0.1),
                      const Color(0xFF6750A4).withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF6750A4).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6750A4).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF6750A4).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.trending_up,
                                        color: const Color(0xFF6750A4),
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Today\'s Progress',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF6750A4),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6750A4),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6750A4).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '$completedHabits/$totalHabits',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Animated Progress Bar
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6750A4),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6750A4).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progress Text with Animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: Text(
                              totalHabits > 0 
                                  ? 'Keep going! You\'re doing great!'
                                  : 'No habits for today. Create your first habit!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuotesSection() {
    return Consumer<QuoteProvider>(
      builder: (context, quoteProvider, child) {
        if (quoteProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final quotes = quoteProvider.quotes;
        final favoriteIds = quoteProvider.favoriteQuotes.map((q) => q.id).toSet();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6750A4), Color(0xFF3A2D6D)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Daily Motivation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (quotes.isNotEmpty)
              SizedBox(
                height: 150,
                child: PageView.builder(
                  itemCount: quotes.length,
                  controller: PageController(viewportFraction: 0.92),
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    final isFavorite = favoriteIds.contains(quote.id);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: theme.colorScheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '"${quote.text}"',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white : Colors.black87,
                                      height: 1.4,
                                    ),
                                    // Show full quote text
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '— ${quote.author}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.copy, size: 20, color: theme.colorScheme.primary),
                                      tooltip: 'Copy',
                                      onPressed: () async {
                                        await Clipboard.setData(ClipboardData(text: '"${quote.text}"\n— ${quote.author}'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Quote copied to clipboard!')),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 22,
                                        color: isFavorite ? Colors.red : theme.colorScheme.primary,
                                      ),
                                      tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
                                      onPressed: userId == null
                                          ? null
                                          : () async {
                                              if (isFavorite) {
                                                await quoteProvider.unfavoriteQuote(userId, quote.id);
                                              } else {
                                                await quoteProvider.favoriteQuote(userId, quote);
                                              }
                                            },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
                                      tooltip: 'Share',
                                      onPressed: () {
                                        final shareText = '"${quote.text}"\n— ${quote.author}';
                                        Share.share(shareText);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No motivational quote available.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTodayHabits() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final todayHabits = habitProvider.getTodayHabits();
        
        if (todayHabits.isEmpty) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, opacity, child) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              
              return Opacity(
                opacity: opacity,
                child: Card(
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
                          Colors.orange.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Today\'s Habits',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits scheduled for today.\nCreate your first habit to get started!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateHabitScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Habit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with Animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, opacity, child) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                
                return Opacity(
                  opacity: opacity,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6750A4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6750A4).withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.task_alt,
                          color: const Color(0xFF6750A4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Today\'s Habits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF6750A4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6750A4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${todayHabits.length}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Animated Habit Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: todayHabits.length,
              itemBuilder: (context, index) {
                final habit = todayHabits[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - opacity)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: HabitCard(
                            habit: habit,
                            showChart: true,
                            onTap: () {
                              // Navigate to habit details or edit
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitSuggestions() {
    final suggestions = [
      'Drink 8 glasses of water',
      'Read for 15 minutes',
      'Take a 10-minute walk',
      'Write a gratitude note',
      'Meditate for 5 minutes',
    ];
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Habit Suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.take(3).map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: theme.textTheme.bodyMedium)),
                ],
              ),
            )),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More suggestions coming soon!')),
                );
              },
              icon: const Icon(Icons.more_horiz),
              label: const Text('See More'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add_task,
                title: 'Create Habit',
                subtitle: 'Add a new habit',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateHabitScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.list_alt,
                title: 'View All',
                subtitle: 'See all habits',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HabitsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(0xFF6750A4),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}



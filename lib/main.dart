import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/quote_provider.dart';
import 'services/theme_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  runApp(const HabitGoApp());
}

class HabitGoApp extends StatelessWidget {
  const HabitGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'HabitGo',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait for AuthProvider to initialize
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait for AuthProvider to finish initializing
      while (authProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (mounted) {
        // Debug log the authentication state
        authProvider.logAuthState();
        
        if (authProvider.isAuthenticated && authProvider.user != null) {
          debugPrint('User is authenticated, navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (authProvider.isFirebaseAuthenticated) {
          debugPrint('User is Firebase authenticated, waiting for user data...');
          // User is authenticated with Firebase but user data might not be loaded yet
          // Wait a bit more for user data to load
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && authProvider.user != null) {
            debugPrint('User data loaded, navigating to HomeScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            debugPrint('User data not loaded, navigating to LoginScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          debugPrint('User not authenticated, navigating to LoginScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6750A4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const Icon(
              Icons.track_changes,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            
            // App Name
            const Text(
              'HabitGo',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tagline
            const Text(
              'Track your habits, achieve your goals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

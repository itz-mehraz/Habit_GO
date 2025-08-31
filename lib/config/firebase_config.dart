import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    try {
      // Only initialize if no Firebase app is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized successfully');
      } else {
        debugPrint('Firebase already initialized');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      // You can show a user-friendly error message here
      rethrow;
    }
  }
}

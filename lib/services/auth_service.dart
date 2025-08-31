import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser {
    final user = _auth.currentUser;
    debugPrint('AuthService: Current Firebase user: ${user?.email ?? 'null'} (UID: ${user?.uid ?? 'null'})');
    return user;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    debugPrint('AuthService: Setting up auth state changes listener');
    return _auth.authStateChanges();
  }

  // Register user
  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
  }) async {
    try {
      debugPrint('AuthService: Attempting registration for $email');
      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        debugPrint('AuthService: Firebase registration successful for UID: ${user.uid}');
        // Create user model
        final UserModel userModel = UserModel(
          uid: user.uid,
          displayName: displayName,
          email: email,
          gender: gender,
          dateOfBirth: dateOfBirth,
          height: height,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        debugPrint('AuthService: User data saved to Firestore');

        // Save user session locally
        await _saveUserSession(user.uid);
        debugPrint('AuthService: User session saved locally');

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase auth exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthService: General error during registration: $e');
      throw 'An error occurred during registration: $e';
    }
  }

  // Login user
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting login for $email');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        debugPrint('AuthService: Firebase login successful for UID: ${user.uid}');
        // Save user session locally
        await _saveUserSession(user.uid);
        debugPrint('AuthService: User session saved locally');

        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          debugPrint('AuthService: User data found in Firestore');
          return UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            user.uid,
          );
        } else {
          debugPrint('AuthService: User data not found in Firestore');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase auth exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthService: General error during login: $e');
      throw 'An error occurred during login: $e';
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      debugPrint('AuthService: Logging out user');
      await _auth.signOut();
      debugPrint('AuthService: Firebase signout successful');
      await _clearUserSession();
      debugPrint('AuthService: Logout complete');
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
      throw 'An error occurred during logout: $e';
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint('AuthService: Fetching user data for UID: $uid');
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        debugPrint('AuthService: User data found for UID: $uid');
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          uid,
        );
      } else {
        debugPrint('AuthService: User data not found for UID: $uid');
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: Error fetching user data: $e');
      throw 'Error fetching user data: $e';
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      debugPrint('AuthService: Updating user data for UID: $uid');
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        ...data,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      debugPrint('AuthService: User data updated successfully');
    } catch (e) {
      debugPrint('AuthService: Error updating user data: $e');
      throw 'Error updating user data: $e';
    }
  }

  // Save user session locally
  Future<void> _saveUserSession(String uid) async {
    debugPrint('AuthService: Saving user session for UID: $uid');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    await prefs.setBool('is_logged_in', true);
    debugPrint('AuthService: User session saved locally');
  }

  // Clear user session locally
  Future<void> _clearUserSession() async {
    debugPrint('AuthService: Clearing user session');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.setBool('is_logged_in', false);
    debugPrint('AuthService: User session cleared locally');
  }

  // Check if user is logged in locally
  Future<bool> isLoggedInLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    debugPrint('AuthService: Local login check: $isLoggedIn');
    return isLoggedIn;
  }

  // Get stored user UID
  Future<String?> getStoredUserUid() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_uid');
    debugPrint('AuthService: Stored UID: $uid');
    return uid;
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('AuthService: Handling Firebase auth exception: ${e.code} - ${e.message}');
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

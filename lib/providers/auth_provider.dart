import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Check if user is authenticated with Firebase
  bool get isFirebaseAuthenticated => _authService.currentUser != null;

  // Get current Firebase user
  User? get currentFirebaseUser => _authService.currentUser;

  // Check if user is authenticated (either locally or with Firebase)
  bool get isAuthenticated => _isAuthenticated || isFirebaseAuthenticated;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    debugPrint('Initializing authentication...');
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes first
      debugPrint('Setting up Firebase auth state listener...');
      _authService.authStateChanges.listen((User? firebaseUser) {
        if (firebaseUser != null) {
          debugPrint('Firebase auth state changed: user logged in - ${firebaseUser.email}');
          _loadUserData(firebaseUser.uid);
        } else {
          debugPrint('Firebase auth state changed: user logged out');
          _clearUser();
        }
      });
      debugPrint('Firebase auth state listener set up successfully');

      // Check if user is logged in locally
      final isLoggedIn = await _authService.isLoggedInLocally();
      debugPrint('Local login check: $isLoggedIn');
      
      if (isLoggedIn) {
        final uid = await _authService.getStoredUserUid();
        debugPrint('Stored UID: $uid');
        if (uid != null) {
          final userData = await _authService.getUserData(uid);
          if (userData != null) {
            debugPrint('Local user data loaded: ${userData.displayName}');
            _user = userData;
            _isAuthenticated = true;
          }
        }
      }
      debugPrint('Local login check completed');
    } catch (e) {
      debugPrint('Error initializing authentication: $e');
      _error = 'Error initializing authentication: $e';
    } finally {
      _isLoading = false;
      debugPrint('Authentication initialization complete');
      notifyListeners();
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      debugPrint('Loading user data for UID: $uid');
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        debugPrint('User data loaded successfully: ${userData.displayName}');
        _user = userData;
        _isAuthenticated = true;
        _error = null;
      } else {
        debugPrint('User data not found for UID: $uid');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _error = 'Error loading user data: $e';
    }
    notifyListeners();
  }

  // Clear user data
  void _clearUser() {
    debugPrint('Clearing user data');
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  // Register user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting to register user: $email');
      final userData = await _authService.registerUser(
        email: email,
        password: password,
        displayName: displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
      );

      if (userData != null) {
        debugPrint('Registration successful for user: ${userData.displayName}');
        _user = userData;
        _isAuthenticated = true;
        _error = null;
        logAuthState(); // Debug log the state
        return true;
      } else {
        debugPrint('Registration failed: userData is null');
        _error = 'Registration failed';
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting to login user: $email');
      final userData = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (userData != null) {
        debugPrint('Login successful for user: ${userData.displayName}');
        _user = userData;
        _isAuthenticated = true;
        _error = null;
        logAuthState(); // Debug log the state
        return true;
      } else {
        debugPrint('Login failed: userData is null');
        _error = 'Login failed';
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logoutUser();
      _clearUser();
    } catch (e) {
      _error = 'Error during logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    String? profilePictureUrl,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (gender != null) updateData['gender'] = gender;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (height != null) updateData['height'] = height;
      if (profilePictureUrl != null) updateData['profilePictureUrl'] = profilePictureUrl;

      await _authService.updateUserData(_user!.uid, updateData);

      // Update local user data
      _user = _user!.copyWith(
        displayName: displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        profilePictureUrl: profilePictureUrl,
      );

      _error = null;
      return true;
    } catch (e) {
      _error = 'Error updating profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
    }
  }

  // Debug method to log authentication state
  void logAuthState() {
    debugPrint('=== Auth State Debug ===');
    debugPrint('isLoading: $_isLoading');
    debugPrint('isAuthenticated: $_isAuthenticated');
    debugPrint('isFirebaseAuthenticated: $isFirebaseAuthenticated');
    debugPrint('user: ${_user?.displayName ?? 'null'}');
    debugPrint('currentFirebaseUser: ${currentFirebaseUser?.email ?? 'null'}');
    debugPrint('error: $_error');
    debugPrint('=======================');
  }
}

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check login status - UPDATED
  Future<bool> checkLoginStatus() async {
    _isLoading = true;
    _error = null;

    try {
      bool isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUserData();
      }
      _isLoading = false;
      return isLoggedIn;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      return false;
    }
  }

  // Sign up with email and password - UPDATED
  Future<bool> signUp(String email, String password, String name, String? phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('AuthProvider: Starting sign up process');

    try {
      UserModel? user = await _authService.signUpWithEmail(email, password, name, phone);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        print('AuthProvider: Sign up successful');
        return true;
      }
      _error = "Failed to create account";
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Sign up failed - user is null');
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Firebase error during sign up: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _error = "An unexpected error occurred";
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Unexpected error during sign up: $e');
      return false;
    }
  }

  // Sign in with email and password - UPDATED
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel? user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = "Invalid email or password";
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "An unexpected error occurred";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out - UPDATED
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to sign out";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password - UPDATED
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "Failed to send reset email";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile - UPDATED
  Future<void> updateProfile(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(user);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to update profile";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'An error occurred: $errorCode';
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
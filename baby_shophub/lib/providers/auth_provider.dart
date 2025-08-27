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
  bool get isAdmin => _currentUser?.isAdministrator ?? false;

  // ---- Helpers ----
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  // ---- Auth Methods ----

  Future<bool> checkLoginStatus() async {
    _setLoading(true);
    _setError(null);

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUserData();
      }
      return isLoggedIn;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String? phone, {
    String role = 'user',
  }) async {
    _setLoading(true);
    _setError(null);

    debugPrint('AuthProvider: Starting sign up process');

    try {
      final user = await _authService.signUpWithEmail(
        email,
        password,
        name,
        phone,
      );

      if (user != null) {
        _currentUser = user;
        debugPrint('AuthProvider: Sign up successful');
        return true;
      }

      _setError("Failed to create account");
      debugPrint('AuthProvider: Sign up failed - user is null');
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      debugPrint(
        'AuthProvider: Firebase error during sign up: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      _setError("An unexpected error occurred");
      debugPrint('AuthProvider: Unexpected error during sign up: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        if (user.isAdministrator) {
          debugPrint('Admin user logged in');
        }
        return true;
      }

      _setError("Invalid email or password");
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError("An unexpected error occurred");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _setError("Failed to sign out");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError("Failed to send reset email");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(UserModel user) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.updateUserProfile(user);
      _currentUser = user;
    } catch (e) {
      _setError("Failed to update profile");
    } finally {
      _setLoading(false);
    }
  }

  // ---- Error Helper ----
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

  void clearError() => _setError(null);
}

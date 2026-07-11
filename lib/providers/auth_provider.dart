import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

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

        await _notificationService.initialize();
        await _notificationService.saveTokenToFirestore(_currentUser!.id);
        await _notificationService.reconcileCurrentToken(_currentUser!.id);
        _notificationService.listenForTokenChanges(_currentUser!.id);
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

    try {
      final user = await _authService.signUpWithEmail(
        email,
        password,
        name,
        phone,
      );

      if (user != null) {
        _currentUser = user;

        await _notificationService.initialize();
        await _notificationService.saveTokenToFirestore(user.id);
        await _notificationService.reconcileCurrentToken(user.id);
        _notificationService.listenForTokenChanges(user.id);

        return true;
      }

      _setError("Failed to create account");
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

  Future<bool> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();

        await _notificationService.initialize();
        await _notificationService.saveTokenToFirestore(user.id);
        await _notificationService.reconcileCurrentToken(user.id);
        _notificationService.listenForTokenChanges(user.id);

        if (user.isAdministrator) {
          await _notificationService.subscribeAdminToOrders();
        } else {
          await _notificationService.subscribeToOrderUpdates(user.id);
        }

        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.initializeNotifications(user.id);

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
      if (_currentUser != null) {
        if (_currentUser!.isAdministrator) {
          await _notificationService.unsubscribeAdminFromOrders();
        } else {
          await _notificationService.unsubscribeFromOrderUpdates(
            _currentUser!.id,
          );
        }

        // cancel token refresh listener
        _notificationService.cancelTokenListener();
      }

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

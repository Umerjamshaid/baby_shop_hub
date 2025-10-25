import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password - UPDATED with better error handling
  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String name,
    String? phone, {
    String role = 'user',
  }) async {
    try {
      debugPrint('Starting sign up process for: $email');

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      debugPrint('User created successfully: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
          addresses: [],
          favoriteProducts: [],
        );

        debugPrint('Saving user to Firestore: ${newUser.toMap()}');

        // Save user to Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        debugPrint('User saved to Firestore successfully');
        return newUser;
      }
      debugPrint('User creation failed - user is null');
      return null;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      // Handle specific errors
      if (e is FirebaseAuthException) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
      throw Exception('Failed to create account: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('Signing in: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('User signed in, fetching data from Firestore');
        // Get user data from Firestore
        return await _getUserData(userCredential.user!.uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      // Handle specific errors
      if (e is FirebaseAuthException) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
      throw Exception('Failed to sign in: $e');
    }
  }

  // Helper method to get user data
  Future<UserModel?> _getUserData(String userId) async {
    try {
      debugPrint('Fetching user data for: $userId');

      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        debugPrint('User document found');
        final data = userDoc.data();
        if (data is Map<String, dynamic>) {
          return UserModel.fromMap(data);
        }
        throw Exception('Invalid user data format');
      }
      debugPrint('User document does not exist in Firestore');
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Error sending reset email: $e');
      if (e is FirebaseAuthException) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
      throw Exception('Failed to reset password: $e');
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (_auth.currentUser != null) {
        debugPrint('Getting current user data: ${_auth.currentUser!.uid}');
        return await _getUserData(_auth.currentUser!.uid);
      }
      debugPrint('No current user found');
      return null;
    } catch (e) {
      debugPrint('Error getting current user data: $e');
      throw Exception('Failed to get current user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      debugPrint('Updating user profile: ${user.id}');
      final data = user.toMap();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(data);
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = _auth.currentUser != null;
      debugPrint('Login check: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }
}

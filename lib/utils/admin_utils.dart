import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AdminUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Update a user's role and keep `isAdmin` in sync
  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'role': newRole,
        'isAdmin': newRole == 'admin', // keep in sync with role
      });
      print('✅ User $userId role updated to: $newRole');
    } catch (e) {
      print('❌ Error updating user role: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  /// 🔹 Promote user to admin
  static Future<void> makeUserAdmin(String userId) async {
    await updateUserRole(userId, 'admin');
  }

  /// 🔹 Demote user to regular
  static Future<void> makeUserRegular(String userId) async {
    await updateUserRole(userId, 'user');
  }

  /// 🔹 Create a new user with a specific role
  static Future<void> createUserWithRole({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user in Firestore with role
        UserModel user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          isAdmin: role == 'admin', // keep in sync
          createdAt: DateTime.now(),
          addresses: [],
          favoriteProducts: [],
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .set(user.toMap());

        print('✅ User created with role $role: ${user.id}');
      }
    } catch (e) {
      print('❌ Error creating user with role: $e');
      throw Exception('Failed to create user with role: $e');
    }
  }

  /// 🔹 Check if current logged in user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      if (_auth.currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(_auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data is Map<String, dynamic>) {
            final userModel = UserModel.fromMap(data);
            return userModel.isAdministrator; // helper from model
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// 🔹 Check if a specific user has a given role
  static Future<bool> userHasRole(String userId, String role) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data is Map<String, dynamic>) {
          final userModel = UserModel.fromMap(data);
          return userModel.role == role;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// 🔹 Get all users by role
  static Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: role)
          .get();

      return querySnapshot.docs
          .map((doc) =>
          UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting users by role: $e');
      return [];
    }
  }

  /// 🔹 Get all admin users
  static Future<List<UserModel>> getAdminUsers() async {
    return await getUsersByRole('admin');
  }

  /// 🔹 Available roles (expandable list)
  static List<String> getAvailableRoles() {
    return ['user', 'admin', 'moderator', 'editor']; // add more if needed
  }

  /// 🔹 Get a user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ----------------------------
  // 🔹 User CRUD
  // ----------------------------

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get users by their IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final users = await Future.wait(
        userIds.map((userId) async {
          final doc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .get();
          return doc.exists
              ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
              : null;
        }),
      );

      return users.whereType<UserModel>().toList();
    } catch (e) {
      throw Exception('Failed to fetch users by IDs: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final nameQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      final emailQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '${query}z')
          .get();

      // Combine + deduplicate
      final allDocs = [...nameQuery.docs, ...emailQuery.docs];
      final uniqueDocs = allDocs.toSet().toList();

      return uniqueDocs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // ----------------------------
  // 🔹 Profile & Image
  // ----------------------------

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child(AppConstants.userImagesPath)
          .child(
            '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      final UploadTask uploadTask = storageRef.putFile(File(filePath));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final Reference storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // ----------------------------
  // 🔹 Address Management
  // ----------------------------

  Future<void> addAddress(String userId, Address address) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      if (address.isDefault) {
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final List<dynamic> addresses = userData['addresses'] ?? [];

          for (int i = 0; i < addresses.length; i++) {
            addresses[i]['isDefault'] = false;
          }
          await userRef.update({'addresses': addresses});
        }
      }

      await userRef.update({
        'addresses': FieldValue.arrayUnion([address.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<void> updateAddress(String userId, Address address) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> addresses = userData['addresses'] ?? [];

        final int index = addresses.indexWhere((a) => a['id'] == address.id);
        if (index != -1) {
          addresses[index] = address.toMap();

          if (address.isDefault) {
            for (int i = 0; i < addresses.length; i++) {
              if (i != index) addresses[i]['isDefault'] = false;
            }
          }

          await userRef.update({'addresses': addresses});
        }
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> addresses = userData['addresses'] ?? [];

        addresses.removeWhere((a) => a['id'] == addressId);

        await userRef.update({'addresses': addresses});
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }
}

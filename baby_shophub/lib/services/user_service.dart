import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Update user profile
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

  // Upload profile image
  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child(AppConstants.userImagesPath)
          .child('$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final UploadTask uploadTask = storageRef.putFile(File(filePath));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete profile image
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

  // Add address
  Future<void> addAddress(String userId, Address address) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      // If this address is default, remove default from others
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

      // Add new address
      await userRef.update({
        'addresses': FieldValue.arrayUnion([address.toMap()])
      });
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update address
  Future<void> updateAddress(String userId, Address address) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      // Get current addresses
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> addresses = userData['addresses'] ?? [];

        // Find and update the address
        final int index = addresses.indexWhere((a) => a['id'] == address.id);
        if (index != -1) {
          addresses[index] = address.toMap();

          // If this address is default, remove default from others
          if (address.isDefault) {
            for (int i = 0; i < addresses.length; i++) {
              if (i != index) {
                addresses[i]['isDefault'] = false;
              }
            }
          }

          await userRef.update({'addresses': addresses});
        }
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      // Get current addresses
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> addresses = userData['addresses'] ?? [];

        // Remove the address
        addresses.removeWhere((a) => a['id'] == addressId);

        await userRef.update({'addresses': addresses});
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
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
}
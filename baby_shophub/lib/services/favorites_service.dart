import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../utils/constants.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add product to favorites
  Future<void> addToFavorites(String userId, String productId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'favoriteProducts': FieldValue.arrayUnion([productId])
    });
  }

  // Remove product from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'favoriteProducts': FieldValue.arrayRemove([productId])
    });
  }

  // Get user's favorite products
  Future<List<Product>> getUserFavorites(String userId) async {
    try {
      // Get user document
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<String> favoriteProductIds =
        List<String>.from(userData['favoriteProducts'] ?? []);

        if (favoriteProductIds.isEmpty) {
          return [];
        }

        // Get all favorite products
        final QuerySnapshot productsSnapshot = await _firestore
            .collection(AppConstants.productsCollection)
            .where(FieldPath.documentId, whereIn: favoriteProductIds)
            .get();

        return productsSnapshot.docs
            .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  // Check if product is in favorites
  Future<bool> isProductInFavorites(String userId, String productId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<String> favoriteProductIds =
        List<String>.from(userData['favoriteProducts'] ?? []);

        return favoriteProductIds.contains(productId);
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check favorites: $e');
    }
  }
}
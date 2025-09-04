import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../utils/constants.dart';

class FavoritesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _favoriteProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user favorites
  Future<void> loadUserFavorites(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
          _favoriteProducts = [];
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Get all favorite products
        final QuerySnapshot productsSnapshot = await _firestore
            .collection(AppConstants.productsCollection)
            .where(FieldPath.documentId, whereIn: favoriteProductIds)
            .get();

        _favoriteProducts = productsSnapshot.docs
            .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        _favoriteProducts = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'favoriteProducts': FieldValue.arrayUnion([productId])
      });

      // Reload favorites to update the list
      await loadUserFavorites(userId);
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'favoriteProducts': FieldValue.arrayRemove([productId])
      });

      // Reload favorites to update the list
      await loadUserFavorites(userId);
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if product is in favorites
  Future<bool> isProductInFavorites(String userId, String productId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final favorites = List<String>.from(data['favoriteProducts'] ?? []);
        return favorites.contains(productId);
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check favorites: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
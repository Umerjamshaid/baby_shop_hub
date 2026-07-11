import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item_model.dart';
import '../utils/constants.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user cart items
  Future<List<CartItem>> getUserCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.cartCollection)
          .get();

      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  // Add item to cart
  Future<void> addToCart(String userId, CartItem cartItem) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.cartCollection)
          .doc(cartItem.id)
          .set(cartItem.toMap());
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.cartCollection)
          .doc(cartItemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  // Update item quantity
  Future<void> updateCartItemQuantity(
      String userId, String cartItemId, int quantity) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.cartCollection)
          .doc(cartItemId)
          .update({'quantity': quantity});
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  // Clear user cart
  Future<void> clearCart(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      var cartItems = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.cartCollection)
          .get();

      for (var doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }
}
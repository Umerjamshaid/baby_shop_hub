import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products Collection
  CollectionReference get productsCollection =>
      _firestore.collection(AppConstants.productsCollection);

  // Categories Collection
  CollectionReference get categoriesCollection =>
      _firestore.collection(AppConstants.categoriesCollection);

  // Users Collection
  CollectionReference get usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  // Orders Collection
  CollectionReference get ordersCollection =>
      _firestore.collection(AppConstants.ordersCollection);

  // Get all products
  Stream<List<Product>> getProducts() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  // Get featured products
  Stream<List<Product>> getFeaturedProducts() {
    return productsCollection
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await productsCollection.doc(productId).get();
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all categories
  Stream<List<Category>> getCategories() {
    return categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get user cart items
  Stream<List<CartItem>> getUserCart(String userId) {
    return usersCollection
        .doc(userId)
        .collection(AppConstants.cartCollection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CartItem.fromMap(doc.data()))
              .toList();
        });
  }

  // Add item to user cart
  Future<void> addToCart(String userId, CartItem cartItem) async {
    await usersCollection
        .doc(userId)
        .collection(AppConstants.cartCollection)
        .doc(cartItem.id)
        .set(cartItem.toMap());
  }

  // Remove item from user cart
  Future<void> removeFromCart(String userId, String cartItemId) async {
    await usersCollection
        .doc(userId)
        .collection(AppConstants.cartCollection)
        .doc(cartItemId)
        .delete();
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(
    String userId,
    String cartItemId,
    int quantity,
  ) async {
    await usersCollection
        .doc(userId)
        .collection(AppConstants.cartCollection)
        .doc(cartItemId)
        .update({'quantity': quantity});
  }

  // Clear user cart
  Future<void> clearCart(String userId) async {
    WriteBatch batch = _firestore.batch();
    var cartItems = await usersCollection
        .doc(userId)
        .collection(AppConstants.cartCollection)
        .get();

    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Create order
  Future<void> createOrder(Order order) async {
    await ordersCollection.doc(order.id).set(order.toMap());
  }

  // Get user orders
  Stream<List<Order>> getUserOrders(String userId) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Add review
  Future<void> addReview(Review review) async {
    // Add to reviews subcollection of product
    await productsCollection
        .doc(review.productId)
        .collection('reviews')
        .doc(review.id)
        .set(review.toMap());

    // Update product rating
    var reviewsSnapshot = await productsCollection
        .doc(review.productId)
        .collection('reviews')
        .get();

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    double newRating = totalRating / reviewsSnapshot.docs.length;
    int reviewCount = reviewsSnapshot.docs.length;

    await productsCollection.doc(review.productId).update({
      'rating': newRating,
      'reviewCount': reviewCount,
    });
  }

  // Get product reviews
  Stream<List<Review>> getProductReviews(String productId) {
    return productsCollection
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromMap(doc.data()))
              .toList();
        });
  }
}

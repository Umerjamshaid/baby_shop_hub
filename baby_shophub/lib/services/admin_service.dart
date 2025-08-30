import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========================= USERS =========================
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.usersCollection).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Admin permissions required to fetch users.');
      }
      throw Exception('Failed to fetch users: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // ========================= ORDERS =========================
  Future<List<Order>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Admin permissions required. Please check Firestore rules.');
      }
      throw Exception('Failed to fetch orders: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final orderRef = _firestore.collection(AppConstants.ordersCollection).doc(orderId);

      final update = {
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Status updated by admin',
      };

      final batch = _firestore.batch();
      batch.update(orderRef, {'status': status});
      batch.update(orderRef, {
        'statusUpdates': FieldValue.arrayUnion([update])
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Failed to update order status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> addTrackingInfo(String orderId, String trackingNumber, String carrier) async {
    try {
      final orderRef = _firestore.collection(AppConstants.ordersCollection).doc(orderId);

      final batch = _firestore.batch();
      batch.update(orderRef, {
        'trackingNumber': trackingNumber,
        'carrier': carrier,
        'status': 'Shipped',
      });
      batch.update(orderRef, {
        'statusUpdates': FieldValue.arrayUnion([
          {
            'status': 'Shipped',
            'timestamp': DateTime.now().toIso8601String(),
            'message': 'Tracking info added by admin',
          }
        ])
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Failed to add tracking info: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add tracking info: $e');
    }
  }

  // ========================= DASHBOARD =========================
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection(AppConstants.usersCollection).get();
      final ordersSnapshot = await _firestore.collection(AppConstants.ordersCollection).get();
      final productsSnapshot = await _firestore.collection(AppConstants.productsCollection).get();

      double totalSales = 0;
      int totalOrders = 0;
      int completedOrders = 0;

      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        final orderStatus = orderData['status']?.toString() ?? 'Pending';

        if (orderStatus == 'Delivered') {
          final orderAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
          totalSales += orderAmount;
          completedOrders++;
        }
        totalOrders++;
      }

      final popularProducts = await _getPopularProducts();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalProducts': productsSnapshot.docs.length,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'totalSales': totalSales,
        'popularProducts': popularProducts,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getPopularProducts() async {
    try {
      final ordersSnapshot = await _firestore.collection(AppConstants.ordersCollection).get();

      final productCounts = <String, int>{};
      final productDetails = <String, Product>{};

      // Count product occurrences in orders
      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final productId = item['productId']?.toString() ?? '';
          if (productId.isNotEmpty) {
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            productCounts[productId] = (productCounts[productId] ?? 0) + quantity;
          }
        }
      }

      // Get product details
      final productsSnapshot = await _firestore.collection(AppConstants.productsCollection).get();

      for (var doc in productsSnapshot.docs) {
        final productData = doc.data();
        final product = Product.fromMap(Map<String, dynamic>.from(productData));
        productDetails[product.id] = product;
      }

      // Create sorted list of popular products
      final popularProducts = productCounts.entries.map((entry) {
        final product = productDetails[entry.key];
        if (product != null) {
          return {
            'product': product,
            'count': entry.value,
            'revenue': (product.price) * entry.value,
          };
        }
        return null;
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

      popularProducts.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return popularProducts.take(5).toList();
    } catch (e) {
      throw Exception('Failed to fetch popular products: $e');
    }
  }

  // ========================= PRODUCTS =========================
  Future<void> createProduct(Product product) async {
    try {
      await _firestore.collection(AppConstants.productsCollection).doc(product.id).set(product.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to create product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection(AppConstants.productsCollection).doc(product.id).update(product.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(AppConstants.productsCollection).doc(productId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw Exception('Product not found.');
      }
      throw Exception('Failed to delete product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ========================= IMAGES =========================
  Future<String> uploadProductImage(String filePath) async {
    try {
      final Reference storageRef = _storage
          .ref()
          .child(AppConstants.productImagesPath)
          .child('product_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final TaskSnapshot snapshot = await storageRef.putFile(File(filePath));
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload product image: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final Reference storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      }
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete product image: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete product image: $e');
    }
  }

  // ========================= ROLES =========================
  Future<void> updateUserRole(String userId, bool isAdmin) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isAdmin': isAdmin, 'role': isAdmin ? 'admin' : 'user'});
    } on FirebaseException catch (e) {
      throw Exception('Failed to update user role: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
}

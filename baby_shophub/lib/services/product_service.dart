import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../utils/constants.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isFeatured', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch category products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      List<Product> allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Simple client-side search
      return allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}
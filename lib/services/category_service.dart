import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // ✅ Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // ✅ Add new category
  Future<void> addCategory(Category category) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .set(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // ✅ Update category
  Future<void> updateCategory(Category category) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // ✅ Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ✅ Get categories with product count (using copyWith)
  Future<List<Category>> getCategoriesWithProductCount() async {
    try {
      // Get all categories
      final categories = await getAllCategories();

      // Get all products once
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      final products = productsSnapshot.docs.map((doc) => doc.data()).toList();

      // Return updated categories using copyWith
      final updatedCategories = categories.map((category) {
        final count = products
            .where((product) => product['category'] == category.name)
            .length;

        return category.copyWith(productCount: count);
      }).toList();

      return updatedCategories;
    } catch (e) {
      throw Exception('Failed to fetch categories with product count: $e');
    }
  }
}

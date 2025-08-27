import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/review_model.dart';
import '../utils/constants.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new review
  Future<void> addReview(Review review) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(review.productId)
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());

      // Update product rating statistics
      await _updateProductRating(review.productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Get reviews for a product
  Stream<List<Review>> getProductReviews(String productId) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .collection('reviews')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromMap(doc.data()))
              .toList();
        });
  }

  // Get user's reviews
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromMap(doc.data()))
              .toList();
        });
  }

  // Check if user has purchased a product
  Future<bool> hasUserPurchasedProduct(String userId, String productId) async {
    try {
      // Check if product exists in any of user's completed orders
      final ordersSnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Delivered')
          .get();

      for (final orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];

        final hasProduct = items.any(
          (item) =>
              item is Map<String, dynamic> && item['productId'] == productId,
        );

        if (hasProduct) return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check purchase status: $e');
    }
  }

  // Update helpful votes
  Future<void> toggleHelpfulVote(
    String productId,
    String reviewId,
    String userId,
  ) async {
    try {
      final reviewRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .doc(reviewId);

      final reviewDoc = await reviewRef.get();
      if (reviewDoc.exists) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>;
        final helpfulVotes = List<String>.from(
          reviewData['helpfulVotes'] ?? [],
        );

        if (helpfulVotes.contains(userId)) {
          // Remove vote
          helpfulVotes.remove(userId);
        } else {
          // Add vote
          helpfulVotes.add(userId);
        }

        await reviewRef.update({'helpfulVotes': helpfulVotes});
      }
    } catch (e) {
      throw Exception('Failed to update helpful vote: $e');
    }
  }

  // Update product rating statistics
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .where('isApproved', isEqualTo: true)
          .get();

      final reviews = reviewsSnapshot.docs
          .map((doc) => Review.fromMap(doc.data()))
          .toList();

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold(
          0.0,
          (sum, review) => sum + review.rating,
        );
        final averageRating = totalRating / reviews.length;
        final reviewCount = reviews.length;

        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .update({'rating': averageRating, 'reviewCount': reviewCount});
      }
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  // Upload review images
  Future<List<String>> uploadReviewImages(
    String reviewId,
    List<String> filePaths,
  ) async {
    try {
      final List<String> downloadUrls = [];

      for (final filePath in filePaths) {
        final Reference storageRef = _storage
            .ref()
            .child('review_images')
            .child(reviewId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final UploadTask uploadTask = storageRef.putFile(File(filePath));
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload review images: $e');
    }
  }

  // Delete review images
  Future<void> deleteReviewImages(List<String> imageUrls) async {
    try {
      for (final imageUrl in imageUrls) {
        if (imageUrl.isNotEmpty) {
          final Reference storageRef = _storage.refFromURL(imageUrl);
          await storageRef.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete review images: $e');
    }
  }

  // Check if user has reviewed a product
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      final reviewSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      return reviewSnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check user review: $e');
    }
  }

  // Get user's review for a specific product
  Future<Review?> getUserProductReview(String userId, String productId) async {
    try {
      final reviewSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (reviewSnapshot.docs.isNotEmpty) {
        return Review.fromMap(reviewSnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user review: $e');
    }
  }
}

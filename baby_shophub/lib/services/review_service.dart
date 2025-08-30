import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/review_model.dart';
import '../utils/constants.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ----------------- Add a new review -----------------
  Future<void> addReview(Review review) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(review.productId)
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());

      // Update product stats after adding
      await _updateProductRating(review.productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // ----------------- Get all reviews for a product -----------------
  Stream<List<Review>> getProductReviews(String productId) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .collection('reviews')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList());
  }

  // ----------------- Get reviews by a user -----------------
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList());
  }

  // ----------------- Check if user purchased this product -----------------
  Future<bool> hasUserPurchasedProduct(String userId, String productId) async {
    try {
      final ordersSnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
      // Check for any "finished" statuses
          .where('status', whereIn: ['Delivered', 'Completed'])
          .get();

      for (final orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];

        final hasProduct = items.any((item) {
          if (item is Map<String, dynamic>) {
            return item['productId'] == productId;
          }
          return false;
        });

        if (hasProduct) return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check purchase status: $e');
    }
  }

  // ----------------- Toggle helpful votes -----------------
  Future<void> toggleHelpfulVote(
      String productId, String reviewId, String userId) async {
    try {
      final reviewRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .doc(reviewId);

      final reviewDoc = await reviewRef.get();
      if (reviewDoc.exists) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>;
        final helpfulVotes = List<String>.from(reviewData['helpfulVotes'] ?? []);

        if (helpfulVotes.contains(userId)) {
          helpfulVotes.remove(userId);
        } else {
          helpfulVotes.add(userId);
        }

        await reviewRef.update({'helpfulVotes': helpfulVotes});
      }
    } catch (e) {
      throw Exception('Failed to update helpful vote: $e');
    }
  }

  // ----------------- Update product rating stats -----------------
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .collection('reviews')
          .where('isApproved', isEqualTo: true)
          .get();

      final reviews =
      reviewsSnapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(
            0.0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / reviews.length;

        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .update({
          'rating': averageRating,
          'reviewCount': reviews.length,
        });
      }
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  // ----------------- Upload review images -----------------
  Future<List<String>> uploadReviewImages(
      String reviewId, List<String> filePaths) async {
    try {
      final List<String> downloadUrls = [];

      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!file.existsSync()) continue; // skip invalid files

        final Reference storageRef = _storage
            .ref()
            .child('review_images')
            .child(reviewId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final UploadTask uploadTask = storageRef.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload review images: $e');
    }
  }

  // ----------------- Delete review images -----------------
  Future<void> deleteReviewImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      if (imageUrl.isEmpty) continue;
      try {
        final Reference storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        // Ignore if file already deleted
      }
    }
  }

  // ----------------- Check if user already reviewed -----------------
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

  // ----------------- Get user review for product -----------------
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

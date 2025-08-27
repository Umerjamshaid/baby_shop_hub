import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/review_service.dart';
import '../../../models/review_model.dart';
import '../common/star_rating.dart';

class ReviewsList extends StatelessWidget {
  final String productId;
  final bool showHeader;
  final int maxReviews;

  const ReviewsList({
    super.key,
    required this.productId,
    this.showHeader = true,
    this.maxReviews = 5,
  });

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return StreamBuilder<List<Review>>(
      stream: reviewService.getProductReviews(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const Text(
                'Customer Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            ...reviews.take(maxReviews).map((review) => _buildReviewItem(context, review)),
            if (reviews.length > maxReviews) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to full reviews screen
                },
                child: const Text('View All Reviews'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        review.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (review.isVerifiedPurchase)
                  const Tooltip(
                    message: 'Verified Purchase',
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating
            StarRating(rating: review.rating, starSize: 16),
            const SizedBox(height: 12),

            // Review Text
            Text(
              review.comment,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),

            // Review Images
            if (review.imageUrls.isNotEmpty) _buildReviewImages(review.imageUrls),
            const SizedBox(height: 12),

            // Helpful Votes
            _buildHelpfulSection(context, review),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewImages(List<String> imageUrls) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrls[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpfulSection(BuildContext context, Review review) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reviewService = ReviewService();

    return Row(
      children: [
        TextButton(
          onPressed: authProvider.currentUser != null
              ? () async {
            await reviewService.toggleHelpfulVote(
              review.productId,
              review.id,
              authProvider.currentUser!.id,
            );
          }
              : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Row(
            children: [
              Icon(
                review.hasUserVoted(authProvider.currentUser?.id ?? '')
                    ? Icons.thumb_up
                    : Icons.thumb_up_alt_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'Helpful (${review.helpfulVotes.length})',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String error) {
    return Text('Error loading reviews: $error');
  }

  Widget _buildEmptyState() {
    return const Column(
      children: [
        Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No reviews yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Be the first to review this product!',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
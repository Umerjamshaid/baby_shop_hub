import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../services/review_service.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../widgets/common/star_rating.dart';
import '../widgets/common/app_button.dart';

class AddReviewScreen extends StatefulWidget {
  final Product product;

  const AddReviewScreen({super.key, required this.product});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;
  bool _hasPurchased = false;
  List<String> _imageUrls = [];
  final List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _checkPurchaseStatus();
  }

  Future<void> _checkPurchaseStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final hasPurchased = await _reviewService.hasUserPurchasedProduct(
        authProvider.currentUser!.id,
        widget.product.id,
      );
      setState(() {
        _hasPurchased = hasPurchased;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(authProvider),
    );
  }

  Widget _buildContent(AuthProvider authProvider) {
    if (authProvider.currentUser == null) {
      return _buildNotLoggedIn();
    }

    if (!_hasPurchased) {
      return _buildNotPurchased();
    }

    return _buildReviewForm(authProvider);
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Please sign in to write a review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You need to be logged in to review products',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              text: 'Sign In',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotPurchased() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Purchase Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You need to purchase this product before you can review it',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'Continue Shopping',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            _buildProductInfo(),
            const SizedBox(height: 24),

            // Rating
            _buildRatingSection(),
            const SizedBox(height: 24),

            // Review Comment
            _buildCommentSection(),
            const SizedBox(height: 24),

            // Image Upload
            _buildImageUploadSection(),
            const SizedBox(height: 32),

            // Submit Button
            AppButton(
              onPressed: _submitReview,
              text: 'Submit Review',
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(widget.product.firstImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.category,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StarRating(
          rating: _rating,
          starSize: 36,
          allowEditing: true,
          onRatingChanged: (rating) {
            setState(() {
              _rating = rating;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          _rating == 0 ? 'Tap a star to rate' : '${_rating.toInt()}/5 stars',
          style: TextStyle(
            color: _rating == 0 ? Colors.grey : Colors.amber,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Share your experience with this product...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please write a review';
            }
            if (value.length < 10) {
              return 'Review must be at least 10 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Photos (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload photos of your product to help other customers',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Selected Images
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImages[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Upload Button
        OutlinedButton(
          onPressed: _pickImages,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 20),
              SizedBox(width: 8),
              Text('Add Photos'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => xfile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser!;

        // Upload images if any
        if (_selectedImages.isNotEmpty) {
          _imageUrls = await _reviewService.uploadReviewImages(
            'review_${DateTime.now().millisecondsSinceEpoch}',
            _selectedImages,
          );
        }

        // Create review
        final review = Review(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.id,
          userEmail: user.email,
          userName: user.name,
          productId: widget.product.id,
          productName: widget.product.name,
          rating: _rating,
          comment: _commentController.text.trim(),
          imageUrls: _imageUrls,
          createdAt: DateTime.now(),
          isVerifiedPurchase: true,
        );

        // Save review
        await _reviewService.addReview(review);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
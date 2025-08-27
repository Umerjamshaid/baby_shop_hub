import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import '../widgets/common/app_button.dart';
import '../widgets/product/reviews_list.dart';
import 'add_review_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Product Images Carousel
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(),
                    const SizedBox(height: 16),

                    // Product Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Text(
                                widget.product.formattedPrice,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.amber,
                              ),
                              Text(
                                widget.product.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                ' (${widget.product.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category and Brand
                          Row(
                            children: [
                              _buildInfoChip(
                                'Category',
                                widget.product.category,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip('Brand', widget.product.brand),
                              const SizedBox(width: 8),
                              _buildInfoChip('Age', widget.product.ageRange),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stock Status
                          Text(
                            widget.product.inStock
                                ? 'In Stock (${widget.product.stock} available)'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.product.inStock
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 24),

                          // Quantity Selector
                          if (widget.product.inStock) _buildQuantitySelector(),
                          const SizedBox(height: 24),
                          // 👇 Reviews Section Inserted Here
                          const Divider(),
                          const SizedBox(height: 24),

                          // Reviews List
                          ReviewsList(productId: widget.product.id),

                          // Add Review Button
                          if (authProvider.currentUser != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddReviewScreen(
                                      product: widget.product,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Write a Review'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add to Cart Button
            if (widget.product.inStock)
              _buildAddToCartButton(cartProvider, authProvider),
          ],
        ),
      ),
    );
  }

  // SIMPLE IMAGE CAROUSEL WITHOUT EXTERNAL DEPENDENCIES
  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Main Image Display
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(
                widget.product.imageUrls.isNotEmpty
                    ? widget.product.imageUrls[_currentImageIndex]
                    : 'https://via.placeholder.com/300',
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Image Thumbnails (if multiple images)
        if (widget.product.imageUrls.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.product.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(widget.product.imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Dot Indicators
        if (widget.product.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.product.imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.blue
                        : Colors.grey,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            if (_quantity > 1) {
              setState(() {
                _quantity--;
              });
            }
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _quantity.toString(),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            if (_quantity < widget.product.stock) {
              setState(() {
                _quantity++;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        onPressed: () {
          if (authProvider.currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to add items to cart'),
              ),
            );
            return;
          }

          cartProvider.addToCart(
            authProvider.currentUser!.id,
            widget.product,
            quantity: _quantity,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $_quantity ${widget.product.name} to cart'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        text:
            'Add to Cart - \$${(widget.product.price * _quantity).toStringAsFixed(2)}',
        width: double.infinity,
      ),
    );
  }
}

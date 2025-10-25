import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/product/reviews_list.dart';
import 'add_review_screen.dart';
import 'reviews_analytics_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isExpanded = false;
  late TabController _tabController;
  bool _isImageZoomed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Favorite and Share Methods
  Future<bool> _getFavoriteStatus(FavoritesProvider favoritesProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return false;

    return await favoritesProvider.isProductInFavorites(
      authProvider.currentUser!.id,
      widget.product.id,
    );
  }

  Future<void> _toggleFavorite(FavoritesProvider favoritesProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      _showLoginDialog(context);
      return;
    }

    try {
      final isCurrentlyFavorite = await _getFavoriteStatus(favoritesProvider);

      if (isCurrentlyFavorite) {
        await favoritesProvider.removeFromFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      } else {
        await favoritesProvider.addToFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update favorites: $e')));
    }
  }

  void _shareProduct() {
    final product = widget.product;
    final shareText =
        '''
🌟 Check out this amazing baby product! 🌟

${product.name}
${product.description}

Price: ${product.formattedPrice}
Rating: ⭐ ${product.rating} (${product.reviewCount} reviews)

Perfect for: ${product.ageRange}
Category: ${product.category}

Get it now on BabyShopHub! 🛍️
''';

    Share.share(shareText, subject: 'Amazing Baby Product: ${product.name}');
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Login Required'),
        content: const Text('Please login to add items to your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showAddToCartSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Added $_quantity ${widget.product.name} to cart',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header with back button and actions
            _buildHeader(),

            // Product Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Enhanced Image Carousel with zoom capability
                    _buildEnhancedImageCarousel(),

                    // Product Card with glassmorphism effect
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Title and Price
                            _buildProductHeader(),

                            const SizedBox(height: 16),

                            // Enhanced Info Chips
                            _buildEnhancedInfoChips(),

                            const SizedBox(height: 20),

                            // Stock Status with progress indicator
                            _buildStockIndicator(),

                            const SizedBox(height: 24),

                            // Expandable Description
                            _buildExpandableDescription(),

                            const SizedBox(height: 24),

                            // Quantity Selector (Enhanced)
                            if (widget.product.inStock)
                              _buildEnhancedQuantitySelector(),
                          ],
                        ),
                      ),
                    ),

                    // Tabbed Content Section
                    _buildTabbedContent(authProvider),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),

            // Enhanced Floating Add to Cart Button
            if (widget.product.inStock)
              _buildFloatingAddToCartButton(cartProvider, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          // Favorite Button
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              return FutureBuilder<bool>(
                future: _getFavoriteStatus(favoritesProvider),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                      ),
                      onPressed: () => _toggleFavorite(favoritesProvider),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          // Share Button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              onPressed: _shareProduct,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedImageCarousel() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Image with zoom capability
          GestureDetector(
            onTap: () {
              setState(() {
                _isImageZoomed = !_isImageZoomed;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isImageZoomed ? 400 : 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.network(
                      widget.product.imageUrls.isNotEmpty
                          ? widget.product.imageUrls[_currentImageIndex]
                          : 'https://via.placeholder.com/300',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                    if (_isImageZoomed)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.zoom_out,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Enhanced Image Thumbnails
          if (widget.product.imageUrls.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.product.imageUrls.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentImageIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: _currentImageIndex == index ? 3 : 1,
                          ),
                          boxShadow: _currentImageIndex == index
                              ? [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.product.imageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                widget.product.formattedPrice,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
            const Spacer(),
            // Enhanced Rating Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    widget.product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' (${widget.product.reviewCount})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoChips() {
    final chips = [
      {
        'label': 'Category',
        'value': widget.product.category,
        'icon': Icons.category,
      },
      {
        'label': 'Brand',
        'value': widget.product.brand,
        'icon': Icons.branding_watermark,
      },
      {
        'label': 'Age',
        'value': widget.product.ageRange,
        'icon': Icons.child_care,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chip['icon'] as IconData, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                '${chip['label']}: ${chip['value']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.product.inStock ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.product.inStock
                  ? 'In Stock (${widget.product.stock} available)'
                  : 'Out of Stock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.product.inStock ? Colors.green[700] : Colors.red,
              ),
            ),
          ],
        ),
        if (widget.product.inStock && widget.product.stock <= 10) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Text(
                  'Only ${widget.product.stock} left in stock!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandableDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                child: Text(
                  'Read more',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.description,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: Text(
                  'Show less',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Text(
            'Quantity:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _quantity > 1
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: _quantity > 1 ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _quantity < widget.product.stock
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: _quantity < widget.product.stock
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                  onPressed: () {
                    if (_quantity < widget.product.stock) {
                      setState(() {
                        _quantity++;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedContent(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.all(16),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Reviews'),
                Tab(text: 'Specifications'),
                Tab(text: 'Shipping'),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Reviews Tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Reviews Analytics Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReviewsAnalyticsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics),
                          label: const Text('View Reviews Analytics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[50],
                            foregroundColor: Colors.purple[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.purple[200]!),
                            ),
                          ),
                        ),
                      ),
                      // Reviews List with constrained height
                      Expanded(
                        child: ReviewsList(
                          productId: widget.product.id,
                          showHeader: false, // Hide header to save space
                        ),
                      ),
                      if (authProvider.currentUser != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddReviewScreen(product: widget.product),
                                ),
                              );
                            },
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write a Review'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Specifications Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _buildSpecItem('Brand', widget.product.brand),
                      _buildSpecItem('Category', widget.product.category),
                      _buildSpecItem('Age Range', widget.product.ageRange),
                      _buildSpecItem(
                        'Weight',
                        '${(widget.product.price * 0.1).toStringAsFixed(1)} kg',
                      ),
                      _buildSpecItem('Dimensions', '20 × 15 × 8 cm'),
                      _buildSpecItem('Material', 'High-quality plastic'),
                      _buildSpecItem('Safety', 'CE certified'),
                    ],
                  ),
                ),

                // Shipping Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _buildShippingOption(
                        'Standard Delivery',
                        '5-7 business days',
                        'Free',
                        Icons.local_shipping,
                      ),
                      const SizedBox(height: 12),
                      _buildShippingOption(
                        'Express Delivery',
                        '2-3 business days',
                        '\$4.99',
                        Icons.flash_on,
                      ),
                      const SizedBox(height: 12),
                      _buildShippingOption(
                        'Next Day Delivery',
                        'Next business day',
                        '\$9.99',
                        Icons.rocket_launch,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Free returns within 30 days of delivery',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOption(
    String title,
    String duration,
    String price,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: price == 'Free'
                  ? Colors.green
                  : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAddToCartButton(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppButton(
        onPressed: () {
          if (authProvider.currentUser == null) {
            _showLoginDialog(context);
            return;
          }

          cartProvider.addToCart(
            authProvider.currentUser!.id,
            widget.product,
            quantity: _quantity,
          );

          _showAddToCartSuccess();
        },
        text:
            'Add to Cart • \$${(widget.product.price * _quantity).toStringAsFixed(2)}',
        width: double.infinity,
      ),
    );
  }
}

import 'dart:ui';
import 'package:baby_shophub/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../screens/product_detail_screen.dart';
import '../common/app_button.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool showFavoriteButton;

  const ProductCard({
    super.key,
    required this.product,
    this.showFavoriteButton = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isHovered = false;
  late AnimationController _favoriteController;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null && widget.showFavoriteButton) {
      _isFavorite = await favoritesProvider.isProductInFavorites(
        authProvider.currentUser!.id,
        widget.product.id,
      );
    }

    if (mounted) {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) {
      _showSnackBar('Please login to add favorites', Icons.login, Colors.blue);
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }

    try {
      if (_isFavorite) {
        await favoritesProvider.addToFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar('Added to favorites', Icons.favorite, Colors.red);
      } else {
        await favoritesProvider.removeFromFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar(
          'Removed from favorites',
          Icons.heart_broken,
          Colors.grey,
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar('Failed to update favorites', Icons.error, Colors.red);
    }
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    Share.share(
      'Check out this product: ${widget.product.name} - ${widget.product.formattedPrice}',
      subject: 'BabyShopHub Product',
    );
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: _isHovered
          ? Matrix4.translationValues(0, -4, 0)
          : Matrix4.identity(),
      child: Card(
        elevation: _isHovered ? 8 : 4,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(product: widget.product),
              ),
            );
          },
          onHover: (hovered) {
            setState(() {
              _isHovered = hovered;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 300, // Increased height for better layout
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _isHovered ? Colors.grey.shade50 : Colors.white,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with badges
                _buildImageSection(),

                // Product Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and badges row
                        Row(
                          children: [
                            _buildCategoryBadge(),
                            const Spacer(),
                            if (widget.product.isFeatured == true)
                              _buildModernBadge(
                                'TRENDING',
                                Icons.trending_up,
                                Colors.purple,
                              ),
                            if (_isNewProduct())
                              _buildModernBadge(
                                'NEW',
                                Icons.new_releases,
                                Colors.teal,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Product name
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.3,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price and Rating Row
                        _buildPriceRatingRow(),
                        const SizedBox(height: 10),

                        // Stock indicator
                        _buildStockIndicator(),
                        const Spacer(),

                        // Add to Cart Button
                        _buildAddToCartButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 170, // Increased height for better visual impact
      child: Stack(
        children: [
          // Image with shimmer loading
          Hero(
            tag: 'product-${widget.product.id}',
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                  ],
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child:
                  widget.product.firstImage.isNotEmpty &&
                      (widget.product.firstImage.startsWith('http') ||
                          widget.product.firstImage.startsWith('assets'))
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: widget.product.firstImage.startsWith('http')
                          ? Image.network(
                              widget.product.firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade50,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.product.category.toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              widget.product.firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.product.category.toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.category.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(_isHovered ? 0.1 : 0.15),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Top badges row
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Share button
                if (widget.showFavoriteButton)
                  _buildGlassButton(
                    icon: Icons.share_rounded,
                    onTap: _shareProduct,
                  ),
                const Spacer(),

                // Sale/Featured badges
                if (widget.product.isOnSale)
                  _buildBadge('SALE', Icons.local_fire_department, Colors.red)
                else if (widget.product.isFeatured == true)
                  _buildBadge('HOT', Icons.star_rounded, Colors.amber),
                const SizedBox(width: 8),

                // Favorite button
                if (widget.showFavoriteButton && !_isCheckingFavorite)
                  _buildFavoriteButton(),
              ],
            ),
          ),

          // Discount badge (bottom left)
          if ((widget.product.discountPercentage ?? 0) > 0)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '-${widget.product.discountPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _favoriteController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_favoriteController.value * 0.3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isFavorite
                        ? Colors.red.withOpacity(.9)
                        : Colors.white.withOpacity(.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isFavorite
                          ? Colors.red.withOpacity(.6)
                          : Colors.white.withOpacity(.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: _isFavorite ? Colors.white : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  bool _isNewProduct() {
    // Consider a product "new" if it was created within the last 30 days
    if (widget.product.createdAt != null) {
      final now = DateTime.now();
      final difference = now.difference(widget.product.createdAt!);
      return difference.inDays <= 30;
    }
    return false;
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(.3), width: 1),
      ),
      child: Text(
        widget.product.category.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPriceRatingRow() {
    return Row(
      children: [
        // Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((widget.product.discountPercentage ?? 0) > 0)
                Text(
                  widget.product.formattedOriginalPrice ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade400,
                  ),
                ),
              Row(
                children: [
                  Text(
                    widget.product.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if ((widget.product.discountPercentage ?? 0) > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SAVE ${(widget.product.discountPercentage ?? 0).toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.amber.shade100],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: Colors.amber.shade700,
                shadows: [
                  Shadow(
                    color: Colors.amber.shade300,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                (widget.product.rating ?? 0).toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade800,
                ),
              ),
              Text(
                ' (${widget.product.reviewCount})',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockIndicator() {
    final inStock = widget.product.inStock;
    final lowStock = widget.product.stock < 10 && widget.product.stock > 0;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inStock
                ? (lowStock ? Colors.orange : Colors.green)
                : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          inStock
              ? (lowStock ? 'Only ${widget.product.stock} left' : 'In Stock')
              : 'Out of Stock',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: inStock
                ? (lowStock ? Colors.orange : Colors.green)
                : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context);
        final isInCart = cartProvider.isInCart(widget.product.id);
        final isOutOfStock = !widget.product.inStock;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (authProvider.currentUser == null) {
                      _showSnackBar(
                        'Please login to add to cart',
                        Icons.login,
                        Colors.blue,
                      );
                      return;
                    }

                    if (isInCart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    } else {
                      cartProvider.addToCart(
                        authProvider.currentUser!.id,
                        widget.product,
                      );
                      _showSnackBar(
                        'Added to cart',
                        Icons.shopping_cart,
                        Colors.green,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? Colors.grey.shade300
                  : isInCart
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              foregroundColor: isInCart
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              elevation: isInCart ? 0 : (_isHovered ? 6 : 3),
              shadowColor: isInCart
                  ? Colors.transparent
                  : Theme.of(context).primaryColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isInCart
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isOutOfStock
                        ? Icons.block
                        : isInCart
                        ? Icons.shopping_cart_checkout
                        : Icons.add_shopping_cart_rounded,
                    key: ValueKey<String>(
                      isOutOfStock
                          ? 'out'
                          : isInCart
                          ? 'in'
                          : 'add',
                    ),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOutOfStock
                      ? 'Out of Stock'
                      : isInCart
                      ? 'View Cart'
                      : 'Add to Cart',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

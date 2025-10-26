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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.blue.withOpacity(.15)
                    : Colors.black.withOpacity(.08),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.grey.shade900.withOpacity(.9),
                            Colors.grey.shade800.withOpacity(.8),
                          ]
                        : [
                            Colors.white.withOpacity(.95),
                            Colors.grey.shade50.withOpacity(.9),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(.2),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
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
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image with badges
                        _buildImageSection(isDark),

                        // Product Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category badge
                                _buildCategoryBadge(),
                                const SizedBox(height: 6),

                                // Product name
                                Flexible(
                                  child: Text(
                                    widget.product.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      letterSpacing: -0.2,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Price and Rating Row
                                _buildPriceRatingRow(isDark),
                                const SizedBox(height: 8),

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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return SizedBox(
      height: 160,
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
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                  ],
                ),
              ),
              child: widget.product.firstImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        widget.product.firstImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
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
                    Colors.black.withOpacity(.2),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // Top badges row
          Positioned(
            top: 8,
            left: 8,
            right: 8,
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
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  '-${widget.product.discountPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

  Widget _buildPriceRatingRow(bool isDark) {
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
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                widget.product.formattedPrice,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade700),
              const SizedBox(width: 3),
              Text(
                (widget.product.rating ?? 0).toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              Text(
                ' (${widget.product.reviewCount})',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
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
          duration: const Duration(milliseconds: 200),
          height: 36,
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
                  ? Colors.transparent
                  : Colors.blue,
              foregroundColor: isInCart ? Colors.blue : Colors.white,
              elevation: isInCart ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isInCart
                    ? BorderSide(color: Colors.blue, width: 1.5)
                    : BorderSide.none,
              ),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfStock
                      ? Icons.block
                      : isInCart
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart_rounded,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isOutOfStock
                      ? 'Out of Stock'
                      : isInCart
                      ? 'View Cart'
                      : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

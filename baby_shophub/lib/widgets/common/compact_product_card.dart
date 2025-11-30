import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/product_detail_screen.dart';
import '../../screens/cart_screen.dart';

class CompactProductCard extends StatefulWidget {
  final Product product;
  final bool showFavoriteButton;

  const CompactProductCard({
    super.key,
    required this.product,
    this.showFavoriteButton = true,
  });

  @override
  State<CompactProductCard> createState() => _CompactProductCardState();
}

class _CompactProductCardState extends State<CompactProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: _isHovered
          ? Matrix4.translationValues(0, -2, 0)
          : Matrix4.identity(),
      child: Card(
        elevation: _isHovered ? 6 : 3,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 160,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
                // Compact Image Section
                _buildImageSection(),

                // Compact Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name (compact)
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Price (compact)
                        Text(
                          widget.product.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade600,
                          ),
                        ),

                        // Spacer for add to cart button
                        const Spacer(),

                        // Compact Add to Cart Button
                        _buildCompactAddToCartButton(),
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
      height: 120,
      child: Stack(
        children: [
          // Image
          Hero(
            tag: 'product-${widget.product.id}',
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
              ),
              child:
                  widget.product.firstImage.isNotEmpty &&
                      (widget.product.firstImage.startsWith('http') ||
                          widget.product.firstImage.startsWith('assets'))
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: widget.product.firstImage.startsWith('http')
                          ? Image.network(
                              widget.product.firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade50,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
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
                                  child: Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              widget.product.firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
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
                                  child: Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 32,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
          ),

          // Sale badge (compact)
          if (widget.product.isOnSale ||
              (widget.product.discountPercentage ?? 0) > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.product.discountPercentage?.toInt() ?? 0}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactAddToCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context);
        final isInCart = cartProvider.isInCart(widget.product.id);
        final isOutOfStock = !widget.product.inStock;

        return SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (authProvider.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to add to cart'),
                          backgroundColor: Colors.blue,
                        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                          backgroundColor: Colors.green,
                        ),
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
              elevation: isInCart ? 0 : (_isHovered ? 4 : 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isInCart
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      )
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfStock
                      ? Icons.block
                      : isInCart
                      ? Icons.shopping_cart_checkout
                      : Icons.add,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isOutOfStock
                      ? 'Out'
                      : isInCart
                      ? 'View'
                      : 'Add',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

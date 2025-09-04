import 'package:baby_shophub/screens/cart_screen.dart';
import 'package:flutter/material.dart';
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

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);

    if (authProvider.currentUser != null && widget.showFavoriteButton) {
      _isFavorite = await favoritesProvider.isProductInFavorites(
        authProvider.currentUser!.id,
        widget.product.id,
      );
    }

    setState(() {
      _isCheckingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        await favoritesProvider.addToFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
      } else {
        await favoritesProvider.removeFromFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite; // revert if error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites: $e')),
      );
    }
  }

  void _shareProduct() {
    Share.share(
      'Check out this product: ${widget.product.name} - ${widget.product.formattedPrice}',
      subject: 'BabyShopHub Product',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: widget.product),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: widget.product.firstImage.isNotEmpty
                      ? Image.network(widget.product.firstImage,
                      fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50, color: Colors.grey[400]),
                ),

                // Product Details
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.category,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // Price and Rating
                      Row(
                        children: [
                          Text(
                            widget.product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          Text(
                            widget.product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Add to Cart Button
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final authProvider =
                          Provider.of<AuthProvider>(context);
                          final isInCart =
                          cartProvider.isInCart(widget.product.id);

                          return AppButton(
                            onPressed: () {
                              if (authProvider.currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                    Text('Please login to add to cart'),
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
                                  SnackBar(
                                    content: Text(
                                        'Added ${widget.product.name} to cart'),
                                  ),
                                );
                              }
                            },
                            text: isInCart ? 'View Cart' : 'Add to Cart',
                            width: double.infinity,
                            variant: isInCart ? 'outline' : 'primary',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ❤️ Favorite button
            if (widget.showFavoriteButton && !_isCheckingFavorite)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),

            // 🔗 Share button
            if (widget.showFavoriteButton)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: _shareProduct,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

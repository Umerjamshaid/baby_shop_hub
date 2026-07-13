import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/common/product_image_view.dart';
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
  bool _descriptionExpanded = false;
  String? _selectedSize;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) {
      _selectedSize = widget.product.sizes!.first;
    }
    if (widget.product.colors != null && widget.product.colors!.isNotEmpty) {
      _selectedColor = widget.product.colors!.first;
    }
  }

  List<String> get _images {
    final urls = widget.product.imageUrls ?? [];
    if (urls.isNotEmpty) return urls;
    return [widget.product.firstImage];
  }

  Future<bool> _isFavorite(FavoritesProvider favoritesProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return false;
    return favoritesProvider.isProductInFavorites(user.id, widget.product.id);
  }

  Future<void> _toggleFavorite(FavoritesProvider favoritesProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      _showLoginDialog();
      return;
    }

    final currentlyFavorite = await _isFavorite(favoritesProvider);

    if (!mounted) return;

    if (currentlyFavorite) {
      await favoritesProvider.removeFromFavorites(user.id, widget.product.id);
      _showSnack('Removed from favorites');
    } else {
      await favoritesProvider.addToFavorites(user.id, widget.product.id);
      _showSnack('Added to favorites');
    }

    if (mounted) setState(() {});
  }

  void _shareProduct() {
    final product = widget.product;
    Share.share(
      '${product.name}\n${product.formattedPrice}\n\n${product.description}',
      subject: 'BabyShopHub: ${product.name}',
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Login required'),
        content: const Text('Please login to continue shopping.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _addToCart(CartProvider cartProvider, AuthProvider authProvider) {
    final user = authProvider.currentUser;

    if (user == null) {
      _showLoginDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    cartProvider.addToCart(user.id, widget.product, quantity: _quantity);
    _showSnack('Added to shopping bag');
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: widget.product.category.toUpperCase(),
              onBack: () => Navigator.pop(context),
              onShare: _shareProduct,
              favoriteBuilder: Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, _) {
                  return FutureBuilder<bool>(
                    future: _isFavorite(favoritesProvider),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
                      return _CircleButton(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xffFF6B6B) : null,
                        onTap: () => _toggleFavorite(favoritesProvider),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ImageCarousel(
                      product: widget.product,
                      images: _images,
                      currentIndex: _currentImageIndex,
                      onChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    const SizedBox(height: 26),
                    _ProductInfo(
                      product: widget.product,
                      expanded: _descriptionExpanded,
                      onToggleDescription: () {
                        setState(() {
                          _descriptionExpanded = !_descriptionExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    if (widget.product.colors != null && widget.product.colors!.isNotEmpty) ...[
                      _ColorSelector(
                        colors: widget.product.colors!,
                        selectedColor: _selectedColor,
                        onSelected: (color) {
                          setState(() => _selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) ...[
                      _SizeSelector(
                        sizes: widget.product.sizes!,
                        selectedSize: _selectedSize,
                        onSelected: (size) {
                          setState(() => _selectedSize = size);
                        },
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (widget.product.inStock)
                      _QuantitySelector(
                        quantity: _quantity,
                        maxQuantity: widget.product.stock,
                        onDecrease: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        onIncrease: () {
                          if (_quantity < widget.product.stock) {
                            setState(() => _quantity++);
                          }
                        },
                      ),
                    const SizedBox(height: 22),
                    _DetailsCard(product: widget.product),
                    const SizedBox(height: 22),
                    _ReviewsPreview(product: widget.product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.product.inStock
          ? _BottomCartBar(
              total: (widget.product.price * (1 - (widget.product.discountPercentage ?? 0) / 100)) * _quantity,
              onAdd: () => _addToCart(cartProvider, authProvider),
            )
          : const _OutOfStockBar(),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final Widget favoriteBuilder;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.favoriteBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff202020),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _CircleButton(icon: Icons.ios_share_rounded, onTap: onShare),
          const SizedBox(width: 10),
          favoriteBuilder,
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? const Color(0xff202020)),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final Product product;
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _ImageCarousel({
    required this.product,
    required this.images,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 345,
          child: PageView.builder(
            itemCount: images.length,
            controller: PageController(viewportFraction: 0.86),
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(
                  right: 12,
                  top: index == currentIndex ? 0 : 16,
                  bottom: index == currentIndex ? 0 : 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffF0F2EF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: ProductImageView(
                    imagePath: images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final selected = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff202020)
                      : const Color(0xffD8D8D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  final bool expanded;
  final VoidCallback onToggleDescription;

  const _ProductInfo({
    required this.product,
    required this.expanded,
    required this.onToggleDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              product.formattedPrice,
              style: const TextStyle(
                color: Color(0xffB86B43),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (product.isOnSale) ...[
              const SizedBox(width: 10),
              Text(
                product.formattedOriginalPrice ?? '',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SAVE ${product.discountPercentage!.toInt()}%',
                  style: const TextStyle(
                    color: Color(0xffFF6B6B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.name.toUpperCase(),
          style: const TextStyle(
            color: Color(0xff202020),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.isOnSale) const _InfoPill('SALE'),
            if (product.isFeatured == true) const _InfoPill('FEATURED'),
            if (product.isOrganic == true)
              const _InfoPill(
                'ORGANIC',
                color: Color(0xff2E7D32),
                backgroundColor: Color(0xffE8F5E9),
              ),
            if (product.isEcoFriendly == true)
              const _InfoPill(
                'ECO-FRIENDLY',
                color: Color(0xff1B5E20),
                backgroundColor: Color(0xffC8E6C9),
              ),
            if ((product.brand ?? '').isNotEmpty) _InfoPill(product.brand!),
            if ((product.ageRange ?? '').isNotEmpty)
              _InfoPill(product.ageRange!),
            _InfoPill(product.inStock ? 'IN STOCK' : 'OUT OF STOCK'),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text(
              'Detail',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xff202020),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onToggleDescription,
              borderRadius: BorderRadius.circular(999),
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xffB86B43),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          product.description.isEmpty
              ? 'A carefully selected baby product designed for everyday comfort, safety, and style.'
              : product.description,
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;

  const _InfoPill(
    this.text, {
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = text == 'SALE';
    final bg = backgroundColor ?? (isSale ? const Color(0xff202020) : Colors.white);
    final fg = color ?? (isSale ? Colors.white : const Color(0xff202020));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: backgroundColor != null ? Colors.transparent : const Color(0xffECECEC),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantitySelector({
    required this.quantity,
    required this.maxQuantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(icon: Icons.remove_rounded, onTap: onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: quantity < maxQuantity ? onIncrease : () {},
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xffF3F3F3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Product product;

  const _DetailsCard({required this.product});

  String? _formatDimensions(Product p) {
    if (p.length == null && p.width == null && p.height == null) return null;
    final parts = <String>[];
    if (p.length != null && p.length! > 0) parts.add('${p.length}L');
    if (p.width != null && p.width! > 0) parts.add('${p.width}W');
    if (p.height != null && p.height! > 0) parts.add('${p.height}H');
    if (parts.isEmpty) return null;
    return '${parts.join(" x ")} cm';
  }

  @override
  Widget build(BuildContext context) {
    final dims = _formatDimensions(product);
    final details = <MapEntry<String, String>>[
      MapEntry('Category', product.category),
      if ((product.brand ?? '').isNotEmpty) MapEntry('Brand', product.brand!),
      if ((product.ageRange ?? '').isNotEmpty)
        MapEntry('Age', product.ageRange!),
      if ((product.materials ?? []).isNotEmpty)
        MapEntry('Material', product.materials!.join(', ')),
      if (product.weight != null && product.weight! > 0)
        MapEntry('Weight', '${product.weight} kg'),
      if (dims != null) MapEntry('Dimensions', dims),
      if ((product.sku ?? '').isNotEmpty) MapEntry('SKU', product.sku!),
      if ((product.warranty ?? '').isNotEmpty) MapEntry('Warranty', product.warranty!),
      if ((product.originCountry ?? '').isNotEmpty)
        MapEntry('Origin Country', product.originCountry!),
      MapEntry(
        'Stock',
        product.inStock ? '${product.stock} available' : 'Out of stock',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xff202020),
            ),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.key,
                      style: const TextStyle(
                        color: Color(0xff8A8A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xff202020),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (product.tags != null && product.tags!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xffECECEC), height: 1),
            const SizedBox(height: 14),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xff202020),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: product.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Color(0xff666666),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  final Product product;

  const _ReviewsPreview({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff202020),
                  ),
                ),
              ),
              if ((product.rating ?? 0) > 0) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xffF5B84B),
                ),
                const SizedBox(width: 4),
                Text(
                  (product.rating ?? 0).toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ReviewsList(productId: product.id, showHeader: false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewScreen(product: product),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write a review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff202020),
                side: const BorderSide(color: Color(0xffE6E6E6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCartBar extends StatelessWidget {
  final double total;
  final VoidCallback onAdd;

  const _BottomCartBar({required this.total, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xffFAFAFA),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.shopping_bag_outlined, size: 20),
          label: Text(
            'ADD TO SHOPPING BAG   •   \$${total.toStringAsFixed(2)}',
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutOfStockBar extends StatelessWidget {
  const _OutOfStockBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: const Color(0xffFAFAFA),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffE8E8E8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'OUT OF STOCK',
            style: TextStyle(
              color: Color(0xff777777),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;
  final ValueChanged<String> onSelected;

  const _ColorSelector({
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  Color _getColorFromName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'red': return const Color(0xffFF3B30);
      case 'blue': return const Color(0xff007AFF);
      case 'green': return const Color(0xff34C759);
      case 'yellow': return const Color(0xffFFCC00);
      case 'black': return const Color(0xff1C1C1E);
      case 'white': return const Color(0xffFFFFFF);
      case 'gray': return const Color(0xff8E8E93);
      case 'grey': return const Color(0xff8E8E93);
      case 'pink': return const Color(0xffFF2D55);
      case 'purple': return const Color(0xffAF52DE);
      case 'orange': return const Color(0xffFF9500);
      case 'brown': return const Color(0xffA2845E);
      default: return const Color(0xffAEAEB2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xff202020),
              ),
            ),
            if (selectedColor != null) ...[
              const SizedBox(width: 8),
              Text(
                selectedColor!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff8A8A8A),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final colorName = colors[index];
              final isSelected = colorName == selectedColor;
              final colorVal = _getColorFromName(colorName);
              final isWhite = colorVal == Colors.white;

              return GestureDetector(
                onTap: () => onSelected(colorName),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorVal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xff202020)
                          : isWhite
                              ? const Color(0xffECECEC)
                              : Colors.transparent,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: colorVal.computeLuminance() > 0.5
                              ? const Color(0xff202020)
                              : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final ValueChanged<String> onSelected;

  const _SizeSelector({
    required this.sizes,
    required this.selectedSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Size',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xff202020),
              ),
            ),
            if (selectedSize != null) ...[
              const SizedBox(width: 8),
              Text(
                selectedSize!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff8A8A8A),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sizes.length,
            itemBuilder: (context, index) {
              final sizeName = sizes[index];
              final isSelected = sizeName == selectedSize;

              return GestureDetector(
                onTap: () => onSelected(sizeName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 12),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff202020) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xff202020)
                          : const Color(0xffECECEC),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    sizeName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xff202020),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

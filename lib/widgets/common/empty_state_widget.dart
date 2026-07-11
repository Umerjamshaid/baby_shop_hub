import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String assetPath;
  final VoidCallback? onAction;
  final String actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.assetPath = 'assets/images/empty.png',
    this.onAction,
    this.actionText = 'Explore Products',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use existing image or fallback to icon
            _buildImageWidget(),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onAction != null)
              ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Try to use existing image, fallback to icon if asset doesn't exist
    try {
      return Image.asset(
        assetPath,
        width: 150,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      );
    } catch (e) {
      return _buildFallbackIcon();
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(75),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 60,
        color: Colors.grey,
      ),
    );
  }
}

class EmptyCartWidget extends StatelessWidget {
  final VoidCallback onShopNow;

  const EmptyCartWidget({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Your Cart is Empty',
      message: 'Looks like you haven\'t added any items to your cart yet.',
      assetPath: 'assets/images/empty_cart.png',
      onAction: onShopNow,
      actionText: 'Shop Now',
    );
  }
}

class EmptyOrdersWidget extends StatelessWidget {
  final VoidCallback onShopNow;

  const EmptyOrdersWidget({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Orders Yet',
      message:
          'You haven\'t placed any orders yet. Start shopping to see your orders here.',
      assetPath: 'assets/images/empty_orders.png',
      onAction: onShopNow,
      actionText: 'Start Shopping',
    );
  }
}

class EmptyFavoritesWidget extends StatelessWidget {
  final VoidCallback onBrowse;

  const EmptyFavoritesWidget({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Favorites Yet',
      message: 'You haven\'t added any products to your favorites yet.',
      assetPath: 'assets/images/empty_favorites.png',
      onAction: onBrowse,
      actionText: 'Browse Products',
    );
  }
}

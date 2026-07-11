import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class ProductImageView extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const ProductImageView({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return placeholder ?? _buildPlaceholder();
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? _buildPlaceholder(),
      );
    }

    return placeholder ?? _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

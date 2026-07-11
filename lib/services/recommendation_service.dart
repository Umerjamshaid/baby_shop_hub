import 'dart:math';
import '../models/product_model.dart';

/// Recommendation engine that provides personalized product suggestions
/// based on user behavior, product attributes, and collaborative filtering
class RecommendationService {
  // Singleton pattern
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // Track user interactions
  final Map<String, int> _productViews = {};
  final Map<String, int> _categoryViews = {};
  final Set<String> _cartItems = {};
  final Set<String> _favorites = {};

  /// Track when user views a product
  void trackProductView(Product product) {
    _productViews[product.id] = (_productViews[product.id] ?? 0) + 1;
    _categoryViews[product.category] = (_categoryViews[product.category] ?? 0) + 1;
  }

  /// Track when user adds to cart
  void trackAddToCart(String productId) {
    _cartItems.add(productId);
  }

  /// Track when user favorites a product
  void trackFavorite(String productId) {
    _favorites.add(productId);
  }

  /// Get recommended products based on user behavior
  List<Product> getRecommendations({
    required List<Product> allProducts,
    Product? currentProduct,
    int limit = 10,
  }) {
    if (allProducts.isEmpty) return [];

    final scoredProducts = <Product, double>{};

    for (final product in allProducts) {
      // Skip current product if provided
      if (currentProduct != null && product.id == currentProduct.id) {
        continue;
      }

      double score = 0.0;

      // 1. Category affinity (40% weight)
      if (currentProduct != null && product.category == currentProduct.category) {
        score += 40.0;
      } else if (_categoryViews.containsKey(product.category)) {
        score += (_categoryViews[product.category]! * 5.0).clamp(0, 30);
      }

      // 2. View history (20% weight)
      if (_productViews.containsKey(product.id)) {
        score += (_productViews[product.id]! * 4.0).clamp(0, 20);
      }

      // 3. Favorites boost (15% weight)
      if (_favorites.contains(product.id)) {
        score += 15.0;
      }

      // 4. Cart items boost (10% weight)
      if (_cartItems.contains(product.id)) {
        score += 10.0;
      }

      // 5. Product quality signals (15% weight)
      if (product.rating != null && product.rating! >= 4.0) {
        score += (product.rating! - 3.0) * 5.0;
      }
      if (product.isFeatured == true) {
        score += 5.0;
      }
      if (product.isOnSale) {
        score += 3.0;
      }

      // 6. Price similarity (if current product exists)
      if (currentProduct != null) {
        final priceDiff = (product.price - currentProduct.price).abs();
        final priceRange = currentProduct.price * 0.5;
        if (priceDiff <= priceRange) {
          score += 5.0 * (1 - (priceDiff / priceRange));
        }
      }

      // 7. Brand affinity (if current product has brand)
      if (currentProduct?.brand != null && 
          product.brand == currentProduct?.brand) {
        score += 8.0;
      }

      // 8. Age range compatibility
      if (currentProduct?.ageRange != null && 
          product.ageRange == currentProduct?.ageRange) {
        score += 5.0;
      }

      scoredProducts[product] = score;
    }

    // Sort by score and return top N
    final sortedProducts = scoredProducts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProducts
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  /// Get "You May Also Like" recommendations
  List<Product> getRelatedProducts({
    required Product product,
    required List<Product> allProducts,
    int limit = 6,
  }) {
    return getRecommendations(
      allProducts: allProducts,
      currentProduct: product,
      limit: limit,
    );
  }

  /// Get personalized homepage recommendations
  List<Product> getPersonalizedFeed({
    required List<Product> allProducts,
    int limit = 20,
  }) {
    // If user has no history, return popular/featured products
    if (_productViews.isEmpty && _categoryViews.isEmpty) {
      final featured = allProducts.where((p) => p.isFeatured == true).toList();
      final highRated = allProducts.where((p) => (p.rating ?? 0) >= 4.0).toList();
      final combined = {...featured, ...highRated}.toList();
      combined.shuffle(Random());
      return combined.take(limit).toList();
    }

    return getRecommendations(
      allProducts: allProducts,
      limit: limit,
    );
  }

  /// Get trending products (most viewed recently)
  List<Product> getTrendingProducts({
    required List<Product> allProducts,
    int limit = 10,
  }) {
    final productScores = <Product, int>{};

    for (final product in allProducts) {
      productScores[product] = _productViews[product.id] ?? 0;
    }

    final sorted = productScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get products similar to user's favorites
  List<Product> getSimilarToFavorites({
    required List<Product> allProducts,
    int limit = 10,
  }) {
    if (_favorites.isEmpty) return [];

    final favoriteProducts = allProducts
        .where((p) => _favorites.contains(p.id))
        .toList();

    if (favoriteProducts.isEmpty) return [];

    final recommendations = <Product>{};
    
    for (final favorite in favoriteProducts) {
      final similar = getRelatedProducts(
        product: favorite,
        allProducts: allProducts,
        limit: 3,
      );
      recommendations.addAll(similar);
    }

    return recommendations.take(limit).toList();
  }

  /// Clear all tracking data (for logout)
  void clearHistory() {
    _productViews.clear();
    _categoryViews.clear();
    _cartItems.clear();
    _favorites.clear();
  }
}

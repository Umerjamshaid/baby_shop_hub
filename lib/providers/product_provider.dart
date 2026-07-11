import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../services/product_service.dart';
import '../services/recommendation_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final RecommendationService _recommendationService = RecommendationService();

  List<Product> _allProducts = [];
  List<Product> _featuredProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _recommendedProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // ✅ Infinite scrolling pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // ✅ Track active filters/search
  SearchFilters _currentFilters = SearchFilters();
  String? _currentCategory;
  String? _currentSearchQuery;

  List<Product> get allProducts => _allProducts;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get filteredProducts => _filteredProducts;
  List<Product> get recommendedProducts => _recommendedProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String? get error => _error;
  SearchFilters get currentFilters => _currentFilters;
  String? get currentCategory => _currentCategory;
  String? get currentSearchQuery => _currentSearchQuery;

  // 🔹 Load products with filters
  Future<void> loadProductsWithFilters(SearchFilters filters) async {
    _isLoading = true;
    _error = null;
    _currentFilters = filters;
    _resetPagination();
    notifyListeners();

    try {
      _allProducts = await _productService.getProducts(filters: filters);
      // Show only first page initially
      _filteredProducts = _allProducts.take(_pageSize).toList();
      _isLoading = false;
      await loadRecommendations(); // Load recommendations after products
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Load all products
  Future<void> loadAllProducts() async {
    _isLoading = true;
    _error = null;
    _currentCategory = null;
    _currentSearchQuery = null;
    _currentFilters = SearchFilters(); // Reset filters completely
    _resetPagination();
    notifyListeners();

    try {
      _allProducts = await _productService
          .getAllProducts(); // Use getAllProducts to get everything
      // Show only first page initially
      _filteredProducts = _allProducts.take(_pageSize).toList();
      _isLoading = false;
      await loadRecommendations(); // Load recommendations after products
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Load featured products
  Future<void> loadFeaturedProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Search products
  Future<void> searchProducts(String query) async {
    _currentSearchQuery = query;
    _currentCategory = null;
    await loadProductsWithFilters(SearchFilters(query: query));
  }

  // 🔹 Filter products by category
  Future<void> filterProductsByCategory(String category) async {
    if (category == 'All') {
      await loadAllProducts();
    } else {
      _currentCategory = category;
      _currentSearchQuery = null;
      await loadProductsWithFilters(SearchFilters(category: category));
    }
  }

  // 🔹 Sort products
  void sortProducts(String sortBy) {
    List<Product> sortedProducts = List.from(_filteredProducts);

    switch (sortBy) {
      case 'price_low':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sortedProducts.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'newest':
        sortedProducts.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'discount':
        sortedProducts.sort(
          (a, b) =>
              (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0),
        );
        break;
    }

    _filteredProducts = sortedProducts;
    notifyListeners();
  }

  // 🔹 Clear filters/search
  void clearFilters() {
    _currentCategory = null;
    _currentSearchQuery = null;
    _currentFilters = SearchFilters();
    _resetPagination();
    // Don't just reset filteredProducts, actually reload all products
    loadAllProducts();
  }

  // 🔹 Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 🔹 Extra helpers from ProductService
  Future<List<String>> getBrands() => _productService.getBrands();
  Future<List<String>> getAgeRanges() => _productService.getAgeRanges();
  Future<List<String>> getSizes() => _productService.getSizes();
  Future<List<String>> getColors() => _productService.getColors();
  Future<List<String>> getSearchSuggestions(String query) =>
      _productService.getSearchSuggestions(query);
  Future<List<String>> getPopularSearches() =>
      _productService.getPopularSearches();

  // 🔹 Infinite Scrolling - Load more products
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Since ProductService doesn't support pagination,
      // we'll implement client-side pagination
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;

      if (startIndex >= _allProducts.length) {
        _hasMoreData = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      _currentPage++;
      
      // Simulate loading delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      final newProducts = _allProducts.skip(startIndex).take(_pageSize).toList();
      
      if (newProducts.length < _pageSize) {
        _hasMoreData = false;
      }

      _filteredProducts.addAll(newProducts);
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      _currentPage--; // Rollback page increment on error
      notifyListeners();
    }
  }

  // 🔹 Reset pagination
  void _resetPagination() {
    _currentPage = 1;
    _hasMoreData = true;
  }

  // 🔹 Load personalized recommendations
  Future<void> loadRecommendations() async {
    try {
      _recommendedProducts = _recommendationService.getPersonalizedFeed(
        allProducts: _allProducts,
        limit: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  // 🔹 Get related products for a specific product
  List<Product> getRelatedProducts(Product product, {int limit = 6}) {
    return _recommendationService.getRelatedProducts(
      product: product,
      allProducts: _allProducts,
      limit: limit,
    );
  }

  // 🔹 Track product view for recommendations
  void trackProductView(Product product) {
    _recommendationService.trackProductView(product);
    loadRecommendations(); // Refresh recommendations
  }

  // 🔹 Track add to cart for recommendations
  void trackAddToCart(String productId) {
    _recommendationService.trackAddToCart(productId);
  }

  // 🔹 Track favorite for recommendations
  void trackFavorite(String productId) {
    _recommendationService.trackFavorite(productId);
  }
}

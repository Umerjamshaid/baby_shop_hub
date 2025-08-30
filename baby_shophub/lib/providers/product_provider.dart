import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  List<Product> _featuredProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  SearchFilters _currentFilters = SearchFilters();

  List<Product> get allProducts => _allProducts;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SearchFilters get currentFilters => _currentFilters;

  // Load all products with optional filters
  Future<void> loadProductsWithFilters(SearchFilters filters) async {
    _isLoading = true;
    _error = null;
    _currentFilters = filters;
    notifyListeners();

    try {
      _allProducts = await _productService.getProducts(filters: filters);
      _filteredProducts = _allProducts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all products
  Future<void> loadAllProducts() async {
    await loadProductsWithFilters(SearchFilters());
  }

  // Load featured products
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

  // Search products
  Future<void> searchProducts(String query) async {
    await loadProductsWithFilters(
      SearchFilters(query: query),
    );
  }

  // Filter products by category
  Future<void> filterProductsByCategory(String category) async {
    await loadProductsWithFilters(
      SearchFilters(category: category),
    );
  }

  // ✅ Sort products
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
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'discount':
        sortedProducts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      default: // relevance
      // No sorting or default sorting
        break;
    }

    _filteredProducts = sortedProducts;
    notifyListeners();
  }

  // Get brands
  Future<List<String>> getBrands() async {
    try {
      return await _productService.getBrands();
    } catch (e) {
      return [];
    }
  }

  // Get age ranges
  Future<List<String>> getAgeRanges() async {
    try {
      return await _productService.getAgeRanges();
    } catch (e) {
      return [];
    }
  }

  // Get sizes
  Future<List<String>> getSizes() async {
    try {
      return await _productService.getSizes();
    } catch (e) {
      return [];
    }
  }

  // Get colors
  Future<List<String>> getColors() async {
    try {
      return await _productService.getColors();
    } catch (e) {
      return [];
    }
  }

  // Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      return await _productService.getSearchSuggestions(query);
    } catch (e) {
      return [];
    }
  }

  // Get popular searches
  Future<List<String>> getPopularSearches() async {
    try {
      return await _productService.getPopularSearches();
    } catch (e) {
      return [];
    }
  }

  // Clear filters
  void clearFilters() {
    _filteredProducts = _allProducts;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

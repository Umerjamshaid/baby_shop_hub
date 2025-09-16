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

  // ✅ Track active filters/search
  SearchFilters _currentFilters = SearchFilters();
  String? _currentCategory;
  String? _currentSearchQuery;

  List<Product> get allProducts => _allProducts;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SearchFilters get currentFilters => _currentFilters;
  String? get currentCategory => _currentCategory;
  String? get currentSearchQuery => _currentSearchQuery;

  // 🔹 Load products with filters
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

  // 🔹 Load all products
  Future<void> loadAllProducts() async {
    _currentCategory = null;
    _currentSearchQuery = null;
    await loadProductsWithFilters(SearchFilters());
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
    }

    _filteredProducts = sortedProducts;
    notifyListeners();
  }

  // 🔹 Clear filters/search
  void clearFilters() {
    _filteredProducts = _allProducts;
    _currentCategory = null;
    _currentSearchQuery = null;
    _currentFilters = SearchFilters();
    notifyListeners();
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
  Future<List<String>> getSearchSuggestions(String query) => _productService.getSearchSuggestions(query);
  Future<List<String>> getPopularSearches() => _productService.getPopularSearches();
}

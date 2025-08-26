import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  List<Product> _featuredProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get allProducts => _allProducts;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all products
  Future<void> loadAllProducts() async {
    _isLoading = true;
    _error = null;

    try {
      _allProducts = await _productService.getAllProducts();
      _filteredProducts = _allProducts;
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    _isLoading = true;
    _error = null;

    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
  }

  // Filter products by category
  void filterProductsByCategory(String category) {
    if (category == 'All') {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((product) => product.category == category)
          .toList();
    }
    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _filteredProducts = await _productService.searchProducts(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sort products (NEW METHOD)
  void sortProducts(String sortBy) {
    List<Product> sortedProducts = List.from(_filteredProducts);

    switch (sortBy) {
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sortedProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    _filteredProducts = sortedProducts;
    notifyListeners();
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
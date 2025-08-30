import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../utils/constants.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get all products with optional filters
  Future<List<Product>> getProducts({SearchFilters? filters}) async {
    try {
      Query query = _firestore.collection(AppConstants.productsCollection);

      // Firestore filters
      if (filters != null) {
        if (filters.category != 'All') {
          query = query.where('category', isEqualTo: filters.category);
        }
        if (filters.minPrice > 0 || filters.maxPrice < 1000) {
          query = query.where('price', isGreaterThanOrEqualTo: filters.minPrice);
          query = query.where('price', isLessThanOrEqualTo: filters.maxPrice);
        }
        if (filters.minRating > 0) {
          query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
        }
        if (filters.brands.isNotEmpty) {
          query = query.where('brand', whereIn: filters.brands);
        }
        if (filters.ageRanges.isNotEmpty) {
          query = query.where('ageRange', whereIn: filters.ageRanges);
        }
        if (filters.inStockOnly) {
          query = query.where('stock', isGreaterThan: 0);
        }
        if (filters.ecoFriendlyOnly) {
          query = query.where('isEcoFriendly', isEqualTo: true);
        }
        if (filters.organicOnly) {
          query = query.where('isOrganic', isEqualTo: true);
        }
        if (filters.onSaleOnly) {
          query = query.where('discountPercentage', isGreaterThan: 0);
        }
      }

      QuerySnapshot snapshot = await query.get();

      List<Product> products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      if (filters != null) {
        products = _applyClientSideFilters(products, filters);
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // ✅ Backwards compatibility: simple get all products
  Future<List<Product>> getAllProducts() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(AppConstants.productsCollection).get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // ✅ Featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isFeatured', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // ✅ Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch category products: $e');
    }
  }

  // ✅ Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // ✅ Backwards compatibility: Simple searchProducts
  Future<List<Product>> searchProducts(String query) async {
    try {
      final allProducts = await getAllProducts();
      return allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase()) ||
            product.brand.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // ✅ Apply client-side filters
  List<Product> _applyClientSideFilters(
      List<Product> products, SearchFilters filters) {
    var filteredProducts = products;

    if (filters.query.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(filters.query.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(filters.query.toLowerCase()) ||
            product.brand.toLowerCase().contains(filters.query.toLowerCase()) ||
            product.category
                .toLowerCase()
                .contains(filters.query.toLowerCase());
      }).toList();
    }

    if (filters.sizes.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.sizes != null &&
            product.sizes!.any((size) => filters.sizes.contains(size));
      }).toList();
    }

    if (filters.colors.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.colors != null &&
            product.colors!.any((color) => filters.colors.contains(color));
      }).toList();
    }

    return _sortProducts(filteredProducts, filters.sortBy);
  }

  // ✅ Sorting helper
  List<Product> _sortProducts(List<Product> products, String sortBy) {
    switch (sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'discount':
        products.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      default:
        break;
    }
    return products;
  }

  // ✅ Unique brands
  Future<List<String>> getBrands() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(AppConstants.productsCollection).get();

      Set<String> brands = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['brand'] != null) brands.add(data['brand']);
      }

      return brands.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch brands: $e');
    }
  }

  // ✅ Unique age ranges
  Future<List<String>> getAgeRanges() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(AppConstants.productsCollection).get();

      Set<String> ageRanges = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['ageRange'] != null) ageRanges.add(data['ageRange']);
      }

      return ageRanges.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch age ranges: $e');
    }
  }

  // ✅ Unique sizes
  Future<List<String>> getSizes() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(AppConstants.productsCollection).get();

      Set<String> sizes = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['sizes'] != null) {
          final List<dynamic> productSizes = data['sizes'];
          for (var size in productSizes) {
            sizes.add(size);
          }
        }
      }

      return sizes.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch sizes: $e');
    }
  }

  // ✅ Unique colors
  Future<List<String>> getColors() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(AppConstants.productsCollection).get();

      Set<String> colors = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['colors'] != null) {
          final List<dynamic> productColors = data['colors'];
          for (var color in productColors) {
            colors.add(color);
          }
        }
      }

      return colors.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch colors: $e');
    }
  }

  // ✅ Search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      Set<String> suggestions = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        suggestions.add(data['name']);
        if (data['brand'] != null) suggestions.add(data['brand']);
        if (data['category'] != null) suggestions.add(data['category']);
      }

      return suggestions.toList();
    } catch (e) {
      throw Exception('Failed to fetch search suggestions: $e');
    }
  }

  // ✅ Popular searches (static for now)
  Future<List<String>> getPopularSearches() async {
    return [
      'Diapers',
      'Baby Food',
      'Strollers',
      'Onesies',
      'Baby Toys',
      'Baby Bottles',
      'Baby Car Seat',
      'Baby Monitor',
      'Baby Blanket',
      'Baby Shampoo',
    ];
  }
}

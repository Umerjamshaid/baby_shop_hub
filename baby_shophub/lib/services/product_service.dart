import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:string_similarity/string_similarity.dart';
import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../utils/constants.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Add product
  Future<void> addProduct(Product product) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .set(product.toMap());

      // Update the product count in the category
      await _updateCategoryProductCount(product.category);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // ✅ Update product
  Future<void> updateProduct(Product product) async {
    try {
      // Get the old product to check if category changed
      final oldProductDoc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .get();

      if (oldProductDoc.exists) {
        final oldProduct = Product.fromMap(
          oldProductDoc.data() as Map<String, dynamic>,
          oldProductDoc.id,
        );

        // If category changed, update both old and new category counts
        if (oldProduct.category != product.category) {
          await _updateCategoryProductCount(oldProduct.category);
          await _updateCategoryProductCount(product.category);
        }
      }

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // ✅ Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get the product to know which category to update
      final productDoc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (productDoc.exists) {
        final product = Product.fromMap(
          productDoc.data() as Map<String, dynamic>,
          productDoc.id,
        );

        // Delete the product
        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .delete();

        // Update the product count in the category
        await _updateCategoryProductCount(product.category);
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ✅ Helper: Update product count in a category
  Future<void> _updateCategoryProductCount(String categoryName) async {
    try {
      // Get all products in this category
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: categoryName)
          .get();

      final productCount = productsSnapshot.docs.length;

      // Find the category document by name
      final categoryQuery = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('name', isEqualTo: categoryName)
          .get();

      if (categoryQuery.docs.isNotEmpty) {
        // ✅ Update existing category
        final categoryDoc = categoryQuery.docs.first;
        await categoryDoc.reference.update({'productCount': productCount});
      } else {
        // ✅ Create category if it doesn’t exist
        final newCategoryRef = _firestore
            .collection(AppConstants.categoriesCollection)
            .doc();

        await newCategoryRef.set({
          'id': newCategoryRef.id,
          'name': categoryName,
          'imageUrl': '', // can be updated later
          'productCount': productCount,
          'createdAt': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error updating category product count: $e');
    }
  }

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
          query = query.where(
            'price',
            isGreaterThanOrEqualTo: filters.minPrice,
          );
          query = query.where('price', isLessThanOrEqualTo: filters.maxPrice);
        }
        if (filters.minRating > 0) {
          query = query.where(
            'rating',
            isGreaterThanOrEqualTo: filters.minRating,
          );
        }
        if (filters.brands.isNotEmpty) {
          query = query.where('brand', whereIn: filters.brands);
        }
        if (filters.ageRanges.isNotEmpty) {
          query = query.where('ageRange', whereIn: filters.ageRanges);
        }
        if (filters.inStockOnly) {
          query = query.where('stockQuantity', isGreaterThan: 0);
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
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
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
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
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
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
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
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
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
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // ✅ Smart Search with Scoring & Fuzzy Matching
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final allProducts = await getAllProducts();
      final normalizedQuery = query.toLowerCase();
      
      // Calculate scores
      final scoredProducts = allProducts.map((product) {
        double score = 0;
        
        // 1. Exact matches (High priority)
        if (product.name.toLowerCase() == normalizedQuery) score += 100;
        if (product.brand?.toLowerCase() == normalizedQuery) score += 80;
        if (product.category.toLowerCase() == normalizedQuery) score += 60;
        
        // 2. Contains matches
        if (product.name.toLowerCase().contains(normalizedQuery)) score += 50;
        if (product.brand?.toLowerCase().contains(normalizedQuery) ?? false) score += 40;
        if (product.category.toLowerCase().contains(normalizedQuery)) score += 30;
        if (product.description.toLowerCase().contains(normalizedQuery)) score += 10;
        if (product.tags?.any((t) => t.toLowerCase().contains(normalizedQuery)) ?? false) score += 20;

        // 3. Fuzzy matches (Handle typos)
        // Using basic string similarity if no exact/contains match found
        if (score == 0) {
          final nameSimilarity = product.name.toLowerCase().similarityTo(normalizedQuery);
          if (nameSimilarity > 0.4) score += nameSimilarity * 30;
          
          if (product.brand != null) {
            final brandSimilarity = product.brand!.toLowerCase().similarityTo(normalizedQuery);
            if (brandSimilarity > 0.4) score += brandSimilarity * 20;
          }
        }
        
        return MapEntry(product, score);
      }).toList();

      // Filter and Sort
      final results = scoredProducts
          .where((entry) => entry.value > 5) // Minimum threshold
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Sort by score desc

      return results.map((e) => e.key).toList();
    } catch (e) {
      print('Smart search error: $e');
      return []; // Fallback to empty
    }
  }

  // ✅ Client-side filters (Updated to use smart search if query exists)
  List<Product> _applyClientSideFilters(
    List<Product> products,
    SearchFilters filters,
  ) {
    var filteredProducts = products;

    // Note: If query is present, we assume products are already filtered by searchProducts 
    // or we apply simple filtering here if not coming from smart search.
    // But for consistency with the new searchProducts, we'll use simple contains here 
    // ONLY if the list wasn't already generated by searchProducts.
    // However, usually this method filters a list that might already be search results.
    
    if (filters.query.isNotEmpty) {
       // If we are filtering an arbitrary list, we use simple contains for performance
       // or we could re-run smart scoring but that's expensive.
       // Let's stick to simple contains for post-filtering if needed.
       filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(filters.query.toLowerCase()) ||
            product.description.toLowerCase().contains(filters.query.toLowerCase()) ||
            (product.brand?.toLowerCase().contains(filters.query.toLowerCase()) ?? false) ||
            product.category.toLowerCase().contains(filters.query.toLowerCase());
      }).toList();
    }

    if (filters.sizes.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.sizes?.any((size) => filters.sizes.contains(size)) ??
            false;
      }).toList();
    }

    if (filters.colors.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.colors?.any((color) => filters.colors.contains(color)) ??
            false;
      }).toList();
    }

    return _sortProducts(filteredProducts, filters.sortBy);
  }

  // ✅ Sorting
  List<Product> _sortProducts(List<Product> products, String sortBy) {
    switch (sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'newest':
        products.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'discount':
        products.sort(
          (a, b) =>
              (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0),
        );
        break;
      default:
        break;
    }
    return products;
  }

  // ✅ Unique brands
  Future<List<String>> getBrands() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

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
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

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
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

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
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

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
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
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
  // ✅ Similar products (Recommendation System)
  Future<List<Product>> getSimilarProducts(Product currentProduct) async {
    try {
      // 1. Get products from the same category
      QuerySnapshot categorySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: currentProduct.category)
          .limit(10) // Fetch a few more to filter
          .get();

      List<Product> similarProducts = categorySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => p.id != currentProduct.id) // Exclude current product
          .toList();

      // 2. (Optional) If not enough, fetch by tags (if tags exist)
      if (similarProducts.length < 5 && (currentProduct.tags?.isNotEmpty ?? false)) {
        QuerySnapshot tagSnapshot = await _firestore
            .collection(AppConstants.productsCollection)
            .where('tags', arrayContainsAny: currentProduct.tags)
            .limit(10)
            .get();
            
        final tagProducts = tagSnapshot.docs
            .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((p) => p.id != currentProduct.id)
            .toList();
            
        // Add unique products
        for (var p in tagProducts) {
          if (!similarProducts.any((existing) => existing.id == p.id)) {
            similarProducts.add(p);
          }
        }
      }

      // 3. Shuffle and limit to 5
      similarProducts.shuffle();
      return similarProducts.take(5).toList();
    } catch (e) {
      print('Error fetching similar products: $e');
      return [];
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../providers/product_provider.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import './product_detail_screen.dart';
import './advanced_search_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  final SearchFilters? searchFilters;

  const ProductsListScreen({
    super.key,
    this.category,
    this.searchQuery,
    this.searchFilters,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _currentSort = 'name';
  bool _isGridView = true;
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();

    _filters = widget.searchFilters ??
        SearchFilters(
          category: widget.category ?? 'All',
          query: widget.searchQuery ?? '',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.loadProductsWithFilters(_filters);
  }

  void _sortProducts(String sortBy) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.sortProducts(sortBy);

    setState(() {
      _currentSort = sortBy;
    });
  }

  String _getScreenTitle() {
    if (_filters.query.isNotEmpty) {
      return 'Search: ${_filters.query}';
    } else if (_filters.category != 'All') {
      return _filters.category;
    } else if (_filters.hasFilters) {
      return 'Filtered Products';
    } else {
      return 'All Products';
    }
  }

  void _triggerNewSearch(String suggestion) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // Update filters with the new search suggestion
    setState(() {
      _filters = SearchFilters(
        category: 'All',
        query: suggestion,
      );
    });

    // Load products with new filters
    productProvider.loadProductsWithFilters(_filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getScreenTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list, size: 22, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvancedSearchScreen(
                    initialCategory: _filters.category,
                  ),
                ),
              );
            },
          ),
          // Grid/List toggle
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isGridView ? Icons.list : Icons.grid_view,
                size: 20,
                color: Colors.black87,
              ),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          const SizedBox(width: 8),
          // Sort menu
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              onSelected: _sortProducts,
              icon: const Icon(Icons.sort, size: 20),
              itemBuilder: (BuildContext context) {
                return [
                  _buildSortOption('name', Icons.sort_by_alpha, 'Sort by Name'),
                  _buildSortOption('price_low', Icons.arrow_upward, 'Price: Low to High'),
                  _buildSortOption('price_high', Icons.arrow_downward, 'Price: High to Low'),
                  _buildSortOption('rating', Icons.star, 'Sort by Rating'),
                ];
              },
            ),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const AppLoadingWidget();
          }

          if (productProvider.error != null) {
            return AppErrorWidget(
              message: productProvider.error!,
              onRetry: _loadProducts,
            );
          }

          final products = productProvider.filteredProducts;

          if (products.isEmpty) {
            return _buildNoResultsState(_filters.query);
          }

          return _isGridView
              ? _buildEnhancedGridView(products)
              : _buildEnhancedListView(products);
        },
      ),
    );
  }

  /// Sort option builder
  PopupMenuItem<String> _buildSortOption(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _currentSort == value
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  /// Enhanced No Results State (merged from both versions)
  Widget _buildNoResultsState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'No products available'
                : 'No results found for "$query"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty
                ? 'Try browsing different categories'
                : 'Try searching with different keywords',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),

          // Suggested searches
          const Text(
            'Try these instead:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['Diapers', 'Toys', 'Clothing', 'Food']
                .map((suggestion) {
              return FilterChip(
                label: Text(suggestion),
                onSelected: (_) {
                  _triggerNewSearch(suggestion);
                },
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action buttons
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvancedSearchScreen(
                    initialCategory: _filters.category,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.filter_list),
            label: const Text('Adjust Filters'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _filters = SearchFilters(category: 'All', query: '');
              });
              _loadProducts();
            },
            child: const Text('Clear Filters & Show All'),
          ),
        ],
      ),
    );
  }

  /// Grid view
  Widget _buildEnhancedGridView(List<Product> products) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return EnhancedProductCard(product: products[index]);
      },
    );
  }

  /// List view
  Widget _buildEnhancedListView(List<Product> products) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return EnhancedProductListCard(product: products[index]);
      },
    );
  }
}

class EnhancedProductCard extends StatelessWidget {
  final Product product;

  const EnhancedProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    product.firstImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
                if (!product.inStock)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(product.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: TextStyle(fontSize: 16, color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                      if (product.inStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            'In Stock',
                            style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedProductListCard extends StatelessWidget {
  final Product product;

  const EnhancedProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                image: DecorationImage(
                  image: NetworkImage(product.firstImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: product.firstImage.isEmpty
                  ? Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 50),
              )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(product.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!product.inStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
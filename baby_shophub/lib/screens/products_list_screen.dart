import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/common/product_card.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import './product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;

  const ProductsListScreen({
    super.key,
    this.category,
    this.searchQuery,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _currentSort = 'name';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (widget.category != null) {
      productProvider.filterProductsByCategory(widget.category!);
    } else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      productProvider.searchProducts(widget.searchQuery!);
    } else {
      productProvider.clearFilters();
    }
  }

  void _sortProducts(String sortBy) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.sortProducts(sortBy); // Use the new method

    setState(() {
      _currentSort = sortBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category ?? widget.searchQuery ?? 'All Products',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _sortProducts,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                const PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
              ];
            },
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.searchQuery != null
                        ? 'No products found for "${widget.searchQuery}"'
                        : 'No products available',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadProducts,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return _isGridView ? _buildGridView(products) : _buildListView(products);
        },
      ),
    );
  }

  Widget _buildGridView(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }

  Widget _buildListView(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductListCard(product: products[index]);
      },
    );
  }
}

// List view variant of product card
class ProductListCard extends StatelessWidget {
  final Product product;

  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                image: DecorationImage(
                  image: NetworkImage(product.firstImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
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
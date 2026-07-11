import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../models/search_filters_model.dart';
import '../../services/product_service.dart';
import '../../services/admin_service.dart';
import 'admin_edit_product_screen.dart';

class EnhancedProductManagementScreen extends StatefulWidget {
  const EnhancedProductManagementScreen({super.key});

  @override
  State<EnhancedProductManagementScreen> createState() =>
      _EnhancedProductManagementScreenState();
}

class _EnhancedProductManagementScreenState
    extends State<EnhancedProductManagementScreen>
    with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final AdminService _adminService = AdminService();

  // State management
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedProducts = {};

  // Filtering and search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SearchFilters _currentFilters = SearchFilters();
  bool _showFilters = false;

  // Sorting
  String _sortBy = 'newest';

  // Bulk operations
  bool _isBulkOperationLoading =
      false; // Used for bulk operations loading state

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _loadProducts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
        _applyFiltersAndSort();
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load products: $e');
    }
  }

  void _applyFiltersAndSort() {
    List<Product> filtered = List.from(_products);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (product.brand?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (product.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            true;
      }).toList();
    }

    // Apply filters
    if (_currentFilters.category != 'All') {
      filtered = filtered
          .where((p) => p.category == _currentFilters.category)
          .toList();
    }
    if (_currentFilters.minPrice > 0) {
      filtered = filtered
          .where((p) => p.price >= _currentFilters.minPrice)
          .toList();
    }
    if (_currentFilters.maxPrice < 10000) {
      filtered = filtered
          .where((p) => p.price <= _currentFilters.maxPrice)
          .toList();
    }
    if (_currentFilters.brands.isNotEmpty) {
      filtered = filtered
          .where((p) => _currentFilters.brands.contains(p.brand))
          .toList();
    }
    if (_currentFilters.inStockOnly) {
      filtered = filtered.where((p) => p.inStock).toList();
    }
    if (_currentFilters.ecoFriendlyOnly) {
      filtered = filtered.where((p) => p.isEcoFriendly == true).toList();
    }
    if (_currentFilters.organicOnly) {
      filtered = filtered.where((p) => p.isOrganic == true).toList();
    }
    if (_currentFilters.onSaleOnly) {
      filtered = filtered.where((p) => p.isOnSale).toList();
    }

    // Apply sorting
    _sortProducts(filtered);

    setState(() => _filteredProducts = filtered);
  }

  void _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_low':
        products.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'stock_high':
        products.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case 'rating':
        products.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'newest':
      default:
        products.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
    }
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
        if (_selectedProducts.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProducts.add(productId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedProducts.length == _filteredProducts.length) {
        _selectedProducts.clear();
        _isSelectionMode = false;
      } else {
        _selectedProducts = _filteredProducts.map((p) => p.id).toSet();
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedProducts.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text(
          'Are you sure you want to delete ${_selectedProducts.length} products? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isBulkOperationLoading = true);
      try {
        await Future.wait(
          _selectedProducts.map((id) => _adminService.deleteProduct(id)),
        );
        _showSuccessSnackBar('Deleted ${_selectedProducts.length} products');
        setState(() {
          _selectedProducts.clear();
          _isSelectionMode = false;
        });
        _loadProducts();
      } catch (e) {
        _showErrorSnackBar('Failed to delete products: $e');
      } finally {
        setState(() => _isBulkOperationLoading = false);
      }
    }
  }

  Future<void> _bulkUpdateStock(int stockChange) async {
    if (_selectedProducts.isEmpty) return;

    setState(() => _isBulkOperationLoading = true);
    try {
      for (final productId in _selectedProducts) {
        final product = _products.firstWhere((p) => p.id == productId);
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          unit: product.unit,
          taxRate: product.taxRate,
          imageUrls: product.imageUrls,
          category: product.category,
          brand: product.brand,
          ageRange: product.ageRange,
          stockQuantity: (product.stockQuantity + stockChange).clamp(0, 99999),
          isService: product.isService,
          isActive: product.isActive,
          rating: product.rating,
          reviewCount: product.reviewCount,
          isFeatured: product.isFeatured,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
          sizes: product.sizes,
          colors: product.colors,
          materials: product.materials,
          isEcoFriendly: product.isEcoFriendly,
          isOrganic: product.isOrganic,
          discountPercentage: product.discountPercentage,
          weight: product.weight,
          length: product.length,
          width: product.width,
          height: product.height,
          sku: product.sku,
          tags: product.tags,
          warranty: product.warranty,
          originCountry: product.originCountry,
        );
        await _productService.updateProduct(updatedProduct);
      }
      _showSuccessSnackBar(
        'Updated stock for ${_selectedProducts.length} products',
      );
      setState(() {
        _selectedProducts.clear();
        _isSelectionMode = false;
      });
      _loadProducts();
    } catch (e) {
      _showErrorSnackBar('Failed to update stock: $e');
    } finally {
      setState(() => _isBulkOperationLoading = false);
    }
  }

  Future<void> _exportProducts() async {
    try {
      final csvData = StringBuffer();
      csvData.writeln('ID,Name,Category,Brand,Price,Stock,SKU,Description');

      for (final product in _filteredProducts) {
        csvData.writeln(
          '"${product.id}","${product.name}","${product.category}","${product.brand}",'
          '${product.price},${product.stockQuantity},"${product.sku ?? ''}","${product.description}"',
        );
      }

      // Copy to clipboard for now (in a real app, you'd save to file)
      await Clipboard.setData(ClipboardData(text: csvData.toString()));
      _showSuccessSnackBar('Product data copied to clipboard');
    } catch (e) {
      _showErrorSnackBar('Failed to export products: $e');
    }
  }

  Future<void> _importProducts() async {
    // For now, show a placeholder since file_picker is not available
    _showErrorSnackBar('Import functionality requires file picker package');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSearchAndFilters(),
                    if (_isSelectionMode) _buildBulkActions(),
                    _buildProductsList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isSelectionMode
            ? '${_selectedProducts.length} selected'
            : 'Product Management',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedProducts.clear();
                  _isSelectionMode = false;
                });
              },
            )
          : null,
      actions: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle filters',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _sortBy = value);
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'name', child: Text('Name A-Z')),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: 'stock_low',
                child: Text('Stock: Low to High'),
              ),
              const PopupMenuItem(
                value: 'stock_high',
                child: Text('Stock: High to Low'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('Highest Rated'),
              ),
            ],
            icon: const Icon(Icons.sort),
            tooltip: 'Sort products',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportProducts();
                  break;
                case 'import':
                  _importProducts();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export CSV')),
              const PopupMenuItem(value: 'import', child: Text('Import CSV')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Select all',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _bulkDelete,
            tooltip: 'Delete selected',
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFiltersAndSort();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFiltersAndSort();
            },
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _currentFilters = _currentFilters.copyWith(
                      minPrice: double.tryParse(value) ?? 0,
                    );
                    _applyFiltersAndSort();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _currentFilters = _currentFilters.copyWith(
                      maxPrice: double.tryParse(value) ?? 10000,
                    );
                    _applyFiltersAndSort();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('In Stock'),
                selected: _currentFilters.inStockOnly,
                onSelected: (selected) {
                  setState(
                    () => _currentFilters = _currentFilters.copyWith(
                      inStockOnly: selected,
                    ),
                  );
                  _applyFiltersAndSort();
                },
              ),
              FilterChip(
                label: const Text('Eco-Friendly'),
                selected: _currentFilters.ecoFriendlyOnly,
                onSelected: (selected) {
                  setState(
                    () => _currentFilters = _currentFilters.copyWith(
                      ecoFriendlyOnly: selected,
                    ),
                  );
                  _applyFiltersAndSort();
                },
              ),
              FilterChip(
                label: const Text('Organic'),
                selected: _currentFilters.organicOnly,
                onSelected: (selected) {
                  setState(
                    () => _currentFilters = _currentFilters.copyWith(
                      organicOnly: selected,
                    ),
                  );
                  _applyFiltersAndSort();
                },
              ),
              FilterChip(
                label: const Text('On Sale'),
                selected: _currentFilters.onSaleOnly,
                onSelected: (selected) {
                  setState(
                    () => _currentFilters = _currentFilters.copyWith(
                      onSaleOnly: selected,
                    ),
                  );
                  _applyFiltersAndSort();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Category:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _currentFilters.category,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Categories'),
                    ),
                    // Add more categories as needed
                  ],
                  onChanged: (value) {
                    setState(
                      () => _currentFilters = _currentFilters.copyWith(
                        category: value ?? 'All',
                      ),
                    );
                    _applyFiltersAndSort();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('${_selectedProducts.length} selected'),
          const Spacer(),
          if (_isBulkOperationLoading)
            const CircularProgressIndicator()
          else ...[
            ElevatedButton.icon(
              onPressed: () => _bulkUpdateStock(10),
              icon: const Icon(Icons.add),
              label: const Text('Add Stock'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _bulkUpdateStock(-10),
              icon: const Icon(Icons.remove),
              label: const Text('Reduce Stock'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _bulkDelete,
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return Container(
        height: 400, // Fixed height to prevent overflow
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Add your first product to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToEditProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWideScreen ? 3 : 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            final isSelected = _selectedProducts.contains(product.id);
            return _buildProductCard(product, isSelected);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSelected) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? Colors.grey.shade900 : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor.withOpacity(.55), cardColor.withOpacity(.35)],
            ),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.withOpacity(.6)
                  : Colors.white.withOpacity(.3),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.blue.withOpacity(.15)
                    : Colors.black.withOpacity(.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleSelection(product.id)
                  : () => _navigateToEditProduct(product),
              onLongPress: () => _toggleSelection(product.id),
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.blue.withOpacity(.15),
              highlightColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with gradient overlay
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            image: product.firstImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(product.firstImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: product.firstImage.isEmpty
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey[300]!,
                                      Colors.grey[100]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: product.firstImage.isEmpty
                              ? Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                )
                              : null,
                        ),
                        // Category badge (TOP LEFT)
                        if (product.category.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        // Stock badge (TOP RIGHT)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.inStock
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.stockQuantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Selection checkbox overlay
                        if (_isSelectionMode)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleSelection(product.id),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content section
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product name
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Price
                          Text(
                            product.formattedPrice,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          // Action buttons
                          if (!_isSelectionMode)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Edit button
                                _glassButton(
                                  icon: Icons.edit_outlined,
                                  color: Colors.blue,
                                  onTap: () => _navigateToEditProduct(product),
                                ),
                                const SizedBox(width: 8),
                                // Delete button
                                _glassButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.red,
                                  onTap: () => _deleteProduct(product.id),
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
          ),
        ),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.3), width: 1),
        ),
        child: Icon(icon, size: 16, color: color.withOpacity(.8)),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToEditProduct,
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  void _navigateToEditProduct([Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditProductScreen(
          product: product,
          onProductSaved: _loadProducts,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteProduct(productId);
        _showSuccessSnackBar('Product deleted successfully');
        _loadProducts();
      } catch (e) {
        _showErrorSnackBar('Failed to delete product: $e');
      }
    }
  }
}

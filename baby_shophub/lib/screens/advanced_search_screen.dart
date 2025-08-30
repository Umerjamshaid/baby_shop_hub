import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../models/search_filters_model.dart';
import '../utils/constants.dart';
import '../widgets/common/app_button.dart';
import 'products_list_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final String? initialCategory;

  const AdvancedSearchScreen({super.key, this.initialCategory});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _minRatingController = TextEditingController();

  late SearchFilters _filters;
  late List<String> _brands;
  late List<String> _ageRanges;
  late List<String> _sizes;
  late List<String> _colors;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      category: widget.initialCategory ?? 'All',
    );
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      _brands = await productProvider.getBrands();
      _ageRanges = await productProvider.getAgeRanges();
      _sizes = await productProvider.getSizes();
      _colors = await productProvider.getColors();
    } catch (e) {
      // Handle error
      _brands = [];
      _ageRanges = [];
      _sizes = [];
      _colors = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        actions: [
          if (_filters.hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSearchForm(),
    );
  }

  Widget _buildSearchForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Box
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Products',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filters = _filters.copyWith(query: '');
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(query: value);
              });
            },
          ),
          const SizedBox(height: 24),

          // Price Range
          _buildPriceFilter(),
          const SizedBox(height: 24),

          // Rating Filter
          _buildRatingFilter(),
          const SizedBox(height: 24),

          // Category Filter
          _buildCategoryFilter(),
          const SizedBox(height: 24),

          // Brand Filter
          _buildBrandFilter(),
          const SizedBox(height: 24),

          // Age Range Filter
          _buildAgeRangeFilter(),
          const SizedBox(height: 24),

          // Size Filter
          _buildSizeFilter(),
          const SizedBox(height: 24),

          // Color Filter
          _buildColorFilter(),
          const SizedBox(height: 24),

          // Special Filters
          _buildSpecialFilters(),
          const SizedBox(height: 24),

          // Sort Options
          _buildSortOptions(),
          const SizedBox(height: 32),

          // Search Button
          AppButton(
            onPressed: _applySearch,
            text: 'Search Products',
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Min',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minPrice = double.tryParse(value) ?? 0;
                  setState(() {
                    _filters = _filters.copyWith(minPrice: minPrice);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Max',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final maxPrice = double.tryParse(value) ?? 1000;
                  setState(() {
                    _filters = _filters.copyWith(maxPrice: maxPrice);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_filters.minPrice, _filters.maxPrice),
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            '\$${_filters.minPrice.toInt()}',
            '\$${_filters.maxPrice.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              );
              _minPriceController.text = values.start.toInt().toString();
              _maxPriceController.text = values.end.toInt().toString();
            });
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minimum Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _filters.minRating,
          min: 0,
          max: 5,
          divisions: 5,
          label: _filters.minRating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(minRating: value);
              _minRatingController.text = value.toStringAsFixed(1);
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0 Stars'),
            Text('${_filters.minRating.toStringAsFixed(1)} Stars'),
            const Text('5 Stars'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters.category,
          items: [
            'All',
            ...AppConstants.productCategories,
          ].map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(category: value!);
            });
          },
        ),
      ],
    );
  }

  Widget _buildBrandFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brands',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _brands.map((brand) {
            final isSelected = _filters.brands.contains(brand);
            return FilterChip(
              label: Text(brand),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final brands = List<String>.from(_filters.brands);
                  if (selected) {
                    brands.add(brand);
                  } else {
                    brands.remove(brand);
                  }
                  _filters = _filters.copyWith(brands: brands);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageRanges.map((ageRange) {
            final isSelected = _filters.ageRanges.contains(ageRange);
            return FilterChip(
              label: Text(ageRange),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final ageRanges = List<String>.from(_filters.ageRanges);
                  if (selected) {
                    ageRanges.add(ageRange);
                  } else {
                    ageRanges.remove(ageRange);
                  }
                  _filters = _filters.copyWith(ageRanges: ageRanges);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sizes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sizes.map((size) {
            final isSelected = _filters.sizes.contains(size);
            return FilterChip(
              label: Text(size),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final sizes = List<String>.from(_filters.sizes);
                  if (selected) {
                    sizes.add(size);
                  } else {
                    sizes.remove(size);
                  }
                  _filters = _filters.copyWith(sizes: sizes);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colors',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((color) {
            final isSelected = _filters.colors.contains(color);
            return FilterChip(
              label: Text(color),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final colors = List<String>.from(_filters.colors);
                  if (selected) {
                    colors.add(color);
                  } else {
                    colors.remove(color);
                  }
                  _filters = _filters.copyWith(colors: colors);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Features',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('In Stock Only'),
          value: _filters.inStockOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(inStockOnly: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Eco-Friendly Only'),
          value: _filters.ecoFriendlyOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(ecoFriendlyOnly: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Organic Only'),
          value: _filters.organicOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(organicOnly: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('On Sale Only'),
          value: _filters.onSaleOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(onSaleOnly: value ?? false);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters.sortBy,
          items: const [
            DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
            DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
            DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
            DropdownMenuItem(value: 'newest', child: Text('Newest First')),
            DropdownMenuItem(value: 'name', child: Text('Name (A-Z)')),
            DropdownMenuItem(value: 'discount', child: Text('Biggest Discount')),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(sortBy: value!);
            });
          },
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _filters = SearchFilters(category: widget.initialCategory ?? 'All');
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _minRatingController.clear();
    });
  }

  void _applySearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsListScreen(
          searchFilters: _filters,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minRatingController.dispose();
    super.dispose();
  }
}
class SearchFilters {
  final String query;
  final String category;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final List<String> brands;
  final List<String> ageRanges;
  final List<String> sizes;
  final List<String> colors;
  final bool inStockOnly;
  final bool ecoFriendlyOnly;
  final bool organicOnly;
  final bool onSaleOnly;
  final String sortBy;

  SearchFilters({
    this.query = '',
    this.category = 'All',
    this.minPrice = 0,
    this.maxPrice = 1000,
    this.minRating = 0,
    this.brands = const [],
    this.ageRanges = const [],
    this.sizes = const [],
    this.colors = const [],
    this.inStockOnly = false,
    this.ecoFriendlyOnly = false,
    this.organicOnly = false,
    this.onSaleOnly = false,
    this.sortBy = 'relevance',
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? brands,
    List<String>? ageRanges,
    List<String>? sizes,
    List<String>? colors,
    bool? inStockOnly,
    bool? ecoFriendlyOnly,
    bool? organicOnly,
    bool? onSaleOnly,
    String? sortBy,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      brands: brands ?? this.brands,
      ageRanges: ageRanges ?? this.ageRanges,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      ecoFriendlyOnly: ecoFriendlyOnly ?? this.ecoFriendlyOnly,
      organicOnly: organicOnly ?? this.organicOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  // Check if any filters are applied
  bool get hasFilters {
    return query.isNotEmpty ||
        category != 'All' ||
        minPrice > 0 ||
        maxPrice < 1000 ||
        minRating > 0 ||
        brands.isNotEmpty ||
        ageRanges.isNotEmpty ||
        sizes.isNotEmpty ||
        colors.isNotEmpty ||
        inStockOnly ||
        ecoFriendlyOnly ||
        organicOnly ||
        onSaleOnly ||
        sortBy != 'relevance';
  }

  // Clear all filters
  SearchFilters clear() {
    return SearchFilters();
  }
}
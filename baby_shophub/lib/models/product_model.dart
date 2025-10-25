class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final String category;
  final String brand;
  final String ageRange;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Filtering properties
  final List<String> sizes;
  final List<String> colors;
  final List<String> materials;
  final bool isEcoFriendly;
  final bool isOrganic;
  final double discountPercentage;

  // Additional e-commerce attributes (optional)
  final double? weight; // in kg
  final double? length; // in cm
  final double? width; // in cm
  final double? height; // in cm
  final String? sku;
  final List<String> tags;
  final String? warranty;
  final String? originCountry;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.category,
    required this.brand,
    required this.ageRange,
    required this.stock,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
    this.updatedAt,
    this.sizes = const [],
    this.colors = const [],
    this.materials = const [],
    this.isEcoFriendly = false,
    this.isOrganic = false,
    this.discountPercentage = 0.0,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.sku,
    this.tags = const [],
    this.warranty,
    this.originCountry,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'category': category,
      'brand': brand,
      'ageRange': ageRange,
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sizes': sizes,
      'colors': colors,
      'materials': materials,
      'isEcoFriendly': isEcoFriendly,
      'isOrganic': isOrganic,
      'discountPercentage': discountPercentage,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'sku': sku,
      'tags': tags,
      'warranty': warranty,
      'originCountry': originCountry,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      ageRange: map['ageRange'] ?? '',
      stock: (map['stock'] ?? 0).toInt(),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      isFeatured: map['isFeatured'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      materials: List<String>.from(map['materials'] ?? []),
      isEcoFriendly: map['isEcoFriendly'] ?? false,
      isOrganic: map['isOrganic'] ?? false,
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      length: map['length'] != null ? (map['length'] as num).toDouble() : null,
      width: map['width'] != null ? (map['width'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      sku: map['sku'],
      tags: List<String>.from(map['tags'] ?? []),
      warranty: map['warranty'],
      originCountry: map['originCountry'],
    );
  }

  // 🔹 Helper Getters
  bool get isOnSale => discountPercentage > 0;
  double get salePrice =>
      isOnSale ? price * (1 - discountPercentage / 100) : price;
  String get formattedSalePrice => '\$${salePrice.toStringAsFixed(2)}';
  bool get inStock => stock > 0;
  String get firstImage => imageUrls.isNotEmpty ? imageUrls[0] : '';
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}

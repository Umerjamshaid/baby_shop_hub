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
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      ageRange: map['ageRange'] ?? '',
      stock: map['stock']?.toInt() ?? 0,
      rating: map['rating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount']?.toInt() ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Helper method to check if product is in stock
  bool get inStock => stock > 0;

  // Helper method to get the first image URL
  String get firstImage => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Helper method to format price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}
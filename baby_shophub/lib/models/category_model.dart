class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int productCount;
  final String? icon; // Icon name or URL
  final String? description;
  final String? parentId; // For subcategories
  final List<String> subcategories; // List of subcategory IDs

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.productCount = 0,
    this.icon,
    this.description,
    this.parentId,
    this.subcategories = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'icon': icon,
      'description': description,
      'parentId': parentId,
      'subcategories': subcategories,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      productCount: map['productCount']?.toInt() ?? 0,
      icon: map['icon'],
      description: map['description'],
      parentId: map['parentId'],
      subcategories: List<String>.from(map['subcategories'] ?? []),
    );
  }
  // Add copyWith method
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? productCount,
    String? icon,
    String? description,
    String? parentId,
    List<String>? subcategories,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}

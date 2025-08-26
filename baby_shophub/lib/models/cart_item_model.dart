class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final int quantity;
  final DateTime addedAt;
  final String? size;
  final String? color;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.quantity,
    required this.addedAt,
    this.size,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'size': size,
      'color': color,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: map['productPrice']?.toDouble() ?? 0.0,
      productImage: map['productImage'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      addedAt: DateTime.parse(map['addedAt']),
      size: map['size'],
      color: map['color'],
    );
  }

  // Helper to calculate total price for this cart item
  double get totalPrice => productPrice * quantity;

  // Helper to format total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  // Helper to format price
  String get formattedPrice => '\$${productPrice.toStringAsFixed(2)}';

  // Copy with method for immutability
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    int? quantity,
    DateTime? addedAt,
    String? size,
    String? color,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }
}
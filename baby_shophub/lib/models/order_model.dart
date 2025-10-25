import 'package:flutter/material.dart';

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final ShippingAddress shippingAddress;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String paymentMethod;
  final String? trackingNumber;
  final String? carrier;
  final List<OrderStatusUpdate> statusUpdates;
  final double? refundAmount;
  final String? refundReason;
  final DateTime? refundDate;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.orderDate,
    this.deliveryDate,
    required this.paymentMethod,
    this.trackingNumber,
    this.carrier,
    this.statusUpdates = const [],
    this.refundAmount,
    this.refundReason,
    this.refundDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress.toMap(),
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'statusUpdates': statusUpdates.map((update) => update.toMap()).toList(),
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'refundDate': refundDate?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<OrderItem>.from(
        map['items']?.map((x) => OrderItem.fromMap(x)) ?? [],
      ),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] ?? {}),
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.parse(map['deliveryDate'])
          : null,
      paymentMethod: map['paymentMethod'] ?? '',
      trackingNumber: map['trackingNumber'],
      carrier: map['carrier'],
      statusUpdates: List<OrderStatusUpdate>.from(
        map['statusUpdates']?.map((x) => OrderStatusUpdate.fromMap(x)) ?? [],
      ),
      refundAmount: map['refundAmount']?.toDouble(),
      refundReason: map['refundReason'],
      refundDate: map['refundDate'] != null
          ? DateTime.parse(map['refundDate'])
          : null,
    );
  }
  // ADD THIS COPYWITH METHOD
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    ShippingAddress? shippingAddress,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? paymentMethod,
    String? trackingNumber,
    String? carrier,
    List<OrderStatusUpdate>? statusUpdates,
    double? refundAmount,
    String? refundReason,
    DateTime? refundDate,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      carrier: carrier ?? this.carrier,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      refundDate: refundDate ?? this.refundDate,
    );
  }

  // Helper to format total amount
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  // Helper to get item count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Helper to check if order can be cancelled
  bool get canCancel => status == 'Pending' || status == 'Confirmed';

  // Helper to check if order can be reordered
  bool get canReorder => status == 'Delivered' || status == 'Cancelled';

  // Helper to get order status color
  Color get statusColor {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Shipped':
        return Colors.blue;
      case 'Processing':
        return Colors.orange;
      case 'Refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: map['productPrice']?.toDouble() ?? 0.0,
      productImage: map['productImage'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
    );
  }

  // Helper to calculate total price for this order item
  double get totalPrice => productPrice * quantity;

  // Helper to format total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
}

class OrderStatusUpdate {
  final String status;
  final DateTime timestamp;
  final String? message;

  OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
    };
  }

  factory OrderStatusUpdate.fromMap(Map<String, dynamic> map) {
    return OrderStatusUpdate(
      status: map['status'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      message: map['message'],
    );
  }
}

class ShippingAddress {
  final String id;
  final String fullName; // Make sure this is 'fullName' not 'name'
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.fullName, // This should be fullName
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'USA',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName, // Make sure this matches
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '', // And here
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? 'USA',
      isDefault: map['isDefault'] ?? false,
    );
  }

  // Helper to format full address
  String get formattedAddress {
    return '$street, $city, $state $zipCode, $country';
  }

  // Helper to get address for display
  String get displayAddress {
    return '$fullName\n$street\n$city, $state $zipCode\n$country\nPhone: $phone';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionFrequency {
  weekly,
  biweekly,
  monthly,
  bimonthly,
}

class SubscriptionModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final SubscriptionFrequency frequency;
  final DateTime nextDeliveryDate;
  final DateTime startDate;
  final bool isActive;
  final double discountPercentage;
  final DateTime? pausedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.frequency,
    required this.nextDeliveryDate,
    required this.startDate,
    this.isActive = true,
    this.discountPercentage = 5.0,
    this.pausedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert frequency to days
  int get frequencyInDays {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 7;
      case SubscriptionFrequency.biweekly:
        return 14;
      case SubscriptionFrequency.monthly:
        return 30;
      case SubscriptionFrequency.bimonthly:
        return 60;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'Every Week';
      case SubscriptionFrequency.biweekly:
        return 'Every 2 Weeks';
      case SubscriptionFrequency.monthly:
        return 'Every Month';
      case SubscriptionFrequency.bimonthly:
        return 'Every 2 Months';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'frequency': frequency.toString().split('.').last,
      'nextDeliveryDate': Timestamp.fromDate(nextDeliveryDate),
      'startDate': Timestamp.fromDate(startDate),
      'isActive': isActive,
      'discountPercentage': discountPercentage,
      'pausedUntil': pausedUntil != null ? Timestamp.fromDate(pausedUntil!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.tryParse(dateValue);
      return null;
    }

    SubscriptionFrequency parseFrequency(String? freq) {
      switch (freq) {
        case 'weekly':
          return SubscriptionFrequency.weekly;
        case 'biweekly':
          return SubscriptionFrequency.biweekly;
        case 'monthly':
          return SubscriptionFrequency.monthly;
        case 'bimonthly':
          return SubscriptionFrequency.bimonthly;
        default:
          return SubscriptionFrequency.monthly;
      }
    }

    return SubscriptionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      frequency: parseFrequency(map['frequency']),
      nextDeliveryDate: parseDate(map['nextDeliveryDate']),
      startDate: parseDate(map['startDate']),
      isActive: map['isActive'] ?? true,
      discountPercentage: (map['discountPercentage'] ?? 5.0).toDouble(),
      pausedUntil: parseNullableDate(map['pausedUntil']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    SubscriptionFrequency? frequency,
    DateTime? nextDeliveryDate,
    DateTime? startDate,
    bool? isActive,
    double? discountPercentage,
    DateTime? pausedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      frequency: frequency ?? this.frequency,
      nextDeliveryDate: nextDeliveryDate ?? this.nextDeliveryDate,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

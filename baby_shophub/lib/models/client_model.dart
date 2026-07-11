import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String taxId;
  final Address address;
  final String notes;
  final List<String> tags;
  final double totalInvoiced;
  final double totalPaid;
  final double outstandingAmount;
  final int invoiceCount;
  final DateTime? lastInvoiceDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.taxId,
    required this.address,
    this.notes = '',
    this.tags = const [],
    this.totalInvoiced = 0,
    this.totalPaid = 0,
    this.outstandingAmount = 0,
    this.invoiceCount = 0,
    this.lastInvoiceDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client.fromMap(json, json['id'] ?? '');
  }

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic dateValue, {DateTime? defaultValue}) {
      if (dateValue == null) return defaultValue ?? DateTime.now();
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? (defaultValue ?? DateTime.now());
      }
      return defaultValue ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
      return null;
    }

    return Client(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'] ?? '',
      taxId: map['taxId'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
      notes: map['notes'] ?? '',
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      totalInvoiced: (map['totalInvoiced'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      outstandingAmount: (map['outstandingAmount'] ?? 0).toDouble(),
      invoiceCount: map['invoiceCount'] ?? 0,
      lastInvoiceDate: parseNullableDate(map['lastInvoiceDate']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'taxId': taxId,
      'address': address.toMap(),
      'notes': notes,
      'tags': tags,
      'totalInvoiced': totalInvoiced,
      'totalPaid': totalPaid,
      'outstandingAmount': outstandingAmount,
      'invoiceCount': invoiceCount,
      'lastInvoiceDate': lastInvoiceDate,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? taxId,
    Address? address,
    String? notes,
    List<String>? tags,
    double? totalInvoiced,
    double? totalPaid,
    double? outstandingAmount,
    int? invoiceCount,
    DateTime? lastInvoiceDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      totalInvoiced: totalInvoiced ?? this.totalInvoiced,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address.fromMap(json);
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  Address copyWith({
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
    );
  }
}

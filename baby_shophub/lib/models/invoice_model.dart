import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String businessProfileId;
  final String clientId;
  final ClientDetails clientDetails;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalTax;
  final Discount discount;
  final double shippingCost;
  final double total;
  final String currency;
  final String status;
  final DateTime dueDate;
  final DateTime issueDate;
  final DateTime? paidDate;
  final double paidAmount;
  final double balanceDue;
  final String paymentMethod;
  final String notes;
  final String terms;
  final List<String> attachments;
  final String? pdfUrl;
  final bool emailSent;
  final DateTime? emailSentAt;
  final DateTime? viewedAt;
  final int remindersSent;
  final DateTime? lastReminderAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.businessProfileId,
    required this.clientId,
    required this.clientDetails,
    required this.items,
    required this.subtotal,
    required this.totalTax,
    required this.discount,
    required this.shippingCost,
    required this.total,
    required this.currency,
    required this.status,
    required this.dueDate,
    required this.issueDate,
    this.paidDate,
    this.paidAmount = 0,
    this.balanceDue = 0,
    this.paymentMethod = '',
    this.notes = '',
    this.terms = '',
    this.attachments = const [],
    this.pdfUrl,
    this.emailSent = false,
    this.emailSentAt,
    this.viewedAt,
    this.remindersSent = 0,
    this.lastReminderAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice.fromMap(json, json['id'] ?? '');
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
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

    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      businessProfileId: map['businessProfileId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientDetails: ClientDetails.fromMap(map['clientDetails'] ?? {}),
      items: List<InvoiceItem>.from(
        (map['items'] as List<dynamic>?)?.map((x) => InvoiceItem.fromMap(x)) ??
            [],
      ),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      totalTax: (map['totalTax'] ?? 0).toDouble(),
      discount: Discount.fromMap(map['discount'] ?? {}),
      shippingCost: (map['shippingCost'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'draft',
      dueDate: parseDate(map['dueDate']),
      issueDate: parseDate(map['issueDate']),
      paidDate: parseNullableDate(map['paidDate']),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      balanceDue: (map['balanceDue'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      notes: map['notes'] ?? '',
      terms: map['terms'] ?? '',
      attachments: List<String>.from(
        map['attachments'] as List<dynamic>? ?? [],
      ),
      pdfUrl: map['pdfUrl'],
      emailSent: map['emailSent'] ?? false,
      emailSentAt: parseNullableDate(map['emailSentAt']),
      viewedAt: parseNullableDate(map['viewedAt']),
      remindersSent: map['remindersSent'] ?? 0,
      lastReminderAt: parseNullableDate(map['lastReminderAt']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'businessProfileId': businessProfileId,
      'clientId': clientId,
      'clientDetails': clientDetails.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'totalTax': totalTax,
      'discount': discount.toMap(),
      'shippingCost': shippingCost,
      'total': total,
      'currency': currency,
      'status': status,
      'dueDate': dueDate,
      'issueDate': issueDate,
      'paidDate': paidDate,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'terms': terms,
      'attachments': attachments,
      'pdfUrl': pdfUrl,
      'emailSent': emailSent,
      'emailSentAt': emailSentAt,
      'viewedAt': viewedAt,
      'remindersSent': remindersSent,
      'lastReminderAt': lastReminderAt,
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? businessProfileId,
    String? clientId,
    ClientDetails? clientDetails,
    List<InvoiceItem>? items,
    double? subtotal,
    double? totalTax,
    Discount? discount,
    double? shippingCost,
    double? total,
    String? currency,
    String? status,
    DateTime? dueDate,
    DateTime? issueDate,
    DateTime? paidDate,
    double? paidAmount,
    double? balanceDue,
    String? paymentMethod,
    String? notes,
    String? terms,
    List<String>? attachments,
    String? pdfUrl,
    bool? emailSent,
    DateTime? emailSentAt,
    DateTime? viewedAt,
    int? remindersSent,
    DateTime? lastReminderAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      businessProfileId: businessProfileId ?? this.businessProfileId,
      clientId: clientId ?? this.clientId,
      clientDetails: clientDetails ?? this.clientDetails,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalTax: totalTax ?? this.totalTax,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      issueDate: issueDate ?? this.issueDate,
      paidDate: paidDate ?? this.paidDate,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      attachments: attachments ?? this.attachments,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      remindersSent: remindersSent ?? this.remindersSent,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvoiceItem {
  final String productId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double taxRate;
  final double taxAmount;
  final double amount;
  final double total;

  const InvoiceItem({
    required this.productId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.taxRate,
    required this.taxAmount,
    required this.amount,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem.fromMap(json);
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'amount': amount,
      'total': total,
    };
  }

  InvoiceItem copyWith({
    String? productId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? rate,
    double? taxRate,
    double? taxAmount,
    double? amount,
    double? total,
  }) {
    return InvoiceItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      amount: amount ?? this.amount,
      total: total ?? this.total,
    );
  }
}

class Discount {
  final String type; // 'percentage' or 'fixed'
  final double value;
  final double amount;

  const Discount({
    required this.type,
    required this.value,
    required this.amount,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount.fromMap(json);
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      type: map['type'] ?? 'percentage',
      value: (map['value'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {'type': type, 'value': value, 'amount': amount};
  }

  Discount copyWith({String? type, double? value, double? amount}) {
    return Discount(
      type: type ?? this.type,
      value: value ?? this.value,
      amount: amount ?? this.amount,
    );
  }
}

class ClientDetails {
  final String name;
  final String email;
  final String phone;
  final Address address;

  const ClientDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory ClientDetails.fromJson(Map<String, dynamic> json) {
    return ClientDetails.fromMap(json);
  }

  factory ClientDetails.fromMap(Map<String, dynamic> map) {
    return ClientDetails(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address.toMap(),
    };
  }

  ClientDetails copyWith({
    String? name,
    String? email,
    String? phone,
    Address? address,
  }) {
    return ClientDetails(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
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

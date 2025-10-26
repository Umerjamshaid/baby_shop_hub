import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_model.dart';

class Business {
  final String id;
  final String businessName;
  final String? logo;
  final String email;
  final String phone;
  final String website;
  final Address address;
  final String taxId;
  final BankDetails? bankDetails;
  final InvoiceSettings invoiceSettings;
  final String paymentTerms;
  final String notes;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Business({
    required this.id,
    required this.businessName,
    this.logo,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.taxId,
    this.bankDetails,
    required this.invoiceSettings,
    required this.paymentTerms,
    required this.notes,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business.fromMap(json, json['id'] ?? '');
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    return Business(
      id: id,
      businessName: map['businessName'] ?? '',
      logo: map['logo'],
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'] ?? '',
      address: Address.fromMap(map['address'] ?? {}),
      taxId: map['taxId'] ?? '',
      bankDetails: map['bankDetails'] != null
          ? BankDetails.fromMap(map['bankDetails'])
          : null,
      invoiceSettings: InvoiceSettings.fromMap(map['invoiceSettings'] ?? {}),
      paymentTerms: map['paymentTerms'] ?? '',
      notes: map['notes'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logo': logo,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address.toMap(),
      'taxId': taxId,
      'bankDetails': bankDetails?.toMap(),
      'invoiceSettings': invoiceSettings.toMap(),
      'paymentTerms': paymentTerms,
      'notes': notes,
      'isDefault': isDefault,
    };
  }

  Business copyWith({
    String? id,
    String? businessName,
    String? logo,
    String? email,
    String? phone,
    String? website,
    Address? address,
    String? taxId,
    BankDetails? bankDetails,
    InvoiceSettings? invoiceSettings,
    String? paymentTerms,
    String? notes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      logo: logo ?? this.logo,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      bankDetails: bankDetails ?? this.bankDetails,
      invoiceSettings: invoiceSettings ?? this.invoiceSettings,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BankDetails {
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String swiftCode;

  const BankDetails({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.swiftCode,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails.fromMap(json);
  }

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      bankName: map['bankName'] ?? '',
      swiftCode: map['swiftCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'accountName': accountName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'swiftCode': swiftCode,
    };
  }

  BankDetails copyWith({
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? swiftCode,
  }) {
    return BankDetails(
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      swiftCode: swiftCode ?? this.swiftCode,
    );
  }
}

class InvoiceSettings {
  final String prefix;
  final int startNumber;
  final int currentNumber;
  final String numberFormat;

  const InvoiceSettings({
    required this.prefix,
    required this.startNumber,
    required this.currentNumber,
    required this.numberFormat,
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) {
    return InvoiceSettings.fromMap(json);
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> map) {
    return InvoiceSettings(
      prefix: map['prefix'] ?? 'INV-',
      startNumber: map['startNumber'] ?? 1,
      currentNumber: map['currentNumber'] ?? 0,
      numberFormat: map['numberFormat'] ?? 'INV-{YYYY}-{####}',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'startNumber': startNumber,
      'currentNumber': currentNumber,
      'numberFormat': numberFormat,
    };
  }

  InvoiceSettings copyWith({
    String? prefix,
    int? startNumber,
    int? currentNumber,
    String? numberFormat,
  }) {
    return InvoiceSettings(
      prefix: prefix ?? this.prefix,
      startNumber: startNumber ?? this.startNumber,
      currentNumber: currentNumber ?? this.currentNumber,
      numberFormat: numberFormat ?? this.numberFormat,
    );
  }
}

import 'order_model.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Address> addresses;
  final List<String> favoriteProducts; // ✅ Favorites
  final List<String> fcmTokens;        // ✅ FCM Tokens
  final bool isAdmin;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    required this.createdAt,
    this.updatedAt,
    this.addresses = const [],
    this.favoriteProducts = const [],
    this.fcmTokens = const [], // ✅ Default empty list
    this.isAdmin = false,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'favoriteProducts': favoriteProducts,
      'fcmTokens': fcmTokens, // ✅ Save tokens
      'isAdmin': isAdmin,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profileImage: map['profileImage'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      addresses: List<Address>.from(
        (map['addresses'] as List? ?? []).map((x) => Address.fromMap(x)),
      ),
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []), // ✅ Load tokens
      isAdmin: map['isAdmin'] ?? false,
      role: map['role'] ?? 'user',
    );
  }

  // ✅ Unified check for admin
  bool get isAdministrator => isAdmin || role == 'admin';

  // ✅ Role check helper
  bool hasRole(String roleName) => role == roleName;

  // ✅ Default address getter
  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
          (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  // ✅ CopyWith
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Address>? addresses,
    List<String>? favoriteProducts,
    List<String>? fcmTokens,
    bool? isAdmin,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addresses: addresses ?? this.addresses,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      fcmTokens: fcmTokens ?? this.fcmTokens, // ✅ Preserve tokens
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
    );
  }
}

class Address {
  final String id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  String get fullAddress => '$street, $city, $state $zipCode';

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  ShippingAddress toShippingAddress() {
    return ShippingAddress(
      id: id,
      fullName: name,
      phone: phone,
      street: street,
      city: city,
      state: state,
      zipCode: zipCode,
      isDefault: isDefault,
    );
  }
}

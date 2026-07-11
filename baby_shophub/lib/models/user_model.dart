import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_model.dart';

class UserSettings {
  // Push Notifications
  final bool pushNotifications;
  final bool orderUpdates;
  final bool newArrivals;
  final bool promotions;
  final bool cartReminders;
  final bool deliveryUpdates;
  final bool securityAlerts;

  // Email Notifications
  final bool emailOrderUpdates;
  final bool emailPromotions;
  final bool emailNewsletters;
  final bool emailWeeklyDigest;

  // SMS Notifications
  final bool smsOrderUpdates;
  final bool smsDeliveryUpdates;
  final bool smsSecurityAlerts;

  // Marketing Communications
  final bool marketingEmails;
  final bool marketingSms;
  final bool marketingPush;
  final bool personalizedOffers;

  // Sound & Vibration
  final bool notificationSound;
  final bool notificationVibration;
  final String notificationSoundType;

  // App Preferences
  final bool darkMode;
  final String language;
  final String currency;
  final bool locationServices;

  // Privacy & Security
  final bool dataSharing;
  final bool analyticsTracking;
  final bool crashReporting;

  UserSettings({
    this.pushNotifications = true,
    this.orderUpdates = true,
    this.newArrivals = true,
    this.promotions = true,
    this.cartReminders = true,
    this.deliveryUpdates = true,
    this.securityAlerts = true,
    this.emailOrderUpdates = true,
    this.emailPromotions = false,
    this.emailNewsletters = false,
    this.emailWeeklyDigest = true,
    this.smsOrderUpdates = true,
    this.smsDeliveryUpdates = true,
    this.smsSecurityAlerts = true,
    this.marketingEmails = false,
    this.marketingSms = false,
    this.marketingPush = false,
    this.personalizedOffers = true,
    this.notificationSound = true,
    this.notificationVibration = true,
    this.notificationSoundType = 'Default',
    this.darkMode = false,
    this.language = 'English',
    this.currency = 'USD',
    this.locationServices = true,
    this.dataSharing = true,
    this.analyticsTracking = true,
    this.crashReporting = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'orderUpdates': orderUpdates,
      'newArrivals': newArrivals,
      'promotions': promotions,
      'cartReminders': cartReminders,
      'deliveryUpdates': deliveryUpdates,
      'securityAlerts': securityAlerts,
      'emailOrderUpdates': emailOrderUpdates,
      'emailPromotions': emailPromotions,
      'emailNewsletters': emailNewsletters,
      'emailWeeklyDigest': emailWeeklyDigest,
      'smsOrderUpdates': smsOrderUpdates,
      'smsDeliveryUpdates': smsDeliveryUpdates,
      'smsSecurityAlerts': smsSecurityAlerts,
      'marketingEmails': marketingEmails,
      'marketingSms': marketingSms,
      'marketingPush': marketingPush,
      'personalizedOffers': personalizedOffers,
      'notificationSound': notificationSound,
      'notificationVibration': notificationVibration,
      'notificationSoundType': notificationSoundType,
      'darkMode': darkMode,
      'language': language,
      'currency': currency,
      'locationServices': locationServices,
      'dataSharing': dataSharing,
      'analyticsTracking': analyticsTracking,
      'crashReporting': crashReporting,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      pushNotifications: map['pushNotifications'] ?? true,
      orderUpdates: map['orderUpdates'] ?? true,
      newArrivals: map['newArrivals'] ?? true,
      promotions: map['promotions'] ?? true,
      cartReminders: map['cartReminders'] ?? true,
      deliveryUpdates: map['deliveryUpdates'] ?? true,
      securityAlerts: map['securityAlerts'] ?? true,
      emailOrderUpdates: map['emailOrderUpdates'] ?? true,
      emailPromotions: map['emailPromotions'] ?? false,
      emailNewsletters: map['emailNewsletters'] ?? false,
      emailWeeklyDigest: map['emailWeeklyDigest'] ?? true,
      smsOrderUpdates: map['smsOrderUpdates'] ?? true,
      smsDeliveryUpdates: map['smsDeliveryUpdates'] ?? true,
      smsSecurityAlerts: map['smsSecurityAlerts'] ?? true,
      marketingEmails: map['marketingEmails'] ?? false,
      marketingSms: map['marketingSms'] ?? false,
      marketingPush: map['marketingPush'] ?? false,
      personalizedOffers: map['personalizedOffers'] ?? true,
      notificationSound: map['notificationSound'] ?? true,
      notificationVibration: map['notificationVibration'] ?? true,
      notificationSoundType: map['notificationSoundType'] ?? 'Default',
      darkMode: map['darkMode'] ?? false,
      language: map['language'] ?? 'English',
      currency: map['currency'] ?? 'USD',
      locationServices: map['locationServices'] ?? true,
      dataSharing: map['dataSharing'] ?? true,
      analyticsTracking: map['analyticsTracking'] ?? true,
      crashReporting: map['crashReporting'] ?? true,
    );
  }

  UserSettings copyWith({
    bool? pushNotifications,
    bool? orderUpdates,
    bool? newArrivals,
    bool? promotions,
    bool? cartReminders,
    bool? deliveryUpdates,
    bool? securityAlerts,
    bool? emailOrderUpdates,
    bool? emailPromotions,
    bool? emailNewsletters,
    bool? emailWeeklyDigest,
    bool? smsOrderUpdates,
    bool? smsDeliveryUpdates,
    bool? smsSecurityAlerts,
    bool? marketingEmails,
    bool? marketingSms,
    bool? marketingPush,
    bool? personalizedOffers,
    bool? notificationSound,
    bool? notificationVibration,
    String? notificationSoundType,
    bool? darkMode,
    String? language,
    String? currency,
    bool? locationServices,
    bool? dataSharing,
    bool? analyticsTracking,
    bool? crashReporting,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      newArrivals: newArrivals ?? this.newArrivals,
      promotions: promotions ?? this.promotions,
      cartReminders: cartReminders ?? this.cartReminders,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      emailOrderUpdates: emailOrderUpdates ?? this.emailOrderUpdates,
      emailPromotions: emailPromotions ?? this.emailPromotions,
      emailNewsletters: emailNewsletters ?? this.emailNewsletters,
      emailWeeklyDigest: emailWeeklyDigest ?? this.emailWeeklyDigest,
      smsOrderUpdates: smsOrderUpdates ?? this.smsOrderUpdates,
      smsDeliveryUpdates: smsDeliveryUpdates ?? this.smsDeliveryUpdates,
      smsSecurityAlerts: smsSecurityAlerts ?? this.smsSecurityAlerts,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      marketingSms: marketingSms ?? this.marketingSms,
      marketingPush: marketingPush ?? this.marketingPush,
      personalizedOffers: personalizedOffers ?? this.personalizedOffers,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration:
          notificationVibration ?? this.notificationVibration,
      notificationSoundType:
          notificationSoundType ?? this.notificationSoundType,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      locationServices: locationServices ?? this.locationServices,
      dataSharing: dataSharing ?? this.dataSharing,
      analyticsTracking: analyticsTracking ?? this.analyticsTracking,
      crashReporting: crashReporting ?? this.crashReporting,
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

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Address> addresses;
  final List<String> favoriteProducts;
  final List<String> fcmTokens;
  final bool isAdmin;
  final String role;
  final UserSettings settings; // ✅ Added settings

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
    this.fcmTokens = const [],
    this.isAdmin = false,
    this.role = 'user',
    UserSettings? settings, // ✅ Optional parameter with default
  }) : settings = settings ?? UserSettings();

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
      'fcmTokens': fcmTokens,
      'isAdmin': isAdmin,
      'role': role,
      'settings': settings.toMap(), // ✅ Save settings
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper function to handle both Timestamp and String dates
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profileImage: map['profileImage'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      addresses: List<Address>.from(
        (map['addresses'] as List? ?? []).map((x) => Address.fromMap(x)),
      ),
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      role: map['role'] ?? 'user',
      settings: map['settings'] != null
          ? UserSettings.fromMap(map['settings'])
          : UserSettings(), // ✅ Load settings with fallback
    );
  }

  bool get isAdministrator => isAdmin || role == 'admin';

  bool hasRole(String roleName) => role == roleName;

  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

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
    UserSettings? settings, // ✅ Added settings to copyWith
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
      fcmTokens: fcmTokens ?? this.fcmTokens,
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
      settings: settings ?? this.settings, // ✅ Preserve settings
    );
  }
}

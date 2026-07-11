import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save cart items locally (for offline access)
  Future<void> saveCartItems(List<Map<String, dynamic>> items) async {
    // Convert to JSON string
    final jsonString = json.encode(items);
    await _prefs?.setString('cart_items', jsonString);
  }

  // Load cart items from local storage
  List<Map<String, dynamic>> loadCartItems() {
    final jsonString = _prefs?.getString('cart_items');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Clear local cart
  Future<void> clearLocalCart() async {
    await _prefs?.remove('cart_items');
  }

  // Save user preferences
  Future<void> saveUserPreference(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  // Get user preference
  String? getUserPreference(String key) {
    return _prefs?.getString(key);
  }
}
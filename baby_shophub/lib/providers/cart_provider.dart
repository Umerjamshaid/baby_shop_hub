import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cartItems.length;
  double get totalAmount {
    return _cartItems.fold(0, (total, item) {
      return total + (item.productPrice * item.quantity);
    });
  }

  // Load user cart
  Future<void> loadUserCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cartItems = await _cartService.getUserCart(userId);
      _isLoading = false;

      // 🔹 Schedule cart abandonment reminder
      scheduleCartAbandonmentNotification(userId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add product to cart
  Future<void> addToCart(String userId, Product product,
      {int quantity = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existingItemIndex = _cartItems.indexWhere(
            (item) => item.productId == product.id,
      );

      if (existingItemIndex != -1) {
        final existingItem = _cartItems[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        await _cartService.updateCartItemQuantity(
          userId,
          existingItem.id,
          newQuantity,
        );

        _cartItems[existingItemIndex] = CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          productName: existingItem.productName,
          productPrice: existingItem.productPrice,
          productImage: existingItem.productImage,
          quantity: newQuantity,
          addedAt: existingItem.addedAt,
        );
      } else {
        final newCartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.firstImage,
          quantity: quantity,
          addedAt: DateTime.now(),
        );

        await _cartService.addToCart(userId, newCartItem);
        _cartItems.add(newCartItem);
      }

      _isLoading = false;

      // 🔹 Schedule cart abandonment reminder
      scheduleCartAbandonmentNotification(userId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String cartItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.removeFromCart(userId, cartItemId);
      _cartItems.removeWhere((item) => item.id == cartItemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update item quantity
  Future<void> updateQuantity(
      String userId, String cartItemId, int newQuantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (newQuantity <= 0) {
        await removeFromCart(userId, cartItemId);
        return;
      }

      await _cartService.updateCartItemQuantity(userId, cartItemId, newQuantity);

      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex != -1) {
        final updatedItem = CartItem(
          id: _cartItems[itemIndex].id,
          productId: _cartItems[itemIndex].productId,
          productName: _cartItems[itemIndex].productName,
          productPrice: _cartItems[itemIndex].productPrice,
          productImage: _cartItems[itemIndex].productImage,
          quantity: newQuantity,
          addedAt: _cartItems[itemIndex].addedAt,
        );
        _cartItems[itemIndex] = updatedItem;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.clearCart(userId);
      _cartItems.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  // Get quantity of product in cart
  int getProductQuantity(String productId) {
    final item = _cartItems.firstWhere(
          (item) => item.productId == productId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        productName: '',
        productPrice: 0,
        productImage: '',
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  // 🔹 Cart abandonment reminder
  void scheduleCartAbandonmentNotification(String userId) {
    if (cartItems.isNotEmpty) {
      Future.delayed(const Duration(hours: 1), () async {
        if (cartItems.isNotEmpty) {
          await NotificationService.showLocalNotification(
            title: 'Items waiting in your cart',
            body:
            'You have ${cartItems.length} items waiting in your cart. Complete your purchase now!',
            payload: 'cart_reminder',
          );
        }
      });
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

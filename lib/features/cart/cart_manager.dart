import 'package:flutter/foundation.dart';

class CartItem {
  final int productId;
  final String productName;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    this.quantity = 1,
  });
}

class CartManager {
  // Singleton para controlar el carro actual
  CartManager._privateConstructor();
  static final CartManager instance = CartManager._privateConstructor();

  // ValueNotifier notifica a la UI cuando hay cambios (para actualizar el ícono)
  final ValueNotifier<List<CartItem>> cartItems = ValueNotifier([]);

  void addToCart(int productId, String productName) {
    final currentList = List<CartItem>.from(cartItems.value);

    // Si ya esta el producto, se suma a la cnatidad
    final index = currentList.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      currentList[index].quantity += 1;
    } else {
      currentList.add(CartItem(productId: productId, productName: productName));
    }

    cartItems.value = currentList;
  }

  void removeFromCart(int productId) {
    final currentList = List<CartItem>.from(cartItems.value);
    currentList.removeWhere((item) => item.productId == productId);
    cartItems.value = currentList;
  }

  void clearCart() {
    cartItems.value = [];
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cart_item.dart';

import 'package:shared_preferences/shared_preferences.dart';
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  /// قائمة المنتجات في السلة
  List<CartItem> get items => _items;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  /// حساب إجمالي السعر
  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  /// إضافة منتج إلى السلة
  void addItem(CartItem item) {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  /// إزالة منتج من السلة
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// تحديث كمية منتج معين في السلة
  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1 && quantity > 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// تفريغ السلة من جميع المنتجات
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  void updateItemQuantity(String id, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  /// إرسال الطلب إلى Firebase Realtime Database
  Future<void> sendOrder() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/order.json');

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id') ?? 'unknown';

    final orderData = {
      'customerId': customerId,
      'items': _items.map((item) => {
        'id': item.keySerch,
        'quantity': item.quantity,
      }).toList(),
      'totalPrice': totalPrice,
      'date': DateTime.now().toIso8601String(),
      'show': 0,

    };

    try {
      final response = await http.post(
        url,
        body: json.encode(orderData),
      );

      if (response.statusCode >= 400) {
        throw Exception('فشل إرسال الطلب');
      }

      clearCart();
    } catch (error) {
      print('Error sending order: $error');
      throw error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}

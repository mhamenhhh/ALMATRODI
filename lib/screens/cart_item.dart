// cart_item.dart
class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  int quantity;
  final String keySerch; // 🛠️ أضفنا هنا حقل keySerch

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
    required this.keySerch, // 🛠️ وأضفناه بالمُنشئ
  });

  /// تحويل بيانات المنتج إلى Map (مفيد للتخزين أو الإرسال)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'key_serch': keySerch, // 🛠️ نضيفه لما نحول لـ Map
    };
  }

  /// إنشاء كائن CartItem من Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: map['quantity'] ?? 1,
      keySerch: map['key_serch'] ?? '', // 🛠️ وأيضاً هنا أثناء البناء من الـ Map
    );
  }
}

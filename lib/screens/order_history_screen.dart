import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer/shimmer.dart';

import 'package:shared_preferences/shared_preferences.dart';
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'ar');
  String _searchQuery = '';
  String? _expandedOrderId; // لتتبع الطلب المفتوح حالياً
  bool _showAll = false; // إذا كانت true تعرض جميع الطلبات، وإلا تعرض فقط طلبات أحدث تاريخ

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    await initializeDateFormatting('ar');

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id') ?? 'unknown';

    final ordersResponse = await http.get(Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/order.json'));
    final productsResponse = await http.get(Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/products.json'));

    if (ordersResponse.statusCode != 200 || productsResponse.statusCode != 200) {
      throw Exception('فشل تحميل الطلبات أو المنتجات');
    }

    final Map<String, dynamic>? ordersData = json.decode(ordersResponse.body);
    final Map<String, dynamic>? productsData = json.decode(productsResponse.body);

    if (ordersData == null || productsData == null) return [];

    final List<Map<String, dynamic>> orders = [];

    ordersData.forEach((orderId, orderValue) {
      final order = Map<String, dynamic>.from(orderValue);

      // فقط إذا كان customerId يطابق
      if (order['customerId'] == customerId) {
        final List<Map<String, dynamic>> items = [];

        if (order['items'] != null) {
          for (var item in order['items']) {
            final id = item['id'] ?? '';
            final productDetails = productsData[id];

            if (productDetails != null) {
              items.add({
                'name': productDetails['Name'] ?? '',
                'image': 'http://51.195.6.59/ToobacoNew/images/${productDetails['ART_NO']}.JPG',
                'price': productDetails['Price2'] ?? 0,
                'quantity': item['quantity'] ?? 1,
              });
            }
          }
        }

        orders.add({
          'id': orderId,
          'date': order['date'],
          'totalPrice': order['totalPrice'],
          'items': items, // ربطنا المنتجات المعدلة هنا
        });
      }
    });

    // ترتيب تنازلي بالتاريخ
    orders.sort((a, b) {
      final aDate = _parseDate(a['date']);
      final bDate = _parseDate(b['date']);
      return bDate.compareTo(aDate);
    });

    return orders;
  }


  // دالة لتحويل الأرقام العربية إلى إنجليزية
  String normalizeDigits(String input) {
    return input.replaceAllMapped(RegExp(r'[٠-٩]'), (match) {
      final digit = match.group(0)!;
      const digitMap = {
        '٠': '0',
        '١': '1',
        '٢': '2',
        '٣': '3',
        '٤': '4',
        '٥': '5',
        '٦': '6',
        '٧': '7',
        '٨': '8',
        '٩': '9',
      };
      return digitMap[digit] ?? digit;
    });
  }

  DateTime _parseDate(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime(1970);

  bool _matchesSearch(Map<String, dynamic> order, String query) {
    final formattedDate =
    DateFormat('dd/MM/yyyy', 'ar').format(_parseDate(order['date']));
    final normalizedQuery = normalizeDigits(query.toLowerCase());
    final normalizedDate = normalizeDigits(formattedDate.toLowerCase());
    final items = (order['items'] as List).cast<Map<String, dynamic>>();

    final dateMatch = normalizedDate.contains(normalizedQuery);
    final itemNameMatch = items.any((item) {
      final itemName = item['name']?.toString().toLowerCase() ?? '';
      return normalizeDigits(itemName).contains(normalizedQuery);
    });
    return dateMatch || itemNameMatch;
  }

  void _showFullImage(BuildContext context, String imageUrl) => showDialog(
    context: context,
    builder: (context) => Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'سجل الطلبات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.teal[700],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(10),
          color: Colors.grey[200],
          child: const Text(
            'سعر الموجود ع الصورة محدث بسعر اليوم اما السعر الموجود بتفاصيل الطلب فهو سعر الشراء في ذلك اليوم',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'ابحث بالتاريخ أو اسم المنتج...',
          hintStyle: const TextStyle(fontFamily: 'Cairo'),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() {
              _searchController.clear();
              _searchQuery = '';
            }),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
  );
  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // عدد الكروت الوهمية
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان والتاريخ
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  // الإجمالي
                  Container(
                    width: 100,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  // العناصر داخل الأوردر
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _fetchOrders(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildShimmerLoader();
      }


      if (snapshot.hasError) {
        return Center(
          child: Text('حدث خطأ في جلب البيانات',
              style: TextStyle(
                  fontFamily: 'Cairo', color: Colors.red[700])),
        );
      }

      final orders = snapshot.data ?? [];
      final filtered = orders
          .where((o) =>
      _searchQuery.isEmpty || _matchesSearch(o, _searchQuery))
          .toList();

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off,
                  size: 60, color: Colors.grey),
              const SizedBox(height: 15),
              Text('لا توجد نتائج بحث',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.grey[600])),
            ],
          ),
        );
      }

      final latestDateString = DateFormat('dd/MM/yyyy', 'ar')
          .format(_parseDate(orders.first['date']));

      final displayedOrders = _showAll
          ? filtered
          : filtered.where((order) {
        final orderDate = DateFormat('dd/MM/yyyy', 'ar')
            .format(_parseDate(order['date']));
        return orderDate == latestDateString;
      }).toList();

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: displayedOrders.length,
              itemBuilder: (context, index) {
                final isLatest = DateFormat('dd/MM/yyyy', 'ar')
                    .format(_parseDate(displayedOrders[index]['date'])) ==
                    latestDateString;
                return _buildOrderCard(displayedOrders[index],
                    isLatest: isLatest);
              },
            ),
          ),
          if (!_showAll &&
              filtered.any((order) {
                final orderDate = DateFormat('dd/MM/yyyy', 'ar')
                    .format(_parseDate(order['date']));
                return orderDate != latestDateString;
              }))
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAll = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'تحميل كل طلباتي القديمة',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _buildOrderCard(Map<String, dynamic> order, {bool isLatest = false}) {
    final date =
    DateFormat('dd/MM/yyyy', 'ar').format(_parseDate(order['date']));
    final totalQuantity = (order['items'] as List).fold(
      0,
          (int previous, dynamic element) {
        int quantity;
        if (element['quantity'] is int) {
          quantity = element['quantity'] as int;
        } else {
          quantity = int.tryParse(element['quantity'].toString()) ?? 0;
        }
        return previous + quantity;
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: isLatest ? Colors.amber[50] : Colors.white,
        elevation: isLatest ? 6 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isLatest
              ? const BorderSide(color: Colors.orange, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            if (isLatest)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'أحدث الطلب',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ExpansionTile(
              key: PageStorageKey(order['id']),
              initiallyExpanded: order['id'] == _expandedOrderId,
              leading: Icon(Icons.shopping_basket, color: Colors.teal[700]),
              title: Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'الإجمالي: ${_currencyFormatter.format(order['totalPrice'])} د.ع - عدد الكراتين: $totalQuantity',
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.teal[700]),
              ),
              children: [
                ...(order['items'] as List)
                    .map((i) => _buildProductItem(i))
                    .toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    final product = Map<String, dynamic>.from(item);
    final imageUrl = product['image'] ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: GestureDetector(
        onTap: () => _showFullImage(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl.isEmpty
              ? Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 70,
              height: 70,
              color: Colors.white,
            ),
          )
              : Image.network(
            imageUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      title: Text(
        product['name'] ?? '',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر: ${_currencyFormatter.format(double.tryParse(product['price'].toString()) ?? 0)} د.ع',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          Text(
            'الكمية: ${product['quantity']}',
            style: TextStyle(
                fontFamily: 'Cairo', color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

}
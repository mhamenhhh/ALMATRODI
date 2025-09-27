import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CustomerOrdersScreen extends StatefulWidget {
  final String customerId;

  const CustomerOrdersScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  _CustomerOrdersScreenState createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  Future<List<Map<String, dynamic>>> _fetchCustomerOrders() async {
    final response = await http.get(Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/order.json'));

    if (response.statusCode != 200) throw Exception('فشل تحميل الطلبات');

    final Map<String, dynamic>? data = json.decode(response.body);
    if (data == null) return [];

    final List<Map<String, dynamic>> orders = data.entries.map((entry) {
      final order = Map<String, dynamic>.from(entry.value as Map);
      order['id'] = entry.key;
      return order;
    }).toList();

    // فلترة الطلبات حسب الزبون
    return orders.where((order) => order['customerId'] == widget.customerId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم العميل'),
        backgroundColor: Colors.teal[700],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCustomerOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('لا توجد طلبات لهذا العميل'),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    DateFormat('dd/MM/yyyy', 'ar').format(DateTime.parse(order['date'])),
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'إجمالي الطلب: ${order['totalPrice']} د.ع',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    onPressed: () {
                      _showOrderDetails(context, order);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var item in order['items']) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(item['image']),
                ),
                title: Text(item['name']),
                subtitle: Text('الكمية: ${item['quantity']}, السعر: ${item['price']}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
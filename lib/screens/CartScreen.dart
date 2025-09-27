import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'cart_provider.dart';
import 'order_history_screen.dart';

class CartScreen extends StatelessWidget {
  const  CartScreen({super.key});




  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 30;
    final currencyFormatter = NumberFormat('#,##0', 'ar');
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('سلة المشتريات', style: TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }

          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Text('لا توجد منتجات في السلة!', style: TextStyle(  fontSize: 18)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Image.network(item.image, fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(item.name, style: const TextStyle(  fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السعر: ${currencyFormatter.format(item.price)} د.ع',
                              style: const TextStyle(  fontSize: 14, color: Colors.teal),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      cartProvider.updateQuantity(item.id, item.quantity - 1);
                                    }
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(  fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () {
                                    cartProvider.updateQuantity(item.id, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            cartProvider.removeItem(item.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ بيانات المجموع والتفاصيل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📦 مجموع الكراتين:',
                            style: TextStyle( fontSize: 16),
                          ),
                          Text(
                            '${cartProvider.totalItems}',
                            style: const TextStyle(  fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '💰 المبلغ الكلي:',
                            style: TextStyle(  fontSize: 16),
                          ),
                          Text(
                            '${currencyFormatter.format(cartProvider.totalPrice)} د.ع',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

// ✅ زر إرسال الطلب أسفله بشكل أنيق
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // ✅ فتح نافذة تأكيد
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد الإرسال', style: TextStyle(fontFamily: 'Cairo')),
                          content: const Text(
                            'هل أنت متأكد من إرسال الطلب؟\nعند تأكيد الإرسال لا يمكن بعدها تعديل الطلبية أو الغائها.',

                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      // ✅ إذا اختار المستخدم تأكيد
                      if (confirm == true) {
                        final message = StringBuffer('🛒 تفاصيل الطلب:\n');
                        for (var item in cartProvider.items) {
                          message.writeln('🔹 ${item.id} (${item.quantity})');
                        }
                        message.writeln('\n📦 الإجمالي: ${currencyFormatter.format(cartProvider.totalPrice)} د.ع');
                        message.writeln('📅 التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');

                        final url = Uri.parse('https://wa.me/9647714651873?text=${Uri.encodeComponent(message.toString())}');
                        await cartProvider.sendOrder();

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('لا يمكن فتح واتساب')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'إرسال الطلب',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                  ),
                ),
              ),


            ],
          );
        },
      ),

    );
  }
}

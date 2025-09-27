import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'cart_provider.dart';
import 'cart_item.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String artNo;
  final String category;

  const ProductDetailsScreen({Key? key, required this.artNo, required this.category}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? productDetails;
  bool isLoading = true;
  int quantity = 1;
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    checkIfInCart();
  }

  void checkIfInCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final existingItem = cartProvider.items.firstWhere(
          (item) => item.id == widget.artNo,
      orElse: () => CartItem(id: '', name: '', image: '', price: 0, quantity: 0, keySerch: ''),
    );

    if (existingItem.id.isNotEmpty) {
      setState(() {
        isInCart = true;
        quantity = existingItem.quantity;
      });
    }
  }

  Future<void> fetchProductDetails() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final jsonFolder = Directory('${directory.path}/json_files');
      final files = jsonFolder.listSync().whereType<File>().where((file) => file.path.endsWith('.json')).toList();
      if (files.isEmpty) {
        setState(() {
          isLoading = false;
          productDetails = null;
        });
        return;
      }
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestFile = files.first;
      final content = await latestFile.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final productEntry = data.entries.firstWhere(
            (entry) => entry.value['ART_NO'] == widget.artNo,
        orElse: () => const MapEntry('', {}),
      );

      if (productEntry.key.isNotEmpty) {
        final loadedProduct = {
          'ART_NO': productEntry.value['ART_NO'],
          'Name': productEntry.value['Name'],
          'Color': productEntry.value['Color'],
          'Size': productEntry.value['Size'],
          'PCK': productEntry.value['PCK'],
          'Price': productEntry.value['Price'],
          'Price2': productEntry.value['Price2'],
          'key_serch': productEntry.value['key_serch'],
          'Category': productEntry.value['Category'],
          'image': 'http://51.195.6.59/ToobacoNew/images/${productEntry.value['ART_NO']}.JPG',
        };

        setState(() {
          productDetails = loadedProduct;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          productDetails = null;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        productDetails = null;
      });
    }
  }

  /// ✅ ويدجت ثابتة للمعلومات
  Widget _buildInfoRow(String label, dynamic value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (value != null && value.toString().isNotEmpty) ? value.toString() : 'غير متوفر',
              style: TextStyle(fontSize: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ صورة المنتج مع تناسق على أي شاشة
  Widget buildProductImage() {
    final String? imageUrl = productDetails?['image'] as String?;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl ?? "",
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }


  /// ✅ المحتوى كامل بحجم الشاشة
  Widget buildContent() {
    String cleanNumber(String input) {
      const arabicNums = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      for (int i = 0; i < arabicNums.length; i++) {
        input = input.replaceAll(arabicNums[i], i.toString());
      }
      input = input.replaceAll(RegExp(r'[^0-9.]'), '');
      return input;
    }

    final formatCurrency = NumberFormat.currency(locale: 'ar_IQ', symbol: 'دينار عراقي ', decimalDigits: 0);
    final price = double.tryParse(cleanNumber(productDetails!['Price'].toString()));
    final pck = double.tryParse(cleanNumber(productDetails!['PCK'].toString()));

    return SizedBox.expand(   // ✅ الصفحة تاخذ حجم الشاشة
      child: SingleChildScrollView(
        child: Column(
          children: [
            buildProductImage(),
            const SizedBox(height: 12),

            /// 💰 بطاقة الأسعار
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          "سعر القطعة:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8), // مسافة صغيرة بدل التباعد الكبير
                        Text(
                          price != null ? formatCurrency.format(price / 12) : "غير متوفر",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,   // 🔴 الرقم باللون الأحمر
                          ),
                        ),
                      ],
                    ),

                    const Divider(),
                    _buildInfoRow("سعر الكارتون:",
                        (price != null && pck != null) ? formatCurrency.format((price / 12) * pck) : "غير متوفر"),
                    _buildInfoRow("سعر الدرزن:", price != null ? formatCurrency.format(price) : "غير متوفر"),
                    _buildInfoRow(" عدد القطع بالكارتون:", productDetails!['PCK']),

                  ],
                ),
              ),
            ),

            /// ℹ️ بطاقة المعلومات
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("رقم المنتج:", productDetails!['ART_NO']),
                    _buildInfoRow("الاسم:", productDetails!['Name']),
                    _buildInfoRow("التصنيف:", productDetails!['Category']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }


  /// ✅ الشريط السفلي للحجز
  Widget buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 8, offset: Offset(0, -2)),
      ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => setState(() { if (quantity > 1) quantity--; }),
                    icon: const Icon(Icons.remove, color: Colors.blue)),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => setState(() => quantity++),
                    icon: const Icon(Icons.add, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                if (isInCart) {
                  cartProvider.updateItemQuantity(productDetails!['ART_NO'], quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("📦 تم تحديث الكمية إلى $quantity"), duration: const Duration(milliseconds: 500)),
                  );
                } else {
                  final cartItem = CartItem(
                    id: productDetails!['ART_NO'],
                    name: productDetails!['Name'],
                    image: productDetails!['image'],
                    price: double.tryParse(productDetails!['Price'].toString()) ?? 0,
                    quantity: quantity,
                    keySerch: productDetails!['key_serch'] ?? '',
                  );
                  cartProvider.addItem(cartItem);
                  setState(() => isInCart = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("تم إضافة ${productDetails!['Name']} بكمية $quantity إلى السلة."),
                        duration: const Duration(milliseconds: 500)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isInCart ? Colors.yellow : Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isInCart ? "  تم الحجز ($quantity)" : "🛒 إضافة إلى السلة",
                style: TextStyle(fontSize: 18, color: isInCart ? Colors.red : Colors.white),
              ),
            ),
          ),

          if (isInCart) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false).removeItem(productDetails!['ART_NO']);
                setState(() {
                  isInCart = false;
                  quantity = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ تم إلغاء الحجز لـ ${productDetails!['Name']}"), duration: const Duration(milliseconds: 500)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("الغاء", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "تفاصيل المنتج",
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
          centerTitle: true,
          automaticallyImplyLeading: false, // ❌ نخفي السهم الافتراضي
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // ✅ سهم أبيض
            onPressed: () {
              Navigator.pop(context); // يرجع للشاشة السابقة
            },
          ),
        ),

        body: isLoading
            ? buildShimmerLoader()
            : productDetails == null
            ? const Center(child: Text("لم يتم العثور على المنتج."))
            : buildContent(),
        bottomNavigationBar: productDetails != null ? buildBottomBar() : null,
      ),
    );
  }

  /// ✅ Shimmer Loader
  Widget buildShimmerLoader() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(height: 300, width: double.infinity, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(height: 20, width: double.infinity, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

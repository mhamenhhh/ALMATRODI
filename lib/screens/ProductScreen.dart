import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; // استخدام import من dart:ui مع alias ui
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'CartScreen.dart';
import 'ProductDetailsScreen.dart'; // تأكد من صحة مسار الملف
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'cart_item.dart';
import 'cart_provider.dart';

/// سلوك تمرير مخصص لإخفاء تأثير overscroll (الشريط الأصفر)
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class ProductScreen extends StatefulWidget {
  final String subCategory;
  final String label;
  final bool showOnlySlippers;
  //const ProductScreen({Key? key, required this.subCategory, required this.label}) : super(key: key);
  final List<Map<String, dynamic>>? overrideProducts;

  const ProductScreen({
    Key? key,
    required this.subCategory,
    required this.label,
    this.overrideProducts,
    this.showOnlySlippers = false,
  }) : super(key: key);







  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  final int pageSize = 20;
  bool allLoaded = false;
  int gridColumns = 2; // القيمة الافتراضية؛ يمكن تغييرها عبر القائمة المنسدلة
  String sortOrder = "asc";
  TextEditingController searchController = TextEditingController();
  double? minPrice;
  double? maxPrice;
  RangeValues? selectedRange;
  final formatCurrency = NumberFormat("#,###", "ar");
  @override
  void initState() {
    super.initState();

    if (widget.overrideProducts != null) {
      setState(() {
        products = widget.overrideProducts!;
        filteredProducts = List.from(products);
        sortProducts("asc");
        allLoaded = true;
        isLoading = false;
      });
      _initPriceRange();
    } else {
      fetchProducts();
      fetchPricesRange(); // ✅ هنا
    }
  }

  Future<void> fetchPricesRange() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final jsonDir = Directory('${directory.path}/json_files');

      final files = jsonDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isNotEmpty) {
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        final latestFile = files.first;

        final jsonString = await latestFile.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);

        // استخرج الأسعار فقط
        final prices = data.entries
            .where((entry) {
          final category = entry.value['Category']?.toString().toLowerCase() ?? '';
          final matchesStart = category.startsWith(widget.subCategory.toLowerCase());

          final isSlipper = category.contains('slipper') ||
              category.contains('slippers') ||
              category.contains('نعال') ||
              category.contains('شحاط');

          if (widget.showOnlySlippers) {
            return matchesStart && isSlipper;
          } else {
            return matchesStart && !isSlipper;
          }
        })
            .map((entry) => double.tryParse(entry.value['Price'].toString()) ?? 0)
            .where((p) => p > 0)
            .toList();

        if (prices.isNotEmpty) {
          setState(() {
            minPrice = prices.reduce((a, b) => a < b ? a : b);
            maxPrice = prices.reduce((a, b) => a > b ? a : b);
            selectedRange = RangeValues(minPrice!, maxPrice!);
          });
        }
      }
    } catch (e) {
      print("❌ خطأ بجلب الرينج: $e");
    }
  }


  void _initPriceRange() {
    if (products.isNotEmpty) {
      minPrice = products.map((p) => double.parse(p['price'].toString())).reduce((a, b) => a < b ? a : b);
      maxPrice = products.map((p) => double.parse(p['price'].toString())).reduce((a, b) => a > b ? a : b);
      selectedRange = RangeValues(minPrice!, maxPrice!);
      print("📊 Range initialized: $minPrice - $maxPrice");
    }
  }

  bool isProductInCart(String artNo, BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return cartProvider.items.any((item) => item.id == artNo);
  }

  void _showPriceFilter(BuildContext context) {
    if (minPrice == null || maxPrice == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("فلترة حسب السعر",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // ✅ RangeSlider
                  RangeSlider(
                    values: selectedRange!,
                    min: minPrice!,
                    max: maxPrice!,
                    divisions: 20,
                    labels: RangeLabels(
                      "${formatCurrency.format(selectedRange!.start.round())} د.ع",
                      "${formatCurrency.format(selectedRange!.end.round())} د.ع",
                    ),
                    onChanged: (RangeValues values) {
                      setStateModal(() {
                        selectedRange = values;
                      });
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(" ${formatCurrency.format(selectedRange!.start.round())} د.ع"),
                      Text(" ${formatCurrency.format(selectedRange!.end.round())} د.ع"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 48)),
                    onPressed: () {
                      setState(() {
                        filteredProducts = products.where((product) {
                          double price = double.parse(product['price'].toString());
                          return price >= selectedRange!.start &&
                              price <= selectedRange!.end;
                        }).toList();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "تطبيق",
                      style: TextStyle(
                        color: Colors.white,   // 🔥 لون الكتابة أبيض
                        fontSize: 18,          // ✨ حجم أكبر (غير 18 للقيمة اللي تعجبك)
                        fontWeight: FontWeight.bold, // اختياري: يخلي الخط أثقل
                      ),
                    ),

                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                    "الغاء",
                    style: TextStyle(
                      color: Colors.teal,   // 🔥 لون الكتابة أبيض
                      fontSize: 18,          // ✨ حجم أكبر (غير 18 للقيمة اللي تعجبك)
                      fontWeight: FontWeight.bold, // اختياري: يخلي الخط أثقل
                    ),
                  ),

            ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> saveProductsToCache(List<Map<String, dynamic>> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(products);
    final now = DateTime.now();
    await prefs.setString('cachedProducts_${widget.subCategory}', jsonString);
    await prefs.setString('cachedDate_${widget.subCategory}', now.toIso8601String());
  }

  Future<List<Map<String, dynamic>>?> loadProductsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cachedProducts_${widget.subCategory}');
    final dateString = prefs.getString('cachedDate_${widget.subCategory}');

    if (jsonString != null && dateString != null) {
      final cachedDate = DateTime.parse(dateString);
      final now = DateTime.now();

      // فحص التاريخ والساعة
      if (cachedDate.day == now.day && now.hour < 7) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } else {
        // اذا الساعة 7 أو التاريخ اختلف يمسح الكاش
        await prefs.remove('cachedProducts_${widget.subCategory}');
        await prefs.remove('cachedDate_${widget.subCategory}');
      }
    }
    return null;
  }
  Future<void> fetchProducts({bool loadMore = false}) async {
    if (allLoaded || isLoadingMore) return;
    setState(() {
      loadMore ? isLoadingMore = true : isLoading = true;
    });

    try {
      final cachedProducts = await loadProductsFromCache();

      if (cachedProducts != null) {
        setState(() {
          products = cachedProducts;
          filteredProducts = List.from(products);
          allLoaded = true;
          isLoading = false;
        });
        _initPriceRange();
      } else {
        // ⭐ هنا نقرأ ملف الجيسون المخزن بالجهاز بدل النت
        final directory = await getApplicationDocumentsDirectory();
        final jsonDir = Directory('${directory.path}/json_files');

        // ابحث عن أحدث ملف تم تحميله
        final files = jsonDir.listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList();

        if (files.isNotEmpty) {
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          final latestFile = files.first;

          final jsonString = await latestFile.readAsString();
          final Map<String, dynamic> data = json.decode(jsonString);

          final allProducts = data.entries
              .where((entry) {
            final category = entry.value['Category']?.toString().toLowerCase() ?? '';
            final matchesStart = category.startsWith(widget.subCategory.toLowerCase());

            final isSlipper = category.contains('slipper') ||
                category.contains('slippers') ||
                category.contains('نعال') ||
                category.contains('شحاط');

            if (widget.showOnlySlippers) {
              return matchesStart && isSlipper;
            } else {
              return matchesStart && !isSlipper;
            }
          })
              .map((entry) => {
            'id': entry.key,
            'name': entry.value['Name'] ?? 'اسم غير متوفر',
            'image': 'http://51.195.6.59/ToobacoNew/images/${entry.value['ART_NO']}.JPG',
            'price': entry.value['Price'] ?? 0,
            'category': entry.value['Category'] ?? 'غير متوفر',
            'ART_NO': entry.value['ART_NO'] ?? 'غير متوفر',
            'Size': entry.value['Size'] ?? 'غير متوفر',
            'key_serch': entry.value['key_serch'] ?? '',
          })
              .toList();



          final startIndex = currentPage * pageSize;
          final endIndex = (startIndex + pageSize < allProducts.length)
              ? startIndex + pageSize
              : allProducts.length;

          if (startIndex >= allProducts.length) {
            setState(() {
              allLoaded = true;
            });
          } else {
            setState(() {
              products.addAll(allProducts.sublist(startIndex, endIndex));
              filteredProducts = List.from(products);
              currentPage++;
              isLoading = false;
              isLoadingMore = false;
            });
          }

          // 🧠 حفظهم بالكاش مثل قبل
          if (products.isNotEmpty) {
            await saveProductsToCache(products);
          }
        } else {
          throw Exception('❌ لا توجد ملفات JSON محفوظة.');
        }
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      print('❌ Error fetching products: $error');
    }
  }



  void filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) =>
      product['name'].toLowerCase().contains(query.toLowerCase()) ||
          product['price'].toString().contains(query))
          .toList();
    });
  }

  void sortProducts(String order) {
    setState(() {
      filteredProducts.sort((a, b) => order == "asc"
          ? a['price'].compareTo(b['price'])
          : b['price'].compareTo(a['price']));
    });
  }

  void navigateToProductDetails(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          artNo: product['ART_NO'],
          category: product['category'],
        ),
      ),
    );
    setState(() {}); // ✅ يحدث اللون بعد الرجوع
  }

  Widget _buildShimmerLoader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), // يمنع التمرير أثناء التحميل
        itemCount: 6, // عدد كروت الشمر الوهمية
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns, // حسب عدد الأعمدة المختار
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: gridColumns == 1 ? 1.3 : gridColumns == 2 ? 1.0 : 0.85,
        ),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(color: Colors.white),
                ),
                Container(
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Colors.white,
                ),
                Container(
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تعديل نسبة العرض إلى الارتفاع بناءً على عدد الأعمدة:
    double aspectRatio;
    if (gridColumns == 1) {
      // في حالة عمود واحد، نستخدم نسبة عرض/ارتفاع أعلى لتقليل ارتفاع الكارت
      aspectRatio = 1.3;
    } else if (gridColumns == 2) {
      aspectRatio = 1.0;
    } else {
      aspectRatio = 0.85;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal, // ✅ نفس لون تفاصيل المنتج
        centerTitle: true,
        title: Text(
          widget.label,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white, // ✅ نفس لون النص
          ),
        ),
        // زر الرجوع ع اليمين (RTL)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // السلة تبقى ع اليسار
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              int totalItems = cartProvider.items.fold(0, (sum, item) => sum + item.quantity);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartScreen()),
                      );
                      setState(() {}); // ✅ يحدث الصفحة بعد الرجوع
                    },
                  ),
                  if (totalItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),



      body: isLoading
          ? _buildShimmerLoader()

          : Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: filterProducts,
              textDirection: ui.TextDirection.rtl,   // ✅ اتجاه النص RTL
              textAlign: TextAlign.right,            // ✅ محاذاة النص يمين
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                hintTextDirection: ui.TextDirection.rtl, // ✅ حتى النص الوهمي "ابحث عن منتج..." يظهر من اليمين
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // خيارات الترتيب وعدد الأعمدة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // قسم ترتيب السعر
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sort, color: Colors.teal, size: 20),
                        const SizedBox(width: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sortOrder,
                            items: const [
                              DropdownMenuItem(
                                value: "asc",
                                child: Text(
                                  "السعر: من الأقل للأعلى",
                                  style: TextStyle(  fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "desc",
                                child: Text(
                                  "السعر: من الأعلى للأقل",
                                  style: TextStyle( fontSize: 14),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  sortOrder = value;
                                  sortProducts(value);
                                });
                              }
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // فاصل عمودي بسيط
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey[400],
                  ),
                  // قسم عدد الأعمدة
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.view_column, color: Colors.teal, size: 20),
                        const SizedBox(width: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: gridColumns,
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  "1 عرض الصور ",
                                  style: TextStyle(  fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(
                                  "2 عرض الصور",
                                  style: TextStyle( fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(
                                  "3 عرض الصور",
                                  style: TextStyle(  fontSize: 14),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  gridColumns = value;
                                });
                              }
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.teal),
                    onPressed: () => _showPriceFilter(context),
                  ),

                ],
              ),
            ),
          ),

          // شبكة عرض المنتجات مع ScrollConfiguration لإخفاء تأثير overscroll
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!isLoadingMore &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent -
                            (scrollInfo.metrics.viewportDimension / 2)) {
                  fetchProducts(loadMore: true);
                }
                return true;
              },
              child: ScrollConfiguration(
                behavior: NoGlowScrollBehavior(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: filteredProducts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredProducts.length) {
                      return allLoaded
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "تم تحميل كل المنتجات المتاحة لهذه الفئة!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                 fontSize: 16),
                          ),
                        ),
                      )
                          : const Center(child: CircularProgressIndicator());
                    }
                    final product = filteredProducts[index];
                    final formattedPrice = NumberFormat('#,##0', 'ar')
                        .format(double.parse(product['price']) / 12);

                    // تغليف الكارت بالكامل بـ Directionality باستخدام ui.TextDirection.rtl
                    return Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: GestureDetector(
                        onTap: () => navigateToProductDetails(product),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: gridColumns == 1
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: product['image'],
                                      placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image, size: 60),
                                      fit: BoxFit.contain, // ✅ الصورة كاملة
                                      width: double.infinity,
                                      height: MediaQuery.of(context).size.height * 0.6, // ✅ تاخذ مساحة الشاشة
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isProductInCart(product['ART_NO'], context)
                                              ? Colors.yellow
                                              : Colors.teal,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          iconSize: 18,
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.shopping_cart,
                                              color: Colors.white, size: 18),
                                          onPressed: () {
                                            final cartProvider =
                                            Provider.of<CartProvider>(context, listen: false);
                                            final isInCart =
                                            isProductInCart(product['ART_NO'], context);

                                            if (isInCart) {
                                              cartProvider.removeItem(product['ART_NO']);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "❌ تم إزالة المنتج ${product['name']} من السلة.",
                                                  ),
                                                  duration: const Duration(milliseconds: 500),
                                                ),
                                              );
                                            } else {
                                              final cartItem = CartItem(
                                                id: product['ART_NO'],
                                                name: product['name'],
                                                image: product['image'],
                                                keySerch: product['key_serch'],
                                                price: double.tryParse(product['price'].toString()) ?? 0,
                                                quantity: 1,
                                              );
                                              cartProvider.addItem(cartItem);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "🛒 تم إضافة المنتج ${product['name']} إلى السلة.",
                                                  ),
                                                  duration: const Duration(milliseconds: 500),
                                                ),
                                              );
                                            }
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ✅ التفاصيل تبقى تحت الصورة
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'سعر القطعة: $formattedPrice د.ع',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.red, // ✅ أحمر لإبراز السعر
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                              : // عند عرض عمودين أو أكثر
                          Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white,
                                  child: CachedNetworkImage(
                                    imageUrl: product['image'],
                                    placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) {
                                      return Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {}); // يعيد بناء الصورة ويحاول تحميلها من جديد
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.refresh, color: Colors.red, size: 36),
                                              SizedBox(height: 4),
                                              Text(
                                                'اضغط لإعادة التحميل',
                                                style: TextStyle(fontSize: 12, color: Colors.black54 ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },

                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isProductInCart(product['ART_NO'], context) ? Colors.yellow : Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 14,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                      final isInCart = isProductInCart(product['ART_NO'], context);

                                      if (isInCart) {
                                        cartProvider.removeItem(product['ART_NO']);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "❌ تم إزالة المنتج ${product['name']} من السلة.",
                                            ),duration: const Duration(milliseconds: 500),
                                          ),
                                        );
                                      } else {
                                        final cartItem = CartItem(
                                          id: product['ART_NO'],
                                          name: product['name'],
                                          image: product['image'],
                                          keySerch: product['key_serch'],
                                          price: double.tryParse(product['price'].toString()) ?? 0,
                                          quantity: 1,
                                        );
                                        cartProvider.addItem(cartItem);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "🛒 تم إضافة المنتج ${product['name']} إلى السلة.",
                                            ), duration: const Duration(milliseconds: 500),
                                          ),
                                        );
                                      }

                                      setState(() {}); // ✅ لإعادة بناء اللون بعد التغيير
                                    },
                                  ),
                                ),
                              ),


                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
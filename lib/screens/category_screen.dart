import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ProductScreen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class CategoryScreen extends StatefulWidget {
  final String category;
  final String label;

  const CategoryScreen({
    Key? key,
    required this.category,
    required this.label,
  }) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  static const Map<String, String> categoryTranslations = {

    'Baby Boot': 'بوت بيبي',
    'Baby Boot Female': 'بوت بيبي بناتي',
    'Baby Boot Male': 'بوتت بيبي ولادي',
    'Baby Sandals Female': 'صندل بيبي بناتي',
    'Baby Sandals Male': 'صندل بيبي ولادي',
    'Baby Shoes': 'حذاء بيبي',
    'Baby Shoes Holes': 'مثقب حذاء بيبي',
    'Baby Slippers': 'نعال بيبي',
    'Baby Sport Holes': 'مثقب رياضي بيبي',
    'Baby Sport Shoes Female': 'حذاء رياضي بيبي بناتي',
    'Baby Sport Shoes Male': 'حذاء رياضي بيبي ولادي',
    'Boy Boot': 'بوت ولادي',
    'Boy Indoor Slippers': 'نعال منزلي ولادي',
    'Boy Sandals': 'صندل ولادي',
    'Boy Shoes': 'حذاء ولادي',
    'Boy Shoes Holes': 'مثقب حذاء ولادي',
    'Boy Slippers': 'نعال ولادي',
    'Boy Sport Shoes': 'حذاء رياضي ولادي',
    'Casual Bags': 'شنط كاجوال',
    'Child Boot Female': 'بوت طفلة',
    'Child Boot Male': 'بوت طفل',
    'Child Indoor Slippers': 'نعال منزلي أطفالي',
    'Child Sandals': 'صندل أطفالي',
    'Child Sandals Female': 'صندل طفلة',
    'Child Sandals Male': 'صندل طفل',
    'Child Shoes': 'حذاء أطفالي',
    'Child Shoes Female': 'حذاء طفلة',
    'Child Shoes Holes': 'مثقب حذاء أطفالي',
    'Child Shoes Male': 'حذاء طفل',
    'Child Shoes Sabow Female': 'نسائي سابو حذاء أطفالي',
    'Child Slippers Female': 'نعال طفلة',
    'Child Slippers Male': 'نعال طفل',
    'Child Sport Shoes': 'حذاء رياضي أطفالي',
    'Child Sport Shoes Female': 'حذاء رياضي طفلة',
    'Child Sport Shoes Male': 'حذاء رياضي طفل',
    'Girl Boot': 'بوت بناتي',
    'Girl Indoor Shoes': 'حذاء منزلي بناتي',
    'Girl Indoor Slippers': 'نعال منزلي بناتي',
    'Girl Sandals': 'صندل بناتي',
    'Girl Shoes': 'حذاء بناتي',
    'Girl Shoes Holes': 'مثقب حذاء بناتي',
    'Girl Shoes Sabow': 'سابو حذاء بناتي',
    'Girl Slippers': 'نعال بناتي',
    'Girl Sport Holes': 'مثقب رياضي بناتي',
    'Girl Sport Shoes': 'حذاء رياضي بناتي',
    'Lady Boot': 'بوت نسائي',
    'Lady Fashion Slippers': 'شحاطة نسائي اصلي',
    'Lady Handbag': 'حقيبة يد نسائي',
    'Lady Indoor Shoes': 'حذاء منزلي نسائي',
    'Lady Indoor Slippers': 'نعال منزلي نسائي',
    'Lady Sandals': 'صندل نسائي',
    'Lady Shoes': 'حذاء نسائي',
    'Lady Shoes Holes': 'مثقب حذاء نسائي',
    'Lady Shoes Sabow': 'سابو حذاء نسائي',
    'Lady Shoes Woven': 'محاك حذاء نسائي',
    'Lady Slippers': 'نعال نسائي',
    'Lady Slippers EVA': 'إيفا نعال نسائي',
    'Lady Slippers PVC': 'بي ڤي سي نعال نسائي',
    'Lady Sport Holes': 'مثقب رياضي نسائي',
    'Lady Sport Shoes': 'حذاء رياضي نسائي',
    'Men Boot': 'بوت رجالي',
    'Men Fashion Slippers': 'شحاطة رجالي اصلي',
    'Men Indoor Slippers': 'نعال منزلي رجالي',
    'Men Sandals': 'صندل رجالي',
    'Men Shoes': 'حذاء رجالي',
    'Men Shoes Holes': 'مثقب حذاء رجالي',
    'Men Slippers': 'شحاطة تركي رجالي',
    'Men Slippers EVA': 'إيفا نعال رجالي',
    'Men Slippers PVC': 'بي ڤي سي نعال رجالي',
    'Men Sport Shoes': 'حذاء رياضي رجالي',
    'School Bags': 'شنط مدرسية',
    'Travel Bags': 'شنط سفر',
    'Baby Sandals': 'صندل بيبي',
    'Baby Sport Shoes': 'حذاء رياضي بيبي',
    'Child Boot': 'بوت أطفالي',
    'Child Slippers': 'نعال أطفالي',
    'Young Boot': 'بوت شبابي',
    'Young Indoor Slippers': 'نعال منزلي شبابي',
    'Young Sandals': 'صندل شبابي',
    'Young Shoes': 'حذاء شبابي',
    'Young Shoes Holes': 'مثقب حذاء شبابي',
    'Young Slippers': 'نعال شبابي',
    'Young Sport Shoes': 'حذاء رياضي شبابي',
  };


  String? selectedCategoryId; // 🧠 لمعرفة أي كارت تم اختياره

  @override
  void initState() {
    super.initState();
    fetchCategories(); print(widget.category.toLowerCase());
  }
  String translateCategory(String key) {
    final cleanedKey = key.replaceAll(RegExp(r'[0-9]'), '').trim();
    return  categoryTranslations[cleanedKey] ?? cleanedKey;
  }

  Future<void> fetchCategories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final jsonFolder = Directory('${directory.path}/json_files');
      final files = jsonFolder.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        setState(() {
          isLoading = false;
          categories = [];
        });
        debugPrint('❌ لا توجد ملفات جيسون.');
        return;
      }

      // ترتيب الملفات وأخذ أحدث ملف
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestFile = files.first;

      final content = await latestFile.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final uniqueCategories = <String>{};

      final filteredCategories = data.entries
          .where((entry) =>
      entry.value['Category'] != null &&
          entry.value['Category'].toString().toLowerCase().contains(widget.category.toLowerCase()))
          .map((entry) {
        final category = entry.value['Category'];
        if (uniqueCategories.add(category)) {
          return {
            'id': entry.key,
            'category': category,
            'name': entry.value['Name'] ?? 'اسم غير متوفر',
          };
        }
        return null;
      })
          .where((item) => item != null)
          .toList();

      setState(() {
        categories = filteredCategories.cast<Map<String, dynamic>>();
        isLoading = false;
      });

      debugPrint('✅ تم تحميل التصنيفات بنجاح.');
    } catch (error) {
      debugPrint('❌ خطأ أثناء قراءة التصنيفات من الجيسون: $error');
      setState(() {
        isLoading = false;
        categories = [];
      });
    }
  }


  Widget _buildShimmerLoader() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6, // عدد الكروت الوهمية أثناء التحميل
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white, // بيكون مع الشمر مو واضح، طبيعي
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildCategoryIcon(String? categoryName) {
    final lowerCategory = categoryName?.toLowerCase() ?? '';

    if (lowerCategory.contains('slippers')) {
      return const FaIcon(FontAwesomeIcons.shoePrints, size: 20, color: Colors.red);
    } else if (lowerCategory.contains('bag')) {
      return const FaIcon(FontAwesomeIcons.bagShopping, size: 20, color: Colors.teal);
    } else {
      return const FaIcon(FontAwesomeIcons.shoePrints, size: 20, color: Colors.teal);
    }
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryId = category['id'];
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(
              subCategory: category['category'] as String,
              label: translateCategory(category['category'] as String),
            ),
          ),
        );
      },
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          gradient: (category['category'] as String).toLowerCase().contains('slippers')
              ? LinearGradient(
            colors: selectedCategoryId == category['id']
                ? [Colors.red.shade600, Colors.red.shade400]
                : [Colors.red.shade400, Colors.red.shade200],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          )
              : LinearGradient(
            colors: selectedCategoryId == category['id']
                ? [Colors.teal.shade600, Colors.teal.shade400]
                : [Colors.teal.shade300, Colors.teal.shade100],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selectedCategoryId == category['id']
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                ),
                child: Center(
                  child: _buildCategoryIcon(category['category']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  translateCategory(category['category']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading && categories.isNotEmpty) {
      categories.sort((a, b) {
        final aIsSlippers = (a['category'] as String).toLowerCase().contains('slippers');
        final bIsSlippers = (b['category'] as String).toLowerCase().contains('slippers');

        if (aIsSlippers && !bIsSlippers) return 1; // خلي a بعد b
        if (!aIsSlippers && bIsSlippers) return -1; // خلي a قبل b
        return 0; // لا تغير
      });
    }

    Widget _buildCategoryCard(Map<String, dynamic> category) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategoryId = category['id'];
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductScreen(
                subCategory: category['category'] as String,
                label: translateCategory(category['category'] as String),
              ),
            ),
          );
        },
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            gradient: (category['category'] as String).toLowerCase().contains('slippers')
                ? LinearGradient(
              colors: selectedCategoryId == category['id']
                  ? [Colors.red.shade600, Colors.red.shade400]
                  : [Colors.red.shade400, Colors.red.shade200],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            )
                : LinearGradient(
              colors: selectedCategoryId == category['id']
                  ? [Colors.teal.shade600, Colors.teal.shade400]
                  : [Colors.teal.shade300, Colors.teal.shade100],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: selectedCategoryId == category['id']
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
                : [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: Center(
                    child: _buildCategoryIcon(category['category']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    translateCategory(category['category']),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }


    print(widget.category.trim().split(' ').first);
    return Directionality(
      textDirection: TextDirection.ltr, // لضبط اتجاه النص من اليمين لليسار
      child:Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: true,
          title: Directionality(
            textDirection: TextDirection.rtl, // عرض النص من اليمين لليسار
            child: Text(
              'قسم ال${widget.label}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.teal,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFF5F5F5), // لون متناسق مع باقي الصفحات
          elevation: 0,
          iconTheme: const IconThemeData(color:Colors.teal),
        ),
       body: isLoading
          ? _buildShimmerLoader()

        : categories.isEmpty
            ? const Center(
          child: Text('لا توجد بيانات مطابقة لهذه الفئة',
              style: TextStyle(fontSize: 18)),
        )
            :  Column(
         children: [
           if ( widget.category.trim().split(' ').first !='Bags') ...[
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Directionality(
                 textDirection: TextDirection.rtl,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: const [
                     Text(
                       'الاقسام الرئيسية',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     SizedBox(height: 4),
                     Divider(thickness: 1, color: Colors.teal),
                   ],
                 ),
               ),
             ),

             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
               child: Row(
                 children: [
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () {
                         final String base = widget.category.trim().split(' ').first;
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => ProductScreen(
                               subCategory: base,
                               label: 'شحاطات $base فقط',
                               showOnlySlippers: true,
                             ),
                           ),
                         );
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.red.shade400,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                         padding: const EdgeInsets.symmetric(vertical: 14),
                       ),
                       child: const Text('لاستيك', style: TextStyle(fontSize: 16, color: Colors.white)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () {
                         final String base = widget.category.trim().split(' ').first;
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => ProductScreen(
                               subCategory: base,
                               label: 'أحذية $base فقط',
                               showOnlySlippers: false,
                             ),
                           ),
                         );
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.teal.shade400,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                         padding: const EdgeInsets.symmetric(vertical: 14),
                       ),
                       child: const Text('أحذية', style: TextStyle(fontSize: 16, color: Colors.white)),
                     ),
                   ),
                 ],
               ),
             ),

             const SizedBox(height: 25),
           ],


// ✅ عنوان الأقسام العامة RTL مع خط تحته
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Directionality(
               textDirection: TextDirection.rtl,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start, // يظل ثابت حتى يبدأ النص من اليمين
                 children: const [
                   Text(
                     'الأقسام العامة',
                     style: TextStyle(
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   SizedBox(height: 4),
                   Divider(thickness: 1, color: Colors.teal),
                 ],
               ),
             ),
           ),


           // ✅ القائمة الرئيسية للتصنيفات
           Expanded(
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: ListView.separated(
                 separatorBuilder: (context, index) => const SizedBox(height: 16),
                 itemCount: categories.length,
                 itemBuilder: (context, index) {
                   final category = categories[index];
                   return _buildCategoryCard(category);
                 },
               ),
             ),
           ),
         ],
       ),
      ),
    );
  }
}

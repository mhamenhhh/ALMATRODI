import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'CartScreen.dart';
import 'CustomerDetailsScreen.dart';
import 'bottom_bar.dart';
import 'cart_provider.dart';
import 'category_screen.dart';
import 'order_history_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int activeIndex = 3;

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Men', 'icon': Icons.male, 'label': 'رجالي'},
    {'name': 'Lady', 'icon': Icons.female, 'label': 'نسائي'},
    {'name': 'Young', 'icon': Icons.person, 'label': 'شبابي'},
    {'name': 'Boy', 'icon': Icons.child_care, 'label': 'ولادي'},
    {'name': 'Girl', 'icon': Icons.female, 'label': 'بناتي'},
    {'name': 'Child', 'icon': Icons.child_friendly, 'label': 'أطفالي'},
    {'name': 'Baby', 'icon': Icons.baby_changing_station, 'label': 'بيبي'},
    {'name': 'Bags', 'icon': Icons.work, 'label': 'حقائب'},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.teal.shade600,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
              : null,
          title: const Text(
            'الأقسام الرئيسية',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.right,
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(
                              category: category['name'] as String,
                              label: category['label'] as String,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.shade100,
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category['icon'], size: 40, color: Colors.teal.shade800),
                            const SizedBox(height: 8),
                            Text(
                              category['label'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }
}


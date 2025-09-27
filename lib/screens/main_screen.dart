import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/CartScreen.dart';
import '../screens/CustomerDetailsScreen.dart';
import '../screens/bottom_bar.dart';
import 'NotificationPage.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => MainScreenState(); // ✅ تعديل هنا
}

class MainScreenState extends State<MainScreen> {
  late int activeIndex;
  bool refreshTrigger = false; // 🟢 متغير علشان نحفز NotificationPage تعيد التحميل

  @override
  void initState() {
    super.initState();
    activeIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen2(),           // index 0 الرئيسية
      const CartScreen(),            // index 1 الطلبات
      const HomeScreen(),            // index 2 الحجز
      const CustomerDetailsScreen(), // index 3 الحساب
      NotificationPage(refreshTrigger: refreshTrigger), // index 4 الإشعارات
    ];


    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomBar.build(
        context,
        activeIndex,
            (index) {
          setState(() {
            activeIndex = index;
            if (index == 4) {
              // 🟢 كل مرة يفتح تبويب الإشعارات نقلب قيمة المتغير
              refreshTrigger = !refreshTrigger;
            }
          });
        },
      ),
    );
  }
}

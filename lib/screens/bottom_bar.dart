import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../screens/cart_provider.dart';

class CustomBottomBar {
  static Widget build(
      BuildContext context,
      int activeIndex,
      Function(int) onTabTapped, {
        int unreadNotifications = 0,
      }) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        int totalItems =
        cartProvider.items.fold(0, (sum, item) => sum + item.quantity);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: ConvexAppBar(
          style: TabStyle.fixedCircle,
          backgroundColor: Colors.white,
          activeColor: Colors.teal,    // ✅ الأيقونة والنص لما يكون التاب مفعل
          color: Colors.black54,       // ✅ الأيقونة والنص لما يكون غير مفعل
          elevation: 10,
          items: [
            TabItem(
              icon: Icon(Icons.home,
                  color: activeIndex == 0 ? Colors.teal : Colors.black54),
              title: 'الرئيسية',
            ),


            TabItem(
              icon: _buildCartIconWithBadge(totalItems, activeIndex == 1),
              title: 'الطلبات',
            ),

            // زر الحجز بالنص (لون مميز)
            TabItem(
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF009688), // Teal أساسي
                      Color(0xFF00796B), // Teal أغمق
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              title: 'حجز',
            ),




            // الحساب (خليته يتبع نفس الستايل)
            TabItem(
              icon: Icon(Icons.person,
                  color: activeIndex == 3 ? Colors.teal : Colors.black54), // ✅
              title: 'الحساب',
            ),

            TabItem(
              icon: _buildNotificationIconWithBadge(
                  unreadNotifications, activeIndex == 4),
              title: 'الإشعارات',
            ),
          ],
          initialActiveIndex: activeIndex,
          onTap: (index) {
            if (index != activeIndex) {
              onTabTapped(index);
            }
          },
        ),

        );
      },
    );
  }

  static Widget _buildCartIconWithBadge(int count, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(Icons.shopping_cart,
            color: isActive ? Colors.teal : Colors.grey, size: 24),
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildNotificationIconWithBadge(int count, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(Icons.notifications,
            color: isActive ? Colors.teal : Colors.grey, size: 24),
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import 'main_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({Key? key}) : super(key: key);

  @override
  _CustomerDetailsScreenState createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  Map<String, dynamic>? customerData;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String appVersion = '';
  String customerId = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _initializePage();
  }

  /// ✅ جلب نسخة التطبيق
  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  /// ✅ التهيئة
  Future<void> _initializePage() async {
    await _checkLoginStatus();
    await _loadCustomerFromFirebase();
  }

  /// ✅ التحقق من حالة تسجيل الدخول
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLogged') ?? false;
      customerId = prefs.getString('customer_id') ?? '';
    });
  }

  /// ✅ تحميل بيانات الزبون من Firebase
  Future<void> _loadCustomerFromFirebase() async {
    if (customerId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/customers/$customerId.json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body);
        setState(() {
          customerData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ لم يتم العثور على الزبون في قاعدة البيانات')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ خطأ في الاتصال: $e')),
      );
    }
  }

  /// ✅ تسجيل الخروج ومسح كل الكاش
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🧹 يمسح كل بيانات الكاش

    setState(() {
      _isLoggedIn = false;
      customerData = null;
      customerId = '';
    });

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          automaticallyImplyLeading: false,
          title: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'معلومات الزبون',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      if (_isLoggedIn) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: const Text('تأكيد تسجيل الخروج',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            );
                          },
                        );
                        if (confirm == true) {
                          await _logout();
                        }
                      } else {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: Icon(_isLoggedIn ? Icons.logout : Icons.login,
                        color: Colors.white, size: 22),
                    label: Text(
                      _isLoggedIn ? 'تسجيل الخروج' : 'تسجيل دخول',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(10, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainScreen(initialIndex: 0)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : customerData == null
            ? const Center(child: Text("🚫 لم يتم تحميل بيانات الزبون"))
            : _buildCustomerContent(),
      ),
    );
  }

  /// ✅ واجهة عرض البيانات
  Widget _buildCustomerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('معلومات الزبون', icon: Icons.person),
          const SizedBox(height: 10),
          _buildInfoCard(Icons.person, 'الاسم',
              customerData?['acc_arabic_name'] ?? '—'),
          _buildInfoCard(
            Icons.location_on,
            'العنوان',
            '${customerData?['province'] ?? ''}'
                '${customerData?['province'] != null && customerData?['province'] != '' ? " - " : ""}'
                '${customerData?['address'] ?? '—'}',
          ),

          _buildInfoCard(Icons.phone, 'الهاتف',
              customerData?['phone'] ?? '—'),
          _buildInfoCard(Icons.badge, 'رقم الزبون',
              customerData?['acc_code'] ?? '—'),
          _buildInfoCard(Icons.date_range, 'تاريخ التسجيل بالوكالة',
              customerData?['creation_date'] ?? '—'),
          _buildInfoCard(Icons.date_range, 'تاريخ اخر تسديد',
              customerData?['last_pay_in_date'] ?? '—'),
          _buildInfoCard(Icons.monetization_on, 'مجموع الدين الحالي',
              '${formatNumber(customerData?['total_credit'] ?? 0)} د.ع'),
          _buildInfoCard(Icons.verified, 'إصدار التطبيق', appVersion),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
        ),
      ],
    );
  }

  /// ✅ تنسيق الأرقام (مثلاً: 120000 → 120,000)
  String formatNumber(dynamic number) {
    String str = number.toString();
    str = str.split(".")[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}

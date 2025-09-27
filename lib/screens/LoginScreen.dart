import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:new_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'RegisterScreen.dart';
import 'notification_token_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true; // ← جديد
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _initApp(); // ← استدعاء التهيئة
  }

  Future<void> _initApp() async {
    await fetchCustomers();        // ← أولًا تحميل الزبائن
    await _checkRememberedLogin(); // ← ثم التحقق من الجلسة المحفوظة
  }



  Future<void> _checkRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('isLogged') ?? false;
    final phone = prefs.getString('phone');
    final password = prefs.getString('password');

    if (isLogged && phone != null && password != null) {
      final matched = _customers.any((cust) =>
      cust['phone'] == phone && cust['password'] == password);
      if (matched) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> fetchCustomers() async {
    final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/customers.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<Map<String, dynamic>> loaded = [];
        data.forEach((key, value) {
          final rawPhone = (value['phone'] ?? '').replaceAll(RegExp(r'\D'), '');
          final normalizedPhone = rawPhone.length >= 10 ? rawPhone.substring(rawPhone.length - 10) : rawPhone;
          loaded.add({
            'id': key,
            'name': value['acc_arabic_name'],
            'phone': normalizedPhone,   // ← نخزن آخر 10 أرقام فقط
            'password': value['password'],
            'acc_serial': value['acc_serial'],
            'acc_code': value['acc_code'],
            'creation_date': value['creation_date'],
            'address': value['address'],
          });
        });
        setState(() {
          _customers = loaded;
        });
      }
    } catch (e) {
      print('خطأ أثناء تحميل الزبائن: $e');
    }
  }

  void _login() async {
    final rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = rawPhone.length >= 10 ? rawPhone.substring(rawPhone.length - 10) : rawPhone;
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الهاتف وكلمة المرور')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final matchedCustomer = _customers.firstWhere(
          (cust) => cust['phone'] == phone && cust['password'] == password,
      orElse: () => {},
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (matchedCustomer.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('phone', phone);
      prefs.setString('password', password);
      prefs.setString('customer_name', matchedCustomer['name'] ?? 'الزبون');
      prefs.setString('customer_id', matchedCustomer['id'] ?? '');
      prefs.setString('acc_serial', (matchedCustomer['acc_serial'] ?? '').toString());
      prefs.setString('acc_code', (matchedCustomer['acc_code'] ?? '').toString());
      prefs.setString('creation_date', (matchedCustomer['creation_date'] ?? '').toString());
      prefs.setString('address', matchedCustomer['address'] ?? '');
      prefs.setBool('isLogged', true);

      // ✅ توليد التوكن
      final customerKey = matchedCustomer['id'];
      if (customerKey != null && customerKey.isNotEmpty) {
        final tokenManager = NotificationManager(customerKey);
        await tokenManager.generateAndSyncToken();
      }

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بيانات غير صحيحة أو الزبون غير موجود')),
      );
    }

    setState(() {
      _isLoading = false;


    });
  }




  @override
  Widget build(BuildContext context) {
    return   WillPopScope(
        onWillPop: () async => false,
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
         automaticallyImplyLeading: false, // ✅ يخفي سهم الرجوع
          centerTitle: true,
          title: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Cairo',
              color: Color(0xFF1B2A4E),
            ),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1B2A4E)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                    labelText: 'رقم الهاتف',
                    labelStyle: TextStyle(color: Colors.teal[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // ← بدل true ثابتة
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                    labelText: 'كلمة المرور',
                    labelStyle: TextStyle(color: Colors.teal[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    // 👇 زر إظهار/إخفاء
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isRememberMe,
                          onChanged: (value) {
                            setState(() {
                              _isRememberMe = value!;
                            });
                          },
                          activeColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const Text(
                          'تذكرني',
                          style: TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final inputPhone = _phoneController.text.trim();
                        if (inputPhone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال رقم الهاتف أولاً')),
                          );
                          return;
                        }
                        final adminPhone = "07714651873".replaceFirst('0', '964');
                        final message = Uri.encodeComponent("طلب إعادة تعيين كلمة المرور للرقم: $inputPhone");
                        final url = Uri.parse("https://wa.me/$adminPhone?text=$message");
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    const Text(
                      "لا تملك حساباً؟",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        "إنشاء حساب جديد",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700], // لون دافئ مميز
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ), ),
    ),
    );
  }
}

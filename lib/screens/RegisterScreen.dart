import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_token_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // 👁 لإظهار/إخفاء كلمة المرور

  final List<String> _provinces = [
    "بغداد", "البصرة", "نينوى", "الأنبار", "أربيل", "كركوك",
    "السليمانية", "ذي قار", "النجف", "كربلاء", "بابل", "واسط",
    "صلاح الدين", "ديالى", "دهوك", "ميسان", "المثنى", "القادسية"
  ];
  String? _selectedProvince;

  // ✅ استخراج آخر 10 أرقام
  String normalizePhone(String phone) {
    final raw = phone.replaceAll(RegExp(r'\D'), ''); // حذف أي رموز
    return raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
  }

  // ✅ التحقق أن الرقم غير مكرر
  Future<bool> _isPhoneUnique(String phone10) async {
    final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/customers.json');
    final response = await http.get(url);

    if (response.statusCode == 200 && response.body != "null") {
      final data = json.decode(response.body) as Map<String, dynamic>;
      for (var value in data.values) {
        final existingPhone = normalizePhone(value['phone'] ?? '');
        if (existingPhone == phone10) {
          return false; // مكرر
        }
      }
    }
    return true; // جديد
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار المحافظة")),
      );
      return;
    }

    // 🟢 تجهيز الرقم → نخزن آخر 10 أرقام فقط
    final phone10 = normalizePhone(_phoneController.text.trim());

    if (phone10.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ رقم الهاتف غير صالح")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ✅ تحقق إذا الرقم مكرر
    final isUnique = await _isPhoneUnique(phone10);
    if (!isUnique) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ هذا الرقم مسجل مسبقًا")),
      );
      return;
    }

    final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/customers.json');

    final newCustomer = {
      "acc_arabic_name": _nameController.text.trim(),
      "phone": phone10, // 🟢 نخزن آخر 10 أرقام
      "password": _passwordController.text.trim(),
      "address": _addressController.text.trim(),
      "province": _selectedProvince,
      "creation_date": DateTime.now().toString().split('.')[0],
      "acc_serial": "",
      "acc_code": "",
      "book_no": "",
      "total_credit": "",
      "last_pay_in_date": "",
    };

    try {
      final response = await http.post(url, body: json.encode(newCustomer));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final customerId = responseData['name'];

        final prefs = await SharedPreferences.getInstance();
        prefs.setString("phone", phone10);
        prefs.setString("password", _passwordController.text.trim());
        prefs.setString("customer_name", _nameController.text.trim());
        prefs.setString("address", _addressController.text.trim());
        prefs.setString("province", _selectedProvince!);
        prefs.setString("customer_id", customerId);
        prefs.setBool("isLogged", true);

        final tokenManager = NotificationManager(customerId);
        await tokenManager.generateAndSyncToken();

        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم إنشاء الحساب بنجاح")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ فشل التسجيل: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ خطأ: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'إنشاء حساب جديد',
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
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: const Icon(Icons.person, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "الرجاء إدخال الاسم" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: "077xxxxxxx", // 👈 Hint
                      prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "الرجاء إدخال رقم الهاتف" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      // 👁 زر إظهار/إخفاء كلمة المرور
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
                    validator: (v) => v!.length < 4 ? "كلمة المرور قصيرة" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "المحافظة",
                      prefixIcon: const Icon(Icons.map, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    value: _selectedProvince,
                    items: _provinces
                        .map((prov) => DropdownMenuItem(
                      value: prov,
                      child: Text(prov),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedProvince = value);
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("إنشاء الحساب"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_app/screens/CustomerOptionsScreen.dart';
import 'package:new_app/screens/PromoSlider.dart';
import 'package:new_app/screens/SplashScreen.dart';
import 'package:new_app/screens/main_screen.dart';
import 'package:new_app/screens/notification_token_manager.dart';
import 'package:new_app/screens/onboarding_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'screens/CustomerDetailsScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/category_screen.dart';
import 'screens/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/json_downloader_manager.dart';
import 'screens/order_history_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔔 تهيئة إشعارات النظام المحلي
Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 👇 تعريف الـ channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // نفس الـ id مالك
    'اشعارات مهمة',
    description: 'هذا القناة للإشعارات المهمة',
    importance: Importance.max,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(channel);
}


// 🔔 إظهار إشعار محلي (للـ Foreground فقط)
void showCustomNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'اشعارات مهمة',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
  );
}

// 📝 تخزين إشعار في SharedPreferences
Future<void> saveNotification(String title, String body) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> savedData = prefs.getStringList("notifications") ?? [];

  final newNotif = {
    "title": title,
    "body": body,
    "time": DateTime.now().toString().substring(0, 16),
  };

  savedData.insert(0, json.encode(newNotif)); // الأحدث أولاً
  await prefs.setStringList("notifications", savedData);
}

// 🔔 معالج الخلفية (Background / Terminated)
// 🔔 معالج الخلفية (Background / Terminated)
// لازم top-level
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final title = message.data['title'] ?? "إشعار";
  final body  = message.data['body'] ?? "";

  // 📝 خزن
  final prefs = await SharedPreferences.getInstance();
  List<String> savedData = prefs.getStringList("notifications") ?? [];
  final newNotif = {
    "title": title,
    "body": body,
    "time": DateTime.now().toString().substring(0, 16),
  };
  savedData.insert(0, json.encode(newNotif));
  await prefs.setStringList("notifications", savedData);

  // 🔔 اعرضه عالشاشة
  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'اشعارات مهمة',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const notifDetails = NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notifDetails,
  );

  print("📥 [Background] إشعار محفوظ وظهر: $title - $body");
}









void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initLocalNotifications();
  await JsonDownloaderManager.requestNotificationPermission();
  await JsonDownloaderManager.downloadJsonNow();

  // 🟢 مهم جداً: اربط المعالج
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final String? customerKey = prefs.getString("customer_id");
  if (customerKey != null) {
    final tokenManager = NotificationManager(customerKey);
    await tokenManager.generateAndSyncToken();
    await tokenManager.tryResendPendingToken();
  } else {
    print("🚫 لم يتم العثور على customer_id");
  }

  await FirebaseMessaging.instance.requestPermission();

  // 🔔 Foreground Notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? "إشعار";
    final body  = message.notification?.body ?? message.data['body'] ?? "";

    showCustomNotification(title, body);
    await saveNotification(title, body);

    print("✅ [Foreground] إشعار محفوظ: $title - $body");
  });




  // 📬 عند الضغط على الإشعار
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final action = message.data['action'];
    if (action == 'open_customer_options') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const CustomerOptionsScreen()),
      );
    }
    if (action == 'open_home_page') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      );
    }
  });



  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyWholesaleShoeApp(),
    ),
  );
}

class MyWholesaleShoeApp extends StatelessWidget {
  const MyWholesaleShoeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'المطرودي للأحذية بالجملة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue.shade900,
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

// ✅ باقي كود HomeScreen2 و AccountOrdersSection و غيرها كما هو عندك




class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  _HomeScreen2State createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  String? _customerName;
  bool _isLoggedIn = false;


  @override
  void initState() {
    super.initState();
    _loadCustomerData();
    Future.delayed(Duration.zero, () async {
      final info = await PackageInfo.fromPlatform();
      print("📦 النسخة الحالية للتطبيق: ${info.version}");
    });
    // ننتظر لحين اكتمال البناء ثم نظهر التنبيه
    //Future.delayed(const Duration(seconds: 1), () {
    //  UpdateChecker.checkAndShowUpdate(context);
    //});
  }





  Future<void> _loadCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerName = prefs.getString('customer_name') ?? 'الزبون';
      _isLoggedIn = prefs.getBool('isLogged') ?? false;

    });
  }




  // قائمة الأقسام باستخدام الأيقونات
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


  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضبط اتجاه النص من اليمين لليسار
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFF5F5F5),
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                  ),

                  const SizedBox(width: 10),

                  const Text(
                     'وكالة المطرودي للأحذية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:    Colors.teal,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              _isLoggedIn
                  ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerDetailsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.teal, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _customerName != null
                            ? (_customerName!.length > 12
                            ? '${_customerName!.substring(0, 12)}...'
                            : _customerName!)
                            : '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.login, color: Colors.green),
                label: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(color: Colors.green),
                ),
              ),



            ],
          ),
        ),



        // لم نستخدم Drawer هنا حتى تكون الصفحات ضمن الصفحة الرئيسية
        body: SingleChildScrollView(
          child: Column(
            children: [
              // شريط البحث
              /*Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الموديل أو الفئة...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),*/
              PromoSlider(), // مباشرة داخل أي `Column` أو `ListView`

              const SizedBox(height: 10),
              // عنوان قسم الأقسام مع زر "عرض الكل"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الأقسام',
                      style: TextStyle(
                        fontSize: 20, color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                      child: const Text(
                        'عرض الكل',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // شريط تمرير أفقي لعرض الأقسام
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 700 + index * 100),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform(
                        transform: Matrix4.identity()
                          ..translate(0.0, (1 - value) * 30)  // Slide down
                          ..scale(value, value),             // Scale in
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),

                      );
                    },
                    child: CategoryIconCard(
                      categoryName: categories[index]['label'] as String,
                      iconData: categories[index]['icon'] as IconData,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(
                              category: categories[index]['name'] as String,
                              label: categories[index]['label'] as String,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),



              const SizedBox(height: 1),

              // قسم الوصول السريع إلى "حساباتي" و"طلباتي" ضمن الصفحة الرئيسية
                AccountOrdersSection(),
              const SizedBox(height: 1),
              // يمكنك إضافة شبكة عرض المنتجات هنا...
              // قسم معلومات الشركة
              const CompanyInfoSection(),
              const SizedBox(height: 1),
            ],
          ),
        ),
        // شريط تنقل سفلي للتطبيق (يمكنك الاحتفاظ به أو تعديله)



      ),
    );
  }
}

// بطاقة القسم الخاصة بالأيقونات
class CategoryIconCard extends StatelessWidget {
  final String categoryName;
  final IconData iconData;
  final VoidCallback onTap;

  const CategoryIconCard({
  super.key,
  required this.categoryName,
  required this.iconData,
  required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 40, color: Colors.teal),
            const SizedBox(height: 5),
            Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
class CompanyInfoSection extends StatefulWidget {
  const CompanyInfoSection({super.key});

  @override
  State<CompanyInfoSection> createState() => _CompanyInfoSectionState();
}

class _CompanyInfoSectionState extends State<CompanyInfoSection> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // 🟡 قللنا الهوامش
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF5B996E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'وكالة المطرودي للأحذية',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const InfoRow(
              icon: Icons.location_on,
              text: 'سوق الذهب - عشار - البصرة',
            ),
            const InfoRow(
              icon: Icons.remove_red_eye,
              text: 'رؤيتنا: الجودة والسعر والخدمة المميزة',
            ),
            const InfoRow(
              icon: Icons.phone,
              text: '07714651873',
            ),
            const SizedBox(height: 1),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://wa.me/9647714651873');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('تواصل معنا'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ مكون مساعد لعرض كل سطر معلومات
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}





// قسم للوصول السريع إلى "حساباتي" و"طلباتي" ضمن الصفحة الرئيسية
class AccountOrdersSection extends StatelessWidget {
    AccountOrdersSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // بطاقة "حساباتي"
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerOptionsScreen()),
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        "حساباتي",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // بطاقة "طلباتي"
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>   OrderHistoryScreen()),
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_cart, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        "طلباتي",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "👋 مرحباً بك",
      "desc": "اكتشف أجمل موديلات الأحذية بالجملة، واحجز بسهولة خلال ثواني.",
      "image": "assets/images/images1.jpg"
    },
    {
      "title": "👟 اختَر تصنيفك المفضل",
      "desc": "تصفح الموديلات حسب النوع: رجالي، نسائي، ولادي...",
      "image": "assets/images/images2.jpg"
    },
    {
      "title": "🛒 احجز الكمية اللي تعجبك",
      "desc": "اختر الموديل، حدد عدد الكراتين، واضغط زر \"حجز\".",
      "image": "assets/images/images3.jpg"
    },
    {
      "title": "✅ تابع حالة طلبك",
      "desc": "بعد الحجز، نراجع طلبك ونوصلك بالتفاصيل عبر واتساب.",
      "image": "assets/images/images4.jpg"
    },
  ];

  Future<void> completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    final isLogged = prefs.getBool('isLogged') ?? false;

    if (isLogged) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) => OnboardContent(
                  title: onboardingData[index]['title']!,
                  desc: onboardingData[index]['desc']!,
                  image: onboardingData[index]['image']!,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                    (index) => buildDot(index),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.teal,
                    iconSize: 24,
                    onPressed: currentPage > 0
                        ? () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                        : null,
                  ),
                  currentPage == onboardingData.length - 1
                      ? ElevatedButton(
                    onPressed: completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("ابدأ الآن",style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                      : IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: Colors.teal,
                    iconSize: 24,
                    onPressed: () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.teal : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardContent extends StatelessWidget {
  final String title, desc, image;

  const OnboardContent({
    Key? key,
    required this.title,
    required this.desc,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

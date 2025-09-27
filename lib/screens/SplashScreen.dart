import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _textController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // الشعار
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // النص
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimations();
    _checkLoginStatus();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('isLogged') ?? false;
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (!onboardingSeen) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, isLogged ? '/home' : '/login');
    }
  }


  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50, // خلفية ناعمة
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 200,
                      fit: BoxFit.contain,
                    )

                  ),



                ),
              ),
            ),
            const SizedBox(height: 25),
            SlideTransition(
              position: _slideAnimation,
              child: const Text(
                'المطرودي للأحذية',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.teal,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

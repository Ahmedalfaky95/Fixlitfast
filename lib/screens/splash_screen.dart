import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/my_button.dart';
import 'admin/admin_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// شاشة البداية المتحركة.
///
/// بعد انتهاء الحركة: إذا كان المستخدم مسجلاً مسبقاً ننقله مباشرة إلى
/// الصفحة الرئيسية (أو لوحة المسؤول)، وإلا إلى شاشة الترحيب.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _fontSize = 2; // يتحكم في ارتفاع الجزء العلوي (height / _fontSize)
  double _containerSize = 1.5; // يتحكم في حجم الشعار (width / _containerSize)
  double _textOpacity = 0.0;
  double _containerOpacity = 0.0;

  // نحتفظ بالمؤقتات لإلغائها في dispose. بدون ذلك قد يُستدعى setState
  // أو Navigator بعد إغلاق الشاشة فيحدث خطأ.
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();

    // إظهار النص بعد أول إطار (بدل setState في كل إطار من AnimationController).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _textOpacity = 1.0);
    });

    _timers.add(Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _fontSize = 1.06;
        _containerSize = 2;
        _containerOpacity = 1;
      });
    }));

    _timers.add(Timer(const Duration(seconds: 4), _goNext));
  }

  /// تحديد الشاشة التالية حسب حالة تسجيل الدخول.
  Future<void> _goNext() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    Widget next;
    if (user == null) {
      next = const WelcomeScreen();
    } else if (await auth.checkAdminRole(user.uid)) {
      next = const AdminScreen();
    } else {
      next = const HomeScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, PageTransition(next));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  /// **دالة _getResponsiveFontSize**
  ///
  /// وظيفتها: حساب حجم الخط المناسب بناءً على عرض الشاشة لضمان التجاوب.
  double _getResponsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.8; // شاشات صغيرة
    if (screenWidth > 600) return baseSize * 1.2; // شاشات كبيرة
    return baseSize;
  }

  @override
  // **دالة بناء واجهة المستخدم (Build Method) لشاشة Splash**
  //
  // وظيفتها: بناء الـ Widget tree وعرض الرسوم المتحركة.
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          Column(
            children: [
              // حاوية متحركة لتغيير ارتفاع الجزء العلوي (تأثير نزول النص)
              AnimatedContainer(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                // يتم التحكم في الارتفاع عن طريق متغير _fontSize
                height: screenHeight / _fontSize,
              ),
              // نص 'FixItFast' يظهر تدريجياً
              AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _textOpacity, // يتم التحكم في الشفافية عبر الـ AnimationListener
                child: Text(
                  'FixItFast',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    // استخدام دالة متجاوبة لحجم الخط
                    fontSize: _getResponsiveFontSize(screenWidth, 30),
                  ),
                ),
              ),
            ],
          ),
          Center(
            // حاوية متحركة للشعار تظهر في المنتصف وتتغير في الحجم والشفافية
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.fastLinearToSlowEaseIn,
              opacity: _containerOpacity, // يتم التحكم فيها عبر المؤقت الزمني
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                // يتم التحكم في الحجم عن طريق متغير _containerSize
                height: screenWidth / _containerSize,
                width: screenWidth / _containerSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Image.asset(
                  'images/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------

/// **PageTransition Class**
///
/// وظيفتها: إنشاء انتقال مخصص (Custom Transition) للصفحات
/// باستخدام تأثير `SizeTransition` من الأسفل إلى الأعلى.
class PageTransition extends PageRouteBuilder {
  final Widget page;

  /// **دالة بناء (Constructor) لـ PageTransition**
  ///
  /// وظيفتها: تهيئة مسار الصفحة وتحديد مدة ونوع الانتقال.
  PageTransition(this.page)
      : super(
          pageBuilder: (context, animation, anotherAnimation) => page,
          transitionDuration: const Duration(milliseconds: 2000),
          transitionsBuilder: (context, animation, anotherAnimation, child) {
            // تطبيق منحنى السرعة على الرسوم المتحركة
            animation = CurvedAnimation(
              curve: Curves.fastLinearToSlowEaseIn,
              parent: animation,
            );
            return Align(
              alignment: Alignment.bottomCenter,
              // استخدام SizeTransition لتغيير حجم الشاشة أثناء الانتقال
              child: SizeTransition(
                sizeFactor: animation, // ربط عامل الحجم بالرسوم المتحركة
                axisAlignment: 0,
                child: page,
              ),
            );
          },
        );
}

// --------------------------------------------------------------------------

/// **WelcomeScreen Widget**
///
/// وظيفتها: الشاشة الترحيبية بعد شاشة البداية، تعرض وصف التطبيق
/// وزر "Get Started" للانتقال إلى شاشة تسجيل الدخول.
class WelcomeScreen extends StatelessWidget {
  final String appDescription =
      "Manage and track all your community complaints easily";

  const WelcomeScreen({super.key});

  @override
  // **دالة بناء واجهة المستخدم (Build Method) لشاشة SecondPage**
  //
  // وظيفتها: بناء الـ Widget tree للشاشة الترحيبية مع الأخذ في الاعتبار التجاوب مع مختلف أحجام الشاشات.
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isLargeScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            // استخدام دالة متجاوبة للهامش الأفقي
            horizontal: _getResponsivePadding(screenSize.width),
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // ضمان أن Column يملأ الشاشة بالحد الأدنى
              minHeight: screenSize.height -
                  MediaQuery.of(context).padding.vertical -
                  40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // بناء قسم الشعار
                _buildLogoSection(screenSize, isSmallScreen),

                SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                // بناء قسم محتوى النص (العنوان والوصف)
                _buildTextContentSection(isSmallScreen, isLargeScreen),

                SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                // بناء قسم الزر
                _buildButtonSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **دالة _buildLogoSection**
  ///
  /// وظيفتها: بناء ويدجت الشعار مع حجم متجاوب.
  Widget _buildLogoSection(Size screenSize, bool isSmallScreen) {
    final double logoSize = isSmallScreen ? 150 : 200;

    return ClipOval(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 2000),
        child: Container(
          width: logoSize,
          height: logoSize,
          color: Colors.blueGrey,
          child: Image.asset(
            'images/Logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// **دالة _buildTextContentSection**
  ///
  /// وظيفتها: بناء ويدجت محتوى النص (العنوان والوصف) بترتيب عمودي.
  Widget _buildTextContentSection(bool isSmallScreen, bool isLargeScreen) {
    return Column(
      children: [
        Text(
          "Complaint Management App",
          textAlign: TextAlign.center,
          style: TextStyle(
            // تحديد حجم الخط بناءً على حجم الشاشة
            fontSize: isSmallScreen ? 20 : (isLargeScreen ? 30 : 25),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // عرض نصوص الوصف المتجاوبة
        ..._buildDescriptionTexts(isSmallScreen, isLargeScreen),
      ],
    );
  }

  /// **دالة _buildDescriptionTexts**
  ///
  /// وظيفتها: تقسيم نص الوصف وعرضه في عدة نصوص (Texts) بشكل متجاوب.
  List<Widget> _buildDescriptionTexts(bool isSmallScreen, bool isLargeScreen) {
    final double fontSize = isSmallScreen ? 16 : (isLargeScreen ? 22 : 20);

    // يتم تقسيم النص باستخدام كلمة 'and' لإنشاء أسطر منفصلة
    return appDescription.split('and').map((part) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          part.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white70,
          ),
        ),
      );
    }).toList();
  }

  /// **دالة _buildButtonSection**
  ///
  /// وظيفتها: بناء ويدجت الزر "Get Started" وتعيين وظيفة الانتقال إلى شاشة Login.
  Widget _buildButtonSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        // استخدام دالة متجاوبة للهامش الأفقي للزر
        horizontal: _getResponsiveButtonPadding(
            MediaQuery.of(context).size.width),
      ),
      child: MyButton(
        color: Colors.blueGrey.shade700,
        title: 'Get Started',
        onPressed: () {
          // الانتقال إلى شاشة Login باستخدام مؤثر حركي مخصص (SlideTransition)
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // تبدأ من اليمين
                const end = Offset.zero; // تنتهي في المنتصف
                const curve = Curves.easeInOut;

                final tween = Tween(begin: begin, end: end);
                final offsetAnimation = animation.drive(
                  tween.chain(CurveTween(curve: curve)),
                );

                // استخدام SlideTransition لتطبيق مؤثر الانزلاق
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// **دالة _getResponsivePadding**
  ///
  /// وظيفتها: حساب قيمة الهامش الأفقي المناسبة بناءً على عرض الشاشة.
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 360) return 16; // شاشات صغيرة
    if (screenWidth > 600) return 40; // شاشات كبيرة
    return 24; // شاشات متوسطة
  }

  /// **دالة _getResponsiveSpacing**
  ///
  /// وظيفتها: حساب قيمة الفراغ (SizedBox height) المناسبة بناءً على ارتفاع الشاشة.
  double _getResponsiveSpacing(double screenHeight) {
    if (screenHeight < 600) return 20; // شاشات قصيرة
    if (screenHeight > 800) return 50; // شاشات طويلة
    return 30; // شاشات متوسطة
  }

  /// **دالة _getResponsiveButtonPadding**
  ///
  /// وظيفتها: حساب قيمة الهامش الأفقي للزر بناءً على عرض الشاشة.
  double _getResponsiveButtonPadding(double screenWidth) {
    if (screenWidth < 360) return 20;
    if (screenWidth > 600) return 100;
    return 50;
  }
}
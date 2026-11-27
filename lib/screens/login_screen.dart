// -----------------------------------------------------------------------------
// استيراد الحزم والأدوات اللازمة
// -----------------------------------------------------------------------------
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/my_button.dart';
import 'admin/admin_login_screen.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

// -----------------------------------------------------------------------------
// صنف واجهة المستخدم (Login Widget)
// -----------------------------------------------------------------------------

// صنف Login هو StatefulWidget لأنه يحتاج إلى إدارة حالة متغيرة (مثل إدخالات المستخدم، حالة التحميل، والأخطاء).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// -----------------------------------------------------------------------------
// صنف الحالة (State) الخاص بصفحة تسجيل الدخول
// -----------------------------------------------------------------------------
class _LoginScreenState extends State<LoginScreen> {
  // المتحكمات (Controllers) لحقول الإدخال.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // مفتاح النموذج (GlobalKey) يستخدم للتحقق من صحة جميع حقول النموذج (Validation).
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // حالة عرض كلمة المرور: لإخفائها أو إظهارها.
  bool _obscureText = true;
  // حالة التحميل: لعرض مؤشر التحميل أثناء محاولة تسجيل الدخول.
  bool _isLoading = false;
  // رسالة الخطأ: لعرض أي رسالة خطأ تحدث أثناء المصادقة.
  String? _error;

  // يتم استدعاء هذه الدالة عند إزالة الـ Widget من شجرة العناصر (لتحرير الذاكرة).
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // منطق تسجيل الدخول (Authentication Logic)
  // ---------------------------------------------------------------------------

  // دالة التعامل مع عملية تسجيل الدخول. هي دالة غير متزامنة (async).
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      final user = await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user == null || !mounted) return;

      // الانتقال إلى الصفحة الرئيسية وإزالة كل الشاشات السابقة (لا رجوع لشاشة الدخول).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = AuthService.messageForError(e));
    } catch (e) {
      debugPrint('Login error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // منطق التنقل بين الصفحات (Navigation)
  // ---------------------------------------------------------------------------

  // دالة مساعدة للانتقال إلى صفحة جديدة مع تأثير انتقالي (Slide Transition).
  void _navigateToPage(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        // بناء الانتقال: استخدام SlideTransition لتحريك الصفحة من اليمين إلى اليسار.
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // يبدأ من اليمين
          const end = Offset.zero; // ينتهي في المنتصف
          const curve = Curves.easeInOut; // منحنى الحركة

          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: curve)),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // بناء واجهة المستخدم (UI)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // جلب معلومات حجم الشاشة للتصميم المتجاوب.
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360; // شاشة صغيرة جداً (مثلاً موبايل قديم).
    final bool isLargeScreen = screenSize.width > 600; // شاشة كبيرة (تابلت أو سطح مكتب).

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text("Login"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // فيزياء مرتدة لجعل التمرير أكثر سلاسة.
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            // ضبط الحشو الأفقي بناءً على حجم الشاشة.
            horizontal: _getResponsivePadding(screenSize.width),
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // ضمان أن النموذج يشغل على الأقل ارتفاع المساحة المتاحة لتوسيط المحتوى.
              minHeight: screenSize.height -
                  MediaQuery.of(context).padding.vertical -
                  kToolbarHeight,
            ),
            child: Form(
              key: _formKey, // ربط المفتاح بالنموذج.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتويات عمودياً.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // قسم العنوان والترحيب.
                  _buildHeaderSection(isSmallScreen, isLargeScreen),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                  // قسم حقول النموذج (البريد وكلمة المرور).
                  _buildFormFieldsSection(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                  // قسم عرض رسالة الخطأ (يظهر فقط إذا كان هناك خطأ).
                  if (_error != null) _buildErrorSection(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),

                  // زر تسجيل الدخول (يتحول إلى مؤشر تحميل إذا كان isLoading صحيحاً).
                  _buildLoginButton(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),

                  // قسم الانتقال إلى التسجيل.
                  _buildRegistrationSection(isSmallScreen),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),

                  // زر تسجيل دخول المسؤول (Admin).
                  _buildAdminButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // الدوال المساعدة لبناء أجزاء الـ UI
  // ---------------------------------------------------------------------------

  // بناء قسم العنوان والترحيب مع دعم التجاوب.
  Widget _buildHeaderSection(bool isSmallScreen, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
            // حجم الخط يتغير بناءً على حجم الشاشة.
            fontSize: isSmallScreen ? 36 : (isLargeScreen ? 56 : 48),
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please login to continue",
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : (isLargeScreen ? 22 : 20),
            color: Colors.blueGrey.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // بناء حقول البريد وكلمة المرور.
  Widget _buildFormFieldsSection() {
    return Column(
      children: [
        // حقل البريد الإلكتروني
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          cursorColor: Colors.blueGrey,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            labelText: 'Email',
            labelStyle: const TextStyle(color: Colors.blueGrey),
            prefixIcon: const Icon(Icons.email, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          // دالة التحقق من صحة حقل البريد.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        SizedBox(height: _getResponsiveSpacing(MediaQuery.of(context).size.height) * 0.5),

        // حقل كلمة المرور
        TextFormField(
          controller: _passwordController,
          cursorColor: Colors.blueGrey,
          obscureText: _obscureText, // يتم التحكم بإخفائها عن طريق _obscureText.
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(), // تسجيل الدخول عند الضغط على "Done".
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            labelText: 'Password',
            labelStyle: const TextStyle(color: Colors.blueGrey),
            // أيقونة للتبديل بين إظهار وإخفاء كلمة المرور.
            prefixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          // دالة التحقق من صحة حقل كلمة المرور.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  // بناء قسم عرض رسالة الخطأ بشكل أنيق.
  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء زر تسجيل الدخول أو مؤشر التحميل.
  Widget _buildLoginButton() {
    return _isLoading
        ? const Center(
            // عرض مؤشر التحميل أثناء الاتصال بالخادم.
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
            ),
          )
        : MyButton(
            color: Colors.blueGrey,
            title: 'Login',
            onPressed: _handleLogin, // استدعاء دالة تسجيل الدخول.
          );
  }

  // بناء قسم "لا تملك حساب؟" مع زر الانتقال إلى التسجيل.
  Widget _buildRegistrationSection(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 16),
          ),
        ),
        TextButton(
          child: Text(
            'Registration',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 15),
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => _navigateToPage(const RegistrationScreen()),
        ),
      ],
    );
  }

  // بناء زر تسجيل دخول المسؤول.
  Widget _buildAdminButton() {
    return MyButton(
      color: Colors.blueGrey.withValues(alpha: 0.8),
      title: 'Admin Login',
      onPressed: () => _navigateToPage(const AdminLoginScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // الدوال المساعدة للتصميم المتجاوب (Responsive Helpers)
  // ---------------------------------------------------------------------------

  // تحديد الحشو (Padding) بناءً على عرض الشاشة.
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth > 600) return 40;
    return 24;
  }

  // تحديد المسافات الرأسية (Spacing) بناءً على ارتفاع الشاشة.
  double _getResponsiveSpacing(double screenHeight) {
    if (screenHeight < 600) return 16;
    if (screenHeight > 800) return 32;
    return 24;
  }

  // تحديد حجم الخط بناءً على عرض الشاشة.
  double _getResponsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth > 600) return baseSize * 1.1;
    return baseSize;
  }
}

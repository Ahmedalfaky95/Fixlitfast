// استيراد الحزم والأدوات اللازمة لتشغيل واجهة التسجيل.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/my_button.dart';
import 'home_screen.dart';

// الصنف الرئيسي لواجهة المستخدم الخاصة بالتسجيل. هو صنف من نوع StatefulWidget لأنه يحتوي على حالة متغيرة (مثل حقول الإدخال ورسائل الخطأ).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

// صنف الحالة (State) الذي يحمل البيانات المتغيرة والمنطق الخاص بواجهة التسجيل.
class _RegistrationScreenState extends State<RegistrationScreen> {
  // المتحكم الخاص بحقل إدخال الاسم.
  final TextEditingController _nameController = TextEditingController();
  // المتحكم الخاص بحقل إدخال رقم الهاتف.
  final TextEditingController _phoneController = TextEditingController();
  // المتحكم الخاص بحقل إدخال البريد الإلكتروني.
  final TextEditingController _emailController = TextEditingController();
  // المتحكم الخاص بحقل إدخال كلمة المرور.
  final TextEditingController _passwordController = TextEditingController();
  // مفتاح عام (GlobalKey) يستخدم للتحقق من صحة جميع حقول النموذج (Form).
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // متغير منطقي لتحديد ما إذا كان يجب إخفاء كلمة المرور (true) أو إظهارها (false).
  bool _obscureText = true;
  // متغير منطقي لتحديد ما إذا كانت عملية التسجيل قيد التنفيذ (لعرض مؤشر التحميل).
  bool _isLoading = false;
  // متغير نصي لتخزين وعرض رسالة الخطأ (إن وجدت) للمستخدم.
  String? _error;

  // دالة 'dispose' يتم استدعاؤها عند إزالة الـ Widget بشكل دائم.
  // تستخدم لتحرير موارد المتحكمات (Controllers) لتجنب تسرب الذاكرة.
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة مساعدة لعرض رسالة سناك بار (Snackbar) قصيرة في أسفل الشاشة.
  // تستخدم لعرض رسائل النجاح أو الفشل غير المرتبطة بالتحقق من صحة الحقول.
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // دالة منطق التعامل مع عملية التسجيل.
  // تتحقق من صحة الحقول ثم تستدعي خدمة المصادقة للتسجيل في Firebase.
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      // إنشاء الحساب وحفظ الاسم والهاتف في Firestore (users/{uid}).
      final user = await auth.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (user == null || !mounted) return;

      _showSnackbar('Account created successfully!', Colors.green);

      // Firebase يسجّل دخول المستخدم تلقائياً بعد إنشاء الحساب،
      // لذلك ننتقل مباشرة إلى الصفحة الرئيسية بدل شاشة تسجيل الدخول.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = AuthService.messageForError(e));
    } catch (e) {
      debugPrint('Registration error: $e');
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

  // دالة للانتقال إلى شاشة تسجيل الدخول (Login).
  // شاشة التسجيل تُفتح دائماً من شاشة الدخول، لذلك نرجع إليها بدل فتح نسخة جديدة فوقها.
  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  // دالة بناء واجهة المستخدم (UI) الرئيسية للـ Widget.
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isLargeScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(
          'Create New Account',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(screenSize.width, 18),
          ),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsivePadding(screenSize.width),
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // ضمان أن المحتوى يملأ الارتفاع المتاح بالكامل.
              minHeight: screenSize.height -
                  MediaQuery.of(context).padding.vertical -
                  kToolbarHeight,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // قسم العنوان والترحيب.
                  _buildHeaderSection(isSmallScreen, isLargeScreen),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                  // قسم حقول الإدخال (الهاتف، البريد، كلمة المرور).
                  _buildFormFieldsSection(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),

                  // قسم عرض رسالة الخطأ (يظهر فقط إذا كان هناك خطأ).
                  if (_error != null) _buildErrorSection(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),

                  // زر التسجيل (يظهر مؤشر تحميل إذا كانت العملية جارية).
                  _buildRegisterButton(),

                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),

                  // قسم رابط الانتقال إلى صفحة تسجيل الدخول.
                  _buildLoginLinkSection(isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  // دالة بناء قسم العنوان الرئيسي والترحيب.
  // تقوم بضبط حجم الخط بشكل متجاوب بناءً على حجم الشاشة.
  Widget _buildHeaderSection(bool isSmallScreen, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
            fontSize: isSmallScreen ? 36 : (isLargeScreen ? 56 : 48),
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Register now and create your account",
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : (isLargeScreen ? 22 : 20),
            color: Colors.blueGrey.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // دالة بناء قسم حقول إدخال النموذج (Phone, Email, Password).
  // تحتوي على حقول TextFormField مع ديكورات (decorations) وتحقق من صحة الإدخال (validation).
  Widget _buildFormFieldsSection() {
    return Column(
      children: [
        // حقل إدخال الاسم.
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          cursorColor: Colors.blueGrey,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            labelText: 'Full Name',
            labelStyle: const TextStyle(color: Colors.blueGrey),
            prefixIcon: const Icon(Icons.person, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),

        SizedBox(height: _getResponsiveSpacing(MediaQuery.of(context).size.height) * 0.5),

        // حقل إدخال رقم الهاتف.
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          cursorColor: Colors.blueGrey,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            labelText: 'Phone Number', // Label change to reflect Firebase Auth standard behavior (phone is usually separate)
            labelStyle: const TextStyle(color: Colors.blueGrey),
            prefixIcon: const Icon(Icons.phone, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          // التحقق من صحة إدخال رقم الهاتف.
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 10) {
              return 'Phone number must be at least 10 digits';
            }
            return null;
          },
        ),

        SizedBox(height: _getResponsiveSpacing(MediaQuery.of(context).size.height) * 0.5),

        // حقل إدخال البريد الإلكتروني.
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          cursorColor: Colors.blueGrey,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.blueGrey),
            prefixIcon: Icon(Icons.email, color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          // التحقق من صحة إدخال البريد الإلكتروني.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        SizedBox(height: _getResponsiveSpacing(MediaQuery.of(context).size.height) * 0.5),

        // حقل إدخال كلمة المرور.
        TextFormField(
          controller: _passwordController,
          obscureText: _obscureText,
          cursorColor: Colors.blueGrey,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            labelText: 'Password',
            labelStyle: const TextStyle(color: Colors.blueGrey),
            // أيقونة لتبديل إخفاء/إظهار كلمة المرور.
            prefixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              // عند الضغط، يتم تبديل حالة _obscureText وإعادة بناء الـ Widget.
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          // التحقق من صحة إدخال كلمة المرور (الطول لا يقل عن 6 أحرف).
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),
      ],
    );
  }

  // دالة بناء قسم رسالة الخطأ.
  // يتم تصميمها كحاوية بارزة باللون الأحمر لعرض رسائل الأخطاء للمستخدم.
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

  // دالة بناء زر التسجيل.
  // تستخدم صنف 'MyButton' المخصص وتظهر مؤشر تحميل دائري إذا كانت عملية التسجيل قيد التنفيذ.
  Widget _buildRegisterButton() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
            ),
          )
        : MyButton(
            color: Colors.blueGrey,
            title: 'Create Account',
            onPressed: _handleRegistration,
          );
  }

  // دالة بناء قسم رابط تسجيل الدخول.
  // يوفر للمستخدم خيار الانتقال إلى شاشة تسجيل الدخول إذا كان لديه حساب بالفعل.
  Widget _buildLoginLinkSection(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 16),
          ),
        ),
        TextButton(
          onPressed: _navigateToLogin,
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 18),
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // --- Responsive Helper Methods ---

  // دالة مساعدة لحساب الهوامش الأفقية المناسبة بناءً على عرض الشاشة.
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth > 600) return 40;
    return 24;
  }

  // دالة مساعدة لحساب التباعد العمودي المناسب (SizedBox height) بناءً على ارتفاع الشاشة.
  double _getResponsiveSpacing(double screenHeight) {
    if (screenHeight < 600) return 16;
    if (screenHeight > 800) return 32;
    return 24;
  }

  // دالة مساعدة لحساب حجم الخط المناسب بناءً على عرض الشاشة.
  double _getResponsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth > 600) return baseSize * 1.1;
    return baseSize;
  }
}
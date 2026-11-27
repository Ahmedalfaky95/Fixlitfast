import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/my_button.dart';
import 'admin_screen.dart';

// الواجهة الرئيسية (StatefulWidget) لشاشة تسجيل دخول المشرفين.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

// فئة الحالة التي تدير منطق وعناصر واجهة المستخدم لتسجيل دخول المشرف.
class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // المتحكمات (Controllers) لحقول إدخال النص.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // مفتاح عام للتحقق من صحة النموذج (Form validation).
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // متغيرات الحالة لإدارة واجهة المستخدم.
  bool _obscureText = true; // للتبديل بين إظهار/إخفاء كلمة المرور.
  bool _isLoading = false; // لعرض مؤشر التحميل أثناء محاولة تسجيل الدخول.
  String? _error; // لتخزين وعرض أخطاء المصادقة.

  @override
  void dispose() {
    // تنظيف المتحكمات عند إزالة الودجت من شجرة الودجت.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // تعالج عملية تسجيل دخول المشرف، بما في ذلك المصادقة والتحقق من الدور.
  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      // 1. تسجيل الدخول بالبريد وكلمة المرور.
      final user = await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user == null) return;

      // 2. التحقق من صلاحية المسؤول.
      final isAdmin = await auth.checkAdminRole(user.uid);
      if (!mounted) return;

      if (isAdmin) {
        // 3. مسؤول: الانتقال إلى لوحة التحكم وإزالة كل الشاشات السابقة.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminScreen()),
          (route) => false,
        );
      } else {
        // 4. ليس مسؤولاً: تسجيل خروجه فوراً.
        await auth.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'This account does not have admin privileges.';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = AuthService.messageForError(e));
    } catch (e) {
      debugPrint('Admin login error: $e');
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
        title: const Text('Admin Login'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // فيزياء التمرير (Scrolling physics)
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsivePadding(screenSize.width),
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // تأكد من أن المحتوى يشغل على الأقل ارتفاع الشاشة مطروحًا منه شريط التطبيق والتهميش.
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
                  // قسم العنوان: العنوان الرئيسي ورسالة الترحيب
                  _buildHeaderSection(isSmallScreen, isLargeScreen),
                  
                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),
                  
                  // قسم حقول النموذج: مدخلات البريد الإلكتروني وكلمة المرور
                  _buildFormFieldsSection(),
                  
                  SizedBox(height: _getResponsiveSpacing(screenSize.height)),
                  
                  // رسالة الخطأ: تعرض أخطاء المصادقة أو الدور
                  if (_error != null) _buildErrorSection(),
                  
                  SizedBox(height: _getResponsiveSpacing(screenSize.height) * 0.5),
                  
                  // زر تسجيل الدخول أو مؤشر التحميل
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // يبني الرأس الذي يحتوي على العنوان الرئيسي ونص الترحيب.
  Widget _buildHeaderSection(bool isSmallScreen, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Admin Access",
          style: TextStyle(
            fontSize: isSmallScreen ? 32 : (isLargeScreen ? 48 : 42),
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Welcome Back, Administrator", // رسالة ترحيب
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : (isLargeScreen ? 20 : 18),
            color: Colors.blueGrey.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // يبني حقول إدخال النص للبريد الإلكتروني وكلمة المرور مع التحقق من صحتها.
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
            labelText: 'Admin Email',
            labelStyle: const TextStyle(color: Colors.blueGrey),
            prefixIcon: const Icon(Icons.email, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter admin email';
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

  // يبني حاوية رسالة الخطأ.
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
          Icon(Icons.security, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // يبني زر تسجيل الدخول أو مؤشر التحميل.
  Widget _buildLoginButton() {
    return _isLoading
        ? Column(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              Text(
                'Verifying Admin Access...', // يتم التحقق من صلاحية المشرف...
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: _getResponsiveFontSize(MediaQuery.of(context).size.width, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
        : MyButton(
            color: Colors.blueGrey,
            title: 'Admin Login',
            onPressed: _handleAdminLogin,
          );
  }

  // طرق مساعدة للاستجابة (Responsive Helper Methods)
  
  // تحدد التباعد الأفقي بناءً على عرض الشاشة.
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth > 600) return 40;
    return 24;
  }

  // تحدد التباعد العمودي بناءً على ارتفاع الشاشة.
  double _getResponsiveSpacing(double screenHeight) {
    if (screenHeight < 600) return 16;
    if (screenHeight > 800) return 32;
    return 24;
  }

  // تعدل حجم الخط بناءً على عرض الشاشة.
  double _getResponsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.9;
    if (screenWidth > 600) return baseSize * 1.1;
    return baseSize;
  }
}

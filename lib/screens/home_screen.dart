// -----------------------------------------------------------------------------
// استيراد الحزم وصفحات العرض (Views)
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'complaint_status_screen.dart';
import 'login_screen.dart';
import 'my_complaints_screen.dart';
import 'new_complaint_screen.dart';
import 'profile_screen.dart';

// -----------------------------------------------------------------------------
// صنف Home (StatefulWidget)
// -----------------------------------------------------------------------------
// Home هو StatefulWidget لأنه يدير حالة الرسوم المتحركة (Animation state).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// -----------------------------------------------------------------------------
// صنف الحالة (State) وإدارة الرسوم المتحركة
// -----------------------------------------------------------------------------
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // SingleTickerProviderStateMixin: ضروري لتوفير "Ticker" لدورة حياة الـ AnimationController.

  // 1. متحكم الرسوم المتحركة: يدير حركة وبدء/إيقاف الرسوم.
  late AnimationController _controller;
  // 2. الرسوم المتحركة لـ Fade (الظهور): تتحكم في شفافية الـ Widget.
  late Animation<double> _fadeAnim;
  // 3. الرسوم المتحركة لـ Slide (الانزلاق): تتحكم في موضع الـ Widget (من الأسفل للأعلى قليلاً).
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكم بمدة زمنية (800 مللي ثانية).
    _controller = AnimationController(
      vsync: this, // ربط المتحكم بالـ TickerProvider (الـ Mixin الذي أضفناه).
      duration: const Duration(milliseconds: 800),
    );

    // تهيئة رسم Fade (من 0.0 إلى 1.0).
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut), // استخدام منحنى حركة سلس.
    );

    // تهيئة رسم Slide (من 25% أسفل الوضع الطبيعي إلى الوضع الطبيعي).
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // بدء الرسوم المتحركة بعد إنشاء الصفحة.
    _controller.forward();
  }

  @override
  void dispose() {
    // يجب التخلص من الـ AnimationController عند إزالة الـ Widget لمنع تسرب الذاكرة.
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------------
  // بناء بطاقة الخيارات الموحدة (Dashboard Card Builder)
  // -----------------------------------------------------------------------------
  Widget _buildCard(Color color, IconData icon, String title, VoidCallback onTap) {
    return FadeTransition(
      opacity: _fadeAnim, // تطبيق رسوم الظهور.
      child: SlideTransition(
        position: _slideAnim, // تطبيق رسوم الانزلاق.
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap, // دالة تُنفذ عند الضغط على البطاقة.
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 160,
              height: 180,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // دائرة الأيقونة المزخرفة
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 34),
                  ),
                  const SizedBox(height: 12),
                  // عنوان البطاقة
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // دالة المساعدة للتنقل
  // -----------------------------------------------------------------------------
  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // -----------------------------------------------------------------------------
  // منطق تسجيل الخروج (Logout Logic)
  // -----------------------------------------------------------------------------

  // تسجيل الخروج الفعلي من Firebase ثم العودة لشاشة الدخول.
  // (سابقاً كان يحذف auth_token من التخزين المحلي فقط ويبقى المستخدم مسجلاً في Firebase)
  Future<void> _logout() async {
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // عرض مربع حوار تأكيد تسجيل الخروج.
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // إغلاق مربع الحوار.
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // إغلاق مربع الحوار.
                _logout(); // تنفيذ عملية تسجيل الخروج.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------------------
  // دالة بناء واجهة المستخدم الرئيسية (UI Build)
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // إزالة الظل من شريط التطبيق.
        automaticallyImplyLeading: false, // لمنع ظهور زر الرجوع التلقائي.
        actions: [
          // زر تسجيل الخروج في شريط التطبيق.
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _showLogoutDialog, // عرض مربع حوار التأكيد.
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // تنظيم المحتويات عمودياً.
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // عنوان التطبيق
              const Text(
                'FixItFast',
                style: TextStyle(
                  fontSize: 38,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // رسالة ترحيب
              const Text(
                'Manage your complaints easily and efficiently',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // استخدام Wrap لتنظيم البطاقات بشكل متجاوب (Responsive)
              Wrap(
                spacing: 16, // المسافة الأفقية بين العناصر.
                runSpacing: 16, // المسافة العمودية بين الصفوف.
                alignment: WrapAlignment.center, // توسيط البطاقات.
                children: [
                  // 1. بطاقة "New Complaint" (شكوى جديدة)
                  _buildCard(const Color(0xff004c4c), Icons.post_add, 'New Complaint',
                      () => _navigateTo(const NewComplaintScreen())),

                  // 2. بطاقة "My Complaints" (الشكاوى المكتملة)
                  _buildCard(const Color(0xffe53935), Icons.sync_problem_sharp, 'My Complaints',
                      () => _navigateTo(const MyComplaintsScreen())),

                  // 3. بطاقة "Complaint status" (حالة الشكوى)
                  _buildCard(const Color(0xfff37736), Icons.notifications, 'Complaint Status',
                      () => _navigateTo(const ComplaintStatusScreen())),

                  // 4. بطاقة "Profile" (الملف الشخصي)
                  _buildCard(const Color(0xff1e88e5), Icons.person_outline, 'Profile',
                      () => _navigateTo(const ProfileScreen())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

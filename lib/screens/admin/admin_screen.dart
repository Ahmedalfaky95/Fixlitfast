import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'dashboard_screen.dart';
import 'in_progress_screen.dart';
import 'pending_complaints_screen.dart';
import 'reports_screen.dart';

// الواجهة الرئيسية (StatefulWidget) للوحة تحكم المشرفين بعد تسجيل الدخول.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  var currentIndex = 0; // فهرس التبويب الحالي

  // تعريف قائمة الصفحات كـ late
  late final List<Widget> _pages;

  // الدالة لتغيير علامة التبويب والتبديل بين الصفحات
  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
      HapticFeedback.lightImpact(); // إضافة اهتزاز خفيف لتجربة مستخدم أفضل
    });
  }

  // دالة تسجيل الخروج وإعادة توجيه المستخدم إلى شاشة تسجيل الدخول
  Future<void> _handleLogout() async {
    try {
      await context.read<AuthService>().signOut();
      if (!mounted) return;
      // بعد تسجيل الخروج، العودة إلى شاشة تسجيل الدخول وإزالة جميع المسارات السابقة
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      // زر "View Progress" في لوحة التحكم ينقل إلى التبويب رقم 1
      DashboardScreen(
        onNavigateToProgress: () => _onItemTapped(1),
        onLogout: _handleLogout,
      ),
      const PendingComplaintsScreen(),
      const InProgressScreen(),
      const ReportsScreen(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    double displayWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false, // لمنع ظهور زر العودة التلقائي

        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(_getAppBarTitle(currentIndex)),
        backgroundColor: Colors.blueGrey,
        actions: [
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout', // نص مساعدة
            onPressed: _handleLogout,
          ),
        ],
      ),
      // IndexedStack يحافظ على حالة كل تبويب بدل إعادة إنشائه عند كل تبديل
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(displayWidth * .05),
        height: displayWidth * .155,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          borderRadius: BorderRadius.circular(50),
        ),
        child: ListView.builder(
          itemCount: listOfIcons.length, // استخدام طول قائمة الأيقونات
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: displayWidth * .02),
          itemBuilder: (context, index) => InkWell(
            onTap: () {
              // **استخدام الدالة المحدثة لتغيير التبويب**
              _onItemTapped(index);
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Stack(
              children: [
                AnimatedContainer(
                  // الحاوية المتحركة التي تتغير عند تحديد التبويب
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.fastLinearToSlowEaseIn,
                  width: index == currentIndex
                      ? displayWidth * .32
                      : displayWidth * .18,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.fastLinearToSlowEaseIn,
                    height: index == currentIndex ? displayWidth * .12 : 0,
                    width: index == currentIndex ? displayWidth * .32 : 0,
                    decoration: BoxDecoration(
                      color: index == currentIndex
                          ? Colors.blueAccent.withValues(alpha: .2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                AnimatedContainer(
                  // الحاوية التي تحتوي على الأيقونة
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.fastLinearToSlowEaseIn,
                  width: index == currentIndex
                      ? displayWidth * .31
                      : displayWidth * .18,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            // لإنشاء مسافة قبل النص عند تحديد التبويب
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn,
                            width:
                                index == currentIndex ? displayWidth * .13 : 0,
                          ),
                          AnimatedOpacity(
                            // لضمان عرض النص فقط عند تحديد التبويب (إذا كان هناك نص)
                            opacity: index == currentIndex ? 1 : 0,
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn,
                          
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            // مسافة قبل الأيقونة
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.fastLinearToSlowEaseIn,
                            width:
                                index == currentIndex ? displayWidth * .03 : 20,
                          ),
                          Icon(
                            // الأيقونة نفسها
                            listOfIcons[index],
                            size: displayWidth * .076,
                            color: index == currentIndex
                                ? Colors.blueGrey
                                : Colors.black26,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة للحصول على عنوان AppBar بناءً على الصفحة الحالية
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'New Complaints';
      case 2:
        return 'In Progress';
      case 3:
        return 'Reports';
      default:
        return 'Admin Panel';
    }
  }

  // قائمة الأيقونات المستخدمة في شريط التنقل السفلي
  final List<IconData> listOfIcons = const [
    Icons.home_rounded,
    Icons.new_releases_outlined,
    Icons.sync_problem_sharp,
    Icons.report_gmailerrorred_rounded,
  ];
}

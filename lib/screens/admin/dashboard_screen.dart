import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// شاشة لوحة تحكم المشرف (StatelessWidget)
class DashboardScreen extends StatelessWidget {
  // الدالة المطلوبة (Callback) لتغيير علامة التبويب في شاشة المسؤول الرئيسية.
  final VoidCallback onNavigateToProgress;

  // تسجيل الخروج الفعلي (signOut) يتم في AdminScreen ويُمرَّر هنا.
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.onNavigateToProgress,
    required this.onLogout,
  });

  // دالة للحصول على تحية مناسبة بناءً على الوقت الحالي.
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning'; // صباح الخير
    } else if (hour < 18) {
      return 'Good Afternoon'; // مساء الخير (بعد الظهر)
    } else {
      return 'Good Evening'; // مساء الخير
    }
  }

  // دالة للحصول على التاريخ والوقت الحالي وتنسيقهما.
  String _getCurrentDateTime() {
    var now = DateTime.now();
    // تنسيق التاريخ والوقت (السنة-الشهر-اليوم الساعة:الدقيقة)
    var formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية خفيفة
      body: SingleChildScrollView(
        // السماح بالتمرير للمحتوى
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم الرأس مع التحية وتاريخ اليوم
            _buildHeader(context),
            
            const SizedBox(height: 30),
            
            // بطاقة ملخص الشكاوى
            _buildComplaintSummaryCard(),
            
            const SizedBox(height: 25),
            
            // زر التنقل إلى شاشة التقدم (New Progress)
            _buildNavigateButton(context),

            // يمكن إضافة أقسام أخرى مثل الإحصائيات أو الشكاوى الحديثة هنا لاحقاً.
          ],
        ),
      ),
    );
  }

  // بناء قسم الرأس
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تحية المدير بناءً على الوقت
                Text(
                  '${_getGreeting()}, Manager',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 5),
                // عرض التاريخ والوقت الحالي
                Text(
                  _getCurrentDateTime(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 15),
              // زر تسجيل الخروج (يستخدم هنا كـ Placeholder لفتح مربع الحوار)
              _buildLogoutButton(context),
            ],
          ),
        ],
      ),
    );
  }

  // زر تسجيل الخروج المحسّن
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: IconButton(
        onPressed: () => _showLogoutDialog(context), // استدعاء مربع حوار تأكيد تسجيل الخروج
        icon: Icon(
          Icons.logout,
          color: Colors.red[700],
          size: 28,
        ),
        tooltip: 'Logout',
      ),
    );
  }

  // دالة عرض مربع حوار تأكيد تسجيل الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 10),
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
            style: TextStyle(
              color: Colors.blueGrey[600],
            ),
          ),
          actions: [
            // زر الإلغاء
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            // زر تأكيد تسجيل الخروج
            ElevatedButton(
              onPressed: () {
                // إغلاق الحوار ثم تسجيل الخروج الفعلي من Firebase.
                Navigator.of(context).pop();
                onLogout();
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

  // بناء بطاقة ملخص الشكاوى (Card)
  Widget _buildComplaintSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        // تدرج لوني جميل للبطاقة
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر إلى اليسار
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apartment Society Complaint', // عنوان النظام
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            const SizedBox(height: 8),

            const Text(
              'Management For Abraj AL-Nilein', // اسم الإدارة
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
    
  // بناء زر التنقل إلى صفحة التقدم
  Widget _buildNavigateButton(BuildContext context) {
    return Center( // توسيط الزر
      child: ElevatedButton(
        onPressed: () {
          // **استدعاء الدالة الممررة لتغيير التبويب في Admin.dart إلى الصفحة 1**
          onNavigateToProgress();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          // تحديد حجم ثابت للزر
          minimumSize: const Size(double.infinity, 50), 
          // بدون padding أفقي ثابت (كان 125 ويسبب overflow على الشاشات الصغيرة)
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'View Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

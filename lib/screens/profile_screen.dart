import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';

/// شاشة الملف الشخصي.
///
/// البيانات محفوظة في Firestore (users/{uid}) فتكون مرتبطة بالحساب وليس بالجهاز.
/// سابقاً كانت محفوظة في SharedPreferences فقط، فيرى المستخدم الثاني على
/// نفس الهاتف بيانات المستخدم الأول.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _genderOptions = const ['Male', 'Female'];

  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  UserProfile data = const UserProfile();
  String? imagePath; // مسار الصورة الشخصية على هذا الجهاز
  bool _isLoading = true;

  /// مفتاح الصورة مرتبط بالمستخدم حتى لا تظهر صورة مستخدم لآخر.
  String get _imageKey => 'profile_image_$_uid';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final userService = context.read<UserService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final profile = await userService.getProfile(uid);
      if (!mounted) return;
      setState(() {
        imagePath = prefs.getString(_imageKey);
        // البريد يُؤخذ دائماً من حساب تسجيل الدخول.
        data = profile.copyWith(
          email: FirebaseAuth.instance.currentUser?.email ?? profile.email,
        );
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
      _showMessage('Could not load your profile.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// حفظ حقل واحد في Firestore وتحديث الواجهة.
  Future<void> _saveField(String field, String value,
      UserProfile Function(UserProfile) update) async {
    final uid = _uid;
    if (uid == null) return;
    final previous = data;
    setState(() => data = update(data));
    try {
      await context.read<UserService>().updateFields(uid, {field: value});
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (!mounted) return;
      setState(() => data = previous);
      _showMessage('Could not save. Please try again.', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    var savedPath = picked.path;
    if (!kIsWeb) {
      // نسخ الصورة إلى مجلد التطبيق لأن مسار image_picker مؤقت وقد يُحذف لاحقاً.
      try {
        final dir = await getApplicationDocumentsDirectory();
        final target = p.join(dir.path, 'profile_$_uid${p.extension(picked.path)}');
        await File(picked.path).copy(target);
        savedPath = target;
        // مسح الصورة القديمة من الذاكرة المؤقتة حتى تظهر الجديدة بنفس المسار.
        await FileImage(File(target)).evict();
      } catch (e) {
        debugPrint('Could not copy profile image: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageKey, savedPath);
    if (!mounted) return;
    setState(() => imagePath = savedPath);
  }

  Widget _buildAvatar() {
    const double size = 120;
    final path = imagePath;
    if (path != null && path.isNotEmpty) {
      // على الويب المسار رابط blob، وعلى الهاتف مسار ملف.
      final ImageProvider image =
          kIsWeb ? NetworkImage(path) : FileImage(File(path));
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: image,
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 60, color: Colors.blueGrey),
    );
  }

  /// **دالة _buildInfoRow**
  ///
  /// وظيفتها: بناء صف معلوماتي واحد (ListTile) مع زر تعديل.
  Widget _buildInfoRow({
    required String label,
    required String value,
    VoidCallback? onEdit, // null = حقل للقراءة فقط
  }) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value.isEmpty ? 'Not set' : value),
      trailing: onEdit == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              color: Colors.blueGrey,
            ),
    );
  }

  /// **دالة _showDatePicker**
  ///
  /// وظيفتها: عرض منتقي التاريخ (DatePicker) للسماح للمستخدم بتعديل تاريخ الميلاد،
  /// وتنسيق التاريخ وحفظه.
  Future<void> _showDatePicker() async {
    DateTime initialDate;
    // محاولة تحليل التاريخ الحالي المخزَّن، وإلا استخدام تاريخ اليوم
    try {
      initialDate = DateFormat('yyyy-MM-dd').parse(data.birthDate);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Choose Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Save',
    );

    if (pickedDate != null) {
      final value = DateFormat('yyyy-MM-dd').format(pickedDate);
      await _saveField('birthDate', value, (d) => d.copyWith(birthDate: value));
    }
  }

  /// **دالة _showGenderDialog**
  ///
  /// وظيفتها: عرض حوار (Dialog) يحتوي على قائمة منسدلة لاختيار النوع (Gender)،
  /// وتحديث القيمة وحفظها.
  Future<String?> _showGenderDialog() async {
    String? selectedGender =
        _genderOptions.contains(data.gender) ? data.gender : _genderOptions[0];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Gender'),
        titleTextStyle: const TextStyle(
          color: Colors.blueGrey,
        ),
        content: DropdownButtonFormField<String>(
          // تعيين القيمة الافتراضية
          initialValue: selectedGender,
          decoration: const InputDecoration(labelText: 'Gender'),
          style: const TextStyle(
            color: Colors.blueGrey,
          ),
          // بناء خيارات القائمة المنسدلة
          items: _genderOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            selectedGender = newValue; // تحديث القيمة المختارة مؤقتاً
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              )),
          TextButton(
              onPressed: () => Navigator.pop(context, selectedGender), // إرجاع القيمة المختارة
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              )),
        ],
      ),
    );
  }

  /// **دالة _showEditDialog (عامة لتعديل الحقول النصية)**
  ///
  /// وظيفتها: عرض حوار عام يحتوي على حقل نصي لتعديل أي من الحقول النصية
  /// (الاسم، البريد الإلكتروني، العنوان) وإرجاع القيمة المعدلة.
  Future<String?> _showEditDialog(String field, String current) async {
    TextEditingController controller =
        TextEditingController(text: current.trim());
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field),
          style: const TextStyle(
            color: Colors.blueGrey,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              )),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()), // إرجاع النص المعدل
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              )),
        ],
      ),
    );
  }

  /// **دالة _buildInfoCard**
  ///
  /// وظيفتها: بناء ويدجت البطاقة (Card) الذي يحتوي على قائمة المعلومات الشخصية القابلة للتعديل.
  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // تصغير حجم العمود ليناسب المحتوى
          children: [
            _buildInfoRow(
              label: 'Name',
              value: data.name,
              onEdit: () async {
                final v = await _showEditDialog('Name', data.name);
                if (v != null) {
                  await _saveField('name', v, (d) => d.copyWith(name: v));
                }
              },
            ),
            _buildInfoRow(
              label: 'Phone',
              value: data.phone,
              onEdit: () async {
                final v = await _showEditDialog('Phone', data.phone);
                if (v != null) {
                  await _saveField('phone', v, (d) => d.copyWith(phone: v));
                }
              },
            ),
            _buildInfoRow(
              label: 'BirthDate',
              value: data.birthDate,
              onEdit: _showDatePicker,
            ),
            _buildInfoRow(
              label: 'Gender',
              value: data.gender,
              onEdit: () async {
                final v = await _showGenderDialog();
                if (v != null) {
                  await _saveField('gender', v, (d) => d.copyWith(gender: v));
                }
              },
            ),
            // البريد هو بريد تسجيل الدخول، لذلك للعرض فقط.
            _buildInfoRow(
              label: 'Email',
              value: data.email,
            ),
            _buildInfoRow(
              label: 'Address',
              value: data.address,
              onEdit: () async {
                final v = await _showEditDialog('Address', data.address);
                if (v != null) {
                  await _saveField('address', v, (d) => d.copyWith(address: v));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  // **دالة بناء واجهة المستخدم (Build Method)**
  //
  // وظيفتها: بناء الـ Widget tree الرئيسية للصفحة باستخدام `Stack` لوضع صورة الملف الشخصي
  // فوق جزء من الخلفية والبطاقة المعلوماتية.
  Widget build(BuildContext context) {
    return Scaffold(
      // لمنع إعادة بناء الشاشة عند ظهور لوحة المفاتيح
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          // **الخلفية (Background)**
          Column(
            children: [
              // الشريط العلوي الأزرق الرمادي
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.blueGrey,
              ),
              // الجزء السفلي ذو الخلفية الفاتحة
              Expanded(
                child: Container(
                  color: const Color(0xFFF0F2F5),
                ),
              ),
            ],
          ),
          // **قسم الصورة الشخصية وزر التعديل (Avatar Section)**
          Positioned(
            top: 110, // وضع الصورة في المنتصف بين الشريطين تقريباً
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage, // استدعاء دالة اختيار الصورة عند النقر
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildAvatar(), // عرض الصورة الدائرية
                      // زر الكاميرا الصغير لتعديل الصورة
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // **قسم بطاقة المعلومات (Info Card Section)**
          Positioned(
            top: 260, // وضع البطاقة أسفل الصورة
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.topCenter,
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(color: Colors.blueGrey),
                    )
                  : SingleChildScrollView(
                      // السماح بالتمرير داخل البطاقة إذا كان ارتفاعها أكبر من المتاح
                      child: _buildInfoCard(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
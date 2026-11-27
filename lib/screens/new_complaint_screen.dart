import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/complaint_service.dart';
import '../services/user_service.dart';

/// شاشة إرسال شكوى جديدة.
class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  // نستخدم XFile و bytes بدل File من dart:io حتى تعمل الشاشة على الويب أيضاً.
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// تعبئة الاسم والهاتف تلقائياً من الملف الشخصي (إن وُجدا).
  Future<void> _prefillFromProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final profile = await context.read<UserService>().getProfile(uid);
      if (!mounted) return;
      if (_nameController.text.isEmpty) _nameController.text = profile.name;
      if (_phoneController.text.isEmpty) _phoneController.text = profile.phone;
    } catch (e) {
      debugPrint('Could not load profile: $e');
    }
  }

  /// اختيار مصدر الصورة (الكاميرا أو المعرض). على الويب نفتح المعرض مباشرة.
  Future<void> _chooseImageSource() async {
    if (kIsWeb) {
      await _pickImage(ImageSource.gallery);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      _showErrorSnackbar('Could not open the camera or gallery.');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final image = _pickedImage;
    if (image == null) {
      _showErrorSnackbar('Please add an image of the issue.');
      return;
    }
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showErrorSnackbar('You are not logged in. Please log in again.');
      return;
    }

    setState(() => _isLoading = true);
    final complaintService = context.read<ComplaintService>();

    try {
      final imageUrl = await complaintService.uploadImageToCloudinary(image);
      if (imageUrl == null) {
        _showErrorSnackbar('Image upload failed. Please try again.');
        return;
      }

      await complaintService.submitComplaintData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        userId: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Submission error: $e');
      _showErrorSnackbar(
          'An error occurred while submitting the complaint. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -----------------------------------------------------------------------------
  // دالة بناء واجهة المستخدم (UI)
  // -----------------------------------------------------------------------------

  // دالة بناء الـ Widget (بناء واجهة المستخدم).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('New Complaint'),
        backgroundColor: Colors.blueGrey,
      ),
      // SingleChildScrollView حتى لا تتجاوز الحقول الشاشة عند ظهور لوحة المفاتيح.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ////////////////////////////// Header (العنوان)
              const Text(
                "Submit a New Complaint",
                style: TextStyle(fontSize: 30, color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),

              ////////////////////////////// Name Field (حقل الاسم)
              TextFormField(
                controller: _nameController,
                cursorColor: Colors.blueGrey,
                decoration: const InputDecoration(
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                ),
                // دالة التحقق من صحة حقل الاسم.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ////////////////////////////// Phone Field (حقل الهاتف)
              TextFormField(
                controller: _phoneController,
                cursorColor: Colors.blueGrey,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                ),
                // دالة التحقق من صحة حقل رقم الهاتف.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number.';
                  }
                  return null;
                },
              ),

              ///////////////////////////// Description (حقل الوصف)
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                cursorColor: Colors.blueGrey,
                maxLines: 5, // الحد الأقصى للسطور المرئية.
                minLines: 3, // الحد الأدنى للسطور المرئية.
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  labelText: 'Detailed Description of the Issue',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                  alignLabelWithHint: true,
                ),
                // دالة التحقق من صحة حقل الوصف.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description of the issue.';
                  }
                  return null;
                },
              ),

              ///////////////////////////// Take Photo Button (زر التقاط الصورة)
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _chooseImageSource,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_pickedImage == null ? 'Add a photo' : 'Change photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),

              ////////////////////////////// Image Preview (معاينة الصورة)
              // شرط لعرض معاينة الصورة فقط إذا تم اختيار صورة (أي _pickedImage ليس Null).
              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Attachment image',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          // زر لعرض معاينة مكبرة للصورة في مربع حوار.
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: InteractiveViewer( // يسمح بالتكبير والتصغير.
                                      child: Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Preview'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ////////////////////////////// Submit Button (زر الإرسال)
              const SizedBox(height: 30),
              ElevatedButton(
                // تعطيل الزر إذا كانت عملية التحميل جارية (_isLoading = true).
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                // عرض مؤشر تحميل دائري أو نص "Send" بناءً على حالة _isLoading.
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text(
                        'Send',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
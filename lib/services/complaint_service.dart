import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/complaint.dart';
import '../models/complaint_status.dart';
import 'cloudinary_config.dart';

/// التعامل مع الشكاوى في Firestore ورفع الصور إلى Cloudinary.
///
/// ملاحظة: الاستعلامات التي تجمع where مع orderBy تحتاج فهارس مركّبة،
/// وهي معرّفة في ملف firestore.indexes.json في جذر المشروع.
class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// مجموعة الشكاوى في Firestore: /complaints
  CollectionReference<Map<String, dynamic>> get complaintsRef =>
      _db.collection('complaints');

  /// إرسال شكوى جديدة (تبدأ دائماً بحالة Pending).
  Future<void> submitComplaintData({
    required String name,
    required String phone,
    required String description,
    required String imageUrl,
    required String userId,
  }) async {
    final complaint = Complaint(
      title: 'New Complaint from $name',
      name: name,
      phone: phone,
      description: description,
      imageUrl: imageUrl,
      status: ComplaintStatus.pending,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await complaintsRef.add(complaint.toFirestore());
  }

  /// رفع صورة إلى Cloudinary وإرجاع رابطها (أو null عند الفشل).
  ///
  /// نقرأ الصورة كـ bytes بدل File حتى يعمل الرفع على الويب أيضاً.
  Future<String?> uploadImageToCloudinary(XFile image) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(CloudinaryConfig.uploadUrl))
            ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              await image.readAsBytes(),
              filename: image.name,
            ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(body)['secure_url'] as String?;
      }
      debugPrint('Cloudinary upload failed (${response.statusCode}): $body');
      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  List<Complaint> _toComplaints(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(Complaint.fromFirestore).toList();
  }

  /// كل شكاوى المستخدم.
  Stream<List<Complaint>> getMyComplaints({required String userId}) {
    return complaintsRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_toComplaints);
  }

  /// شكاوى بحالة معينة (لشاشات المسؤول).
  Stream<List<Complaint>> getComplaintsByStatus({required ComplaintStatus status}) {
    return complaintsRef
        .where('status', isEqualTo: status.value)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_toComplaints);
  }

  /// شكاوى المستخدم غير المكتملة (Pending أو InProgress).
  Stream<List<Complaint>> getPendingOrInProgressComplaints({required String userId}) {
    return complaintsRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          ComplaintStatus.pending.value,
          ComplaintStatus.inProgress.value,
        ])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_toComplaints);
  }

  /// شكاوى المستخدم المكتملة.
  Stream<List<Complaint>> getCompletedComplaints({required String userId}) {
    return complaintsRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ComplaintStatus.completed.value)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_toComplaints);
  }

  /// تحديث الحالة. عند الإكمال نسجّل وقت الإنجاز، وغير ذلك نمسحه.
  Future<void> updateComplaintStatus(
      String complaintId, ComplaintStatus newStatus) async {
    await complaintsRef.doc(complaintId).update({
      'status': newStatus.value,
      'resolvedAt': newStatus == ComplaintStatus.completed
          ? FieldValue.serverTimestamp()
          : null,
    });
  }

  Future<void> deleteComplaint(String complaintId) async {
    await complaintsRef.doc(complaintId).delete();
  }
}

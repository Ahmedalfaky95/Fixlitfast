import 'package:cloud_firestore/cloud_firestore.dart';

import 'complaint_status.dart';

/// نموذج بيانات الشكوى.
class Complaint {
  /// معرّف المستند في Firestore (يكون null قبل الحفظ).
  final String? id;
  final String title;

  /// اسم مقدم الشكوى.
  final String name;
  final String phone;
  final String description;

  /// رابط الصورة المرفقة (على Cloudinary).
  final String imageUrl;
  final ComplaintStatus status;

  /// وقت إرسال الشكوى.
  final DateTime timestamp;

  /// وقت إنجاز الشكوى (null إذا لم تكتمل بعد).
  final DateTime? resolvedAt;

  /// معرّف المستخدم (UID) الذي قدّم الشكوى.
  final String? userId;

  const Complaint({
    this.id,
    required this.title,
    required this.name,
    required this.phone,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.timestamp,
    this.resolvedAt,
    this.userId,
  });

  /// إنشاء شكوى من مستند Firestore.
  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    return Complaint.fromMap(doc.id, doc.data() as Map<String, dynamic>?);
  }

  /// إنشاء شكوى من خريطة بيانات (منفصلة عن Firestore لتسهيل الاختبار).
  factory Complaint.fromMap(String? id, Map<String, dynamic>? data) {
    return Complaint(
      id: id,
      title: data?['title'] as String? ?? 'No Title',
      name: data?['name'] as String? ?? 'Unknown User',
      phone: data?['phone'] as String? ?? 'N/A',
      description: data?['description'] as String? ?? 'No Description',
      imageUrl: data?['imageUrl'] as String? ?? '',
      status: ComplaintStatus.fromValue(data?['status'] as String?),
      timestamp:
          (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data?['resolvedAt'] as Timestamp?)?.toDate(),
      userId: data?['userId'] as String?,
    );
  }

  /// تحويل الشكوى إلى خريطة جاهزة للحفظ في Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'name': name,
      'phone': phone,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'userId': userId,
    };
  }
}

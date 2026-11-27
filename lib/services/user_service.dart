import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// قراءة وتعديل الملف الشخصي للمستخدم في users/{uid}.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Future<UserProfile> getProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    return UserProfile.fromMap(snapshot.data());
  }

  /// تحديث حقول محددة فقط (مثلاً: {'name': 'Ahmed'}).
  Future<void> updateFields(String uid, Map<String, dynamic> fields) {
    return _doc(uid).set(fields, SetOptions(merge: true));
  }
}

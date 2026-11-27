import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// كل عمليات تسجيل الدخول والخروج والتحقق من صلاحية المسؤول.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// يصدر قيمة جديدة كلما سجّل المستخدم دخوله أو خروجه.
  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? getCurrentUserUID() => _auth.currentUser?.uid;

  /// إنشاء حساب جديد وحفظ بياناته الأساسية في users/{uid}.
  ///
  /// ملاحظة: Firebase يسجّل دخول المستخدم تلقائياً بعد إنشاء الحساب.
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'phone': phone,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.code}');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in error: ${e.code}');
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// يتحقق من وجود admins/{uid} وأن isAdmin = true.
  ///
  /// هذا الفحص لتوجيه الواجهة فقط. الحماية الحقيقية موجودة في firestore.rules.
  Future<bool> checkAdminRole(String uid) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      return adminDoc.exists && adminDoc.data()?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin role: $e');
      return false;
    }
  }

  /// تحويل رموز أخطاء Firebase إلى رسائل مفهومة للمستخدم.
  ///
  /// مشاريع Firebase الجديدة (مع حماية تعداد البريد) ترجع "invalid-credential"
  /// بدلاً من "user-not-found" و "wrong-password"، لذلك نتعامل مع الثلاثة.
  static String messageForError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'weak-password':
        return 'Password is too weak (must be at least 6 characters).';
      case 'email-already-in-use':
        return 'This email is already in use by another account.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled on the server.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

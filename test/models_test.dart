import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixltfast/models/complaint.dart';
import 'package:fixltfast/models/complaint_status.dart';
import 'package:fixltfast/models/user_profile.dart';
import 'package:fixltfast/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComplaintStatus', () {
    test('fromValue maps Firestore values', () {
      expect(ComplaintStatus.fromValue('Pending'), ComplaintStatus.pending);
      expect(ComplaintStatus.fromValue('InProgress'), ComplaintStatus.inProgress);
      expect(ComplaintStatus.fromValue('Completed'), ComplaintStatus.completed);
    });

    test('unknown or missing values fall back to pending', () {
      expect(ComplaintStatus.fromValue(null), ComplaintStatus.pending);
      expect(ComplaintStatus.fromValue('Resolved'), ComplaintStatus.pending);
    });

    test('stored values never change (existing data depends on them)', () {
      expect(ComplaintStatus.values.map((s) => s.value),
          ['Pending', 'InProgress', 'Completed']);
    });
  });

  group('Complaint', () {
    test('toFirestore and fromMap round-trip', () {
      final original = Complaint(
        title: 'Water leak',
        name: 'Sara',
        phone: '0555555555',
        description: 'Leak in the kitchen',
        imageUrl: 'https://example.com/a.jpg',
        status: ComplaintStatus.completed,
        timestamp: DateTime(2025, 5, 1, 10, 30),
        resolvedAt: DateTime(2025, 5, 2, 9, 0),
        userId: 'uid-1',
      );

      final map = original.toFirestore();
      expect(map['status'], 'Completed');
      expect(map['timestamp'], isA<Timestamp>());

      final restored = Complaint.fromMap('doc-1', map);
      expect(restored.id, 'doc-1');
      expect(restored.title, original.title);
      expect(restored.status, ComplaintStatus.completed);
      expect(restored.timestamp, original.timestamp);
      expect(restored.resolvedAt, original.resolvedAt);
      expect(restored.userId, 'uid-1');
    });

    test('fromMap uses safe defaults for missing fields', () {
      final c = Complaint.fromMap('x', {});
      expect(c.title, 'No Title');
      expect(c.imageUrl, '');
      expect(c.status, ComplaintStatus.pending);
      expect(c.resolvedAt, isNull);
    });
  });

  group('UserProfile', () {
    test('copyWith only changes the given field', () {
      const p = UserProfile(name: 'A', phone: '1', email: 'a@b.com');
      final q = p.copyWith(phone: '2');
      expect(q.name, 'A');
      expect(q.phone, '2');
      expect(q.email, 'a@b.com');
    });
  });

  group('AuthService.messageForError', () {
    test('invalid-credential shows the wrong password message', () {
      // مشاريع Firebase الجديدة ترجع invalid-credential بدل wrong-password
      expect(
        AuthService.messageForError(
            FirebaseAuthException(code: 'invalid-credential')),
        'Email or password is incorrect.',
      );
      expect(
        AuthService.messageForError(FirebaseAuthException(code: 'wrong-password')),
        'Email or password is incorrect.',
      );
    });

    test('unknown codes get a generic message', () {
      expect(
        AuthService.messageForError(FirebaseAuthException(code: 'weird')),
        'Something went wrong. Please try again.',
      );
    });
  });
}

import 'package:flutter/material.dart';

/// حالات الشكوى في مكان واحد بدل كتابة النصوص يدوياً في كل ملف.
///
/// [value] هي القيمة المخزنة في Firestore (يجب ألا تتغير حتى لا تضيع البيانات القديمة).
/// [label] هو النص الذي يظهر للمستخدم.
enum ComplaintStatus {
  pending('Pending', 'Pending'),
  inProgress('InProgress', 'In Progress'),
  completed('Completed', 'Completed');

  const ComplaintStatus(this.value, this.label);

  final String value;
  final String label;

  /// تحويل النص القادم من Firestore إلى حالة. أي قيمة غير معروفة تعتبر "Pending".
  static ComplaintStatus fromValue(String? value) {
    return ComplaintStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ComplaintStatus.pending,
    );
  }

  /// اللون المستخدم لعرض الحالة في الواجهة.
  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange.shade700;
      case ComplaintStatus.inProgress:
        return Colors.blue.shade700;
      case ComplaintStatus.completed:
        return Colors.green.shade700;
    }
  }
}

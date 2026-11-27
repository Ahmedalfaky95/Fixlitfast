// اختبارات الواجهة. تعمل بدون Firebase لأنها تختبر Widgets مستقلة.
//
// التشغيل:  flutter test

import 'package:fixltfast/models/complaint.dart';
import 'package:fixltfast/models/complaint_status.dart';
import 'package:fixltfast/widgets/complaint_card.dart';
import 'package:fixltfast/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyButton', () {
    testWidgets('shows its title and calls onPressed when tapped',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MyButton(
            color: Colors.blueGrey,
            title: 'Login',
            onPressed: () => tapped++,
          ),
        ),
      ));

      expect(find.text('Login'), findsOneWidget);
      await tester.tap(find.text('Login'));
      expect(tapped, 1);
    });

    testWidgets('uses the color it is given', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MyButton(color: Colors.red, title: 'X', onPressed: () {}),
        ),
      ));

      expect(
        find.byWidgetPredicate((w) => w is Material && w.color == Colors.red),
        findsOneWidget,
      );
    });
  });

  group('ComplaintCard', () {
    testWidgets('shows title, status label and description', (tester) async {
      final complaint = Complaint(
        id: '1',
        title: 'Broken elevator',
        name: 'Ahmed',
        phone: '0500000000',
        description: 'The elevator in building A is not working.',
        imageUrl: '',
        status: ComplaintStatus.inProgress,
        timestamp: DateTime(2025, 1, 2, 3, 4),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ComplaintCard(complaint: complaint)),
      ));

      expect(find.text('Broken elevator'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('The elevator in building A is not working.'),
          findsOneWidget);
      expect(find.text('Date: 2025-01-02 03:04'), findsOneWidget);
      // لا يوجد زر مرفق عندما لا توجد صورة
      expect(find.text('View Attachment'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaints_stream_list.dart';

/// الشكاوى المكتملة الخاصة بالمستخدم الحالي.
class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        Provider.of<AuthService>(context, listen: false).getCurrentUserUID();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Completed Complaints'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey,
      ),
      body: userId == null
          ? const _NotLoggedIn()
          : ComplaintsStreamList(
              createStream: () =>
                  Provider.of<ComplaintService>(context, listen: false)
                      .getCompletedComplaints(userId: userId),
              itemBuilder: (context, complaint) => ComplaintCard(
                key: ValueKey(complaint.id),
                complaint: complaint,
              ),
              empty: EmptyState(
                icon: Icons.assignment_turned_in,
                title: 'No completed complaints yet.',
                action: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                  label: const Text(
                    'Go Back',
                    style: TextStyle(
                        color: Colors.blueGrey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Please log in to view your complaints.',
          style: TextStyle(fontSize: 18, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

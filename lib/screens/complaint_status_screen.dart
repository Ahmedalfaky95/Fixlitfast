import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaints_stream_list.dart';
import 'new_complaint_screen.dart';

/// متابعة الشكاوى التي لم تكتمل بعد (Pending و In Progress).
class ComplaintStatusScreen extends StatelessWidget {
  const ComplaintStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        Provider.of<AuthService>(context, listen: false).getCurrentUserUID();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Status'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey,
      ),
      body: userId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Please log in to view your complaints status.',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey),
                  ),
                  child: const Text(
                    'Follow the status of your complaints and their updates in real time below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ComplaintsStreamList(
                    createStream: () =>
                        Provider.of<ComplaintService>(context, listen: false)
                            .getPendingOrInProgressComplaints(userId: userId),
                    itemBuilder: (context, complaint) => ComplaintCard(
                      key: ValueKey(complaint.id),
                      complaint: complaint,
                    ),
                    empty: EmptyState(
                      icon: Icons.assignment_turned_in,
                      title: 'No pending or in-progress complaints.',
                      action: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NewComplaintScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_circle,
                            color: Colors.blueGrey),
                        label: const Text(
                          'Submit a New Complaint',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

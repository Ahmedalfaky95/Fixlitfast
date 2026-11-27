import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint_status.dart';
import '../../services/complaint_service.dart';
import '../../widgets/admin_complaint_card.dart';
import '../../widgets/complaints_stream_list.dart';

/// الشكاوى قيد التنفيذ (InProgress).
class InProgressScreen extends StatelessWidget {
  const InProgressScreen({super.key});

  static const _actions = [
    StatusAction(
      label: 'Back to Pending',
      icon: Icons.undo,
      targetStatus: ComplaintStatus.pending,
      color: Colors.orange,
      successMessage: 'Complaint moved back to "Pending".',
      outlined: true,
    ),
    StatusAction(
      label: 'Complete',
      icon: Icons.done_all,
      targetStatus: ComplaintStatus.completed,
      color: Colors.green,
      successMessage: 'Complaint marked as "Completed".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: ComplaintsStreamList(
        createStream: () => Provider.of<ComplaintService>(context, listen: false)
            .getComplaintsByStatus(status: ComplaintStatus.inProgress),
        itemBuilder: (context, complaint) => AdminComplaintCard(
          key: ValueKey(complaint.id),
          complaint: complaint,
          actions: _actions,
        ),
        empty: const EmptyState(
          icon: Icons.engineering,
          iconColor: Colors.blue,
          title: 'No tasks in progress.',
          subtitle:
              'Either no pending complaints have been started, or all tasks are done.',
        ),
      ),
    );
  }
}

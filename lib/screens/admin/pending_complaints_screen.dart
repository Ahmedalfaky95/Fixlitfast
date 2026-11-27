import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint_status.dart';
import '../../services/complaint_service.dart';
import '../../widgets/admin_complaint_card.dart';
import '../../widgets/complaints_stream_list.dart';

/// الشكاوى الجديدة (Pending) التي لم تبدأ معالجتها بعد.
class PendingComplaintsScreen extends StatelessWidget {
  const PendingComplaintsScreen({super.key});

  static const _actions = [
    StatusAction(
      label: 'Start',
      icon: Icons.play_arrow,
      targetStatus: ComplaintStatus.inProgress,
      color: Colors.green,
      successMessage: 'Complaint moved to "In Progress".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: ComplaintsStreamList(
        createStream: () => Provider.of<ComplaintService>(context, listen: false)
            .getComplaintsByStatus(status: ComplaintStatus.pending),
        itemBuilder: (context, complaint) => AdminComplaintCard(
          key: ValueKey(complaint.id),
          complaint: complaint,
          actions: _actions,
        ),
        empty: const EmptyState(
          icon: Icons.assignment_turned_in_outlined,
          iconColor: Colors.green,
          title: 'No new complaints right now.',
          subtitle: 'Great work! Every complaint is being handled.',
        ),
      ),
    );
  }
}

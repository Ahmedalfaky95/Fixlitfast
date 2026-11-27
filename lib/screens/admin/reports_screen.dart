import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint_status.dart';
import '../../services/complaint_service.dart';
import '../../widgets/admin_complaint_card.dart';
import '../../widgets/complaints_stream_list.dart';

/// تقارير الشكاوى المكتملة.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: ComplaintsStreamList(
        createStream: () => Provider.of<ComplaintService>(context, listen: false)
            .getComplaintsByStatus(status: ComplaintStatus.completed),
        itemBuilder: (context, complaint) => AdminComplaintCard(
          key: ValueKey(complaint.id),
          complaint: complaint,
          showResolvedDate: true,
        ),
        empty: const EmptyState(
          icon: Icons.assignment_turned_in,
          iconColor: Colors.blueGrey,
          title: 'No completed reports yet.',
          subtitle: 'Complaints marked as "Completed" will appear here.',
        ),
      ),
    );
  }
}

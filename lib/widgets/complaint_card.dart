import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/complaint.dart';
import 'complaint_image_dialog.dart';

/// بطاقة عرض الشكوى للمستخدم العادي (للعرض فقط).
class ComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const ComplaintCard({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint.status;
    final statusColor = status.color;
    final submissionDate =
        DateFormat('yyyy-MM-dd HH:mm').format(complaint.timestamp);
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withValues(alpha: 0.6), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20, color: Colors.blueGrey),

            // الحالة الحالية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Status:',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  width: 120,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Description:',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              complaint.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text('Date: $submissionDate', style: theme.textTheme.bodySmall),
              ],
            ),

            if (complaint.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      showComplaintImageDialog(context, complaint.imageUrl),
                  icon: const Icon(Icons.image),
                  label: const Text('View Attachment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

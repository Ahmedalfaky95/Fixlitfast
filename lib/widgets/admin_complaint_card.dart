import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../models/complaint_status.dart';
import '../services/complaint_service.dart';
import 'complaint_image_dialog.dart';

/// إجراء يغيّر حالة الشكوى (زر في بطاقة المسؤول).
class StatusAction {
  final String label;
  final IconData icon;
  final ComplaintStatus targetStatus;
  final Color color;
  final String successMessage;

  /// true = زر بإطار فقط (OutlinedButton)، false = زر ممتلئ.
  final bool outlined;

  const StatusAction({
    required this.label,
    required this.icon,
    required this.targetStatus,
    required this.color,
    required this.successMessage,
    this.outlined = false,
  });
}

/// بطاقة الشكوى في شاشات المسؤول.
///
/// كانت هذه البطاقة مكررة في New_Progress و In_Progress و Reports
/// تحت أسماء متطابقة (ComplaintCard / ReportCard)، والآن نسخة واحدة.
class AdminComplaintCard extends StatefulWidget {
  final Complaint complaint;
  final List<StatusAction> actions;

  /// عرض تاريخ الإنجاز (لشاشة التقارير).
  final bool showResolvedDate;

  const AdminComplaintCard({
    super.key,
    required this.complaint,
    this.actions = const [],
    this.showResolvedDate = false,
  });

  @override
  State<AdminComplaintCard> createState() => _AdminComplaintCardState();
}

class _AdminComplaintCardState extends State<AdminComplaintCard> {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');
  bool _isUpdating = false;

  Future<void> _runAction(StatusAction action) async {
    final id = widget.complaint.id;
    final messenger = ScaffoldMessenger.of(context);

    if (id == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Error: complaint ID is missing, cannot update status.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await context
          .read<ComplaintService>()
          .updateComplaintStatus(id, action.targetStatus);
      // نستخدم messenger المحفوظ مسبقاً لأن البطاقة قد تختفي من القائمة بعد التحديث.
      messenger.showSnackBar(SnackBar(
        content: Text(action.successMessage),
        backgroundColor: action.color,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Update failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 16, color: valueColor ?? Colors.black87),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton() {
    final hasImage = widget.complaint.imageUrl.isNotEmpty;
    return InkWell(
      onTap: hasImage
          ? () => showComplaintImageDialog(context, widget.complaint.imageUrl)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasImage ? Colors.blueGrey : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasImage ? Icons.photo : Icons.image_not_supported,
                color: hasImage ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 5),
            Text(
              hasImage ? 'View Image' : 'No Image',
              style: TextStyle(
                color: hasImage ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(StatusAction action) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);
    final label =
        Text(action.label, style: const TextStyle(fontWeight: FontWeight.bold));

    if (action.outlined) {
      return OutlinedButton.icon(
        onPressed: () => _runAction(action),
        icon: Icon(action.icon, size: 20),
        label: label,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: action.color),
          foregroundColor: action.color,
          shape: shape,
          padding: padding,
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => _runAction(action),
      icon: Icon(action.icon, color: Colors.white),
      label: label,
      style: ElevatedButton.styleFrom(
        backgroundColor: action.color,
        foregroundColor: Colors.white,
        shape: shape,
        padding: padding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final statusColor = complaint.status.color;
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: widget.showResolvedDate
            ? BorderSide(color: statusColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Divider(height: 20, color: statusColor.withValues(alpha: 0.5)),

            _buildDetailRow(Icons.person, 'Complainant:', complaint.name),
            _buildDetailRow(Icons.phone, 'Phone:', complaint.phone),
            _buildDetailRow(Icons.access_time, 'Submitted:',
                _dateFormat.format(complaint.timestamp)),

            if (widget.showResolvedDate) ...[
              _buildDetailRow(Icons.done_all, 'Status:', complaint.status.label,
                  valueColor: statusColor),
              _buildDetailRow(
                Icons.check_circle_outline,
                'Resolved:',
                complaint.resolvedAt != null
                    ? _dateFormat.format(complaint.resolvedAt!)
                    : '—',
              ),
            ],

            const SizedBox(height: 10),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 15),

            // Wrap بدل Row حتى لا تتجاوز الأزرار عرض الشاشات الصغيرة.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildImageButton(),
                if (_isUpdating)
                  const CircularProgressIndicator()
                else if (widget.actions.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.actions.map(_buildActionButton).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

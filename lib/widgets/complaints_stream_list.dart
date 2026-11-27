import 'package:flutter/material.dart';

import '../models/complaint.dart';

/// قائمة شكاوى تُحدَّث لحظياً من Firestore، مع حالات الخطأ والتحميل والقائمة الفارغة.
///
/// الـ Stream يُنشأ مرة واحدة في initState، بدل إنشائه داخل build()
/// (كان يُعاد إنشاء الاشتراك في Firestore مع كل إعادة بناء للشاشة).
class ComplaintsStreamList extends StatefulWidget {
  const ComplaintsStreamList({
    super.key,
    required this.createStream,
    required this.itemBuilder,
    required this.empty,
  });

  /// تُستدعى مرة واحدة فقط لإنشاء الـ Stream.
  final Stream<List<Complaint>> Function() createStream;
  final Widget Function(BuildContext context, Complaint complaint) itemBuilder;

  /// ما يظهر عندما تكون القائمة فارغة.
  final Widget empty;

  @override
  State<ComplaintsStreamList> createState() => _ComplaintsStreamListState();
}

class _ComplaintsStreamListState extends State<ComplaintsStreamList> {
  late final Stream<List<Complaint>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.createStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Complaint>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Complaints stream error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load complaints.\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        final complaints = snapshot.data ?? const <Complaint>[];
        if (complaints.isEmpty) return widget.empty;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: complaints.length,
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, complaints[index]),
        );
      },
    );
  }
}

/// رسالة "لا توجد بيانات" موحّدة.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.grey.shade400, size: 80),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

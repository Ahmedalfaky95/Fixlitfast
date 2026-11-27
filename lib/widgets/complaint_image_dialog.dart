import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// عرض صورة الشكوى في نافذة مع إمكانية التكبير.
/// كان هذا الكود مكرراً في ثلاثة ملفات، والآن في مكان واحد.
void showComplaintImageDialog(BuildContext context, String imageUrl) {
  if (imageUrl.isEmpty) return;

  // استخدام https دائماً لتحميل آمن.
  final url = imageUrl.replaceFirst('http://', 'https://');

  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.blueGrey,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                const Text('Failed to load image.'),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: imageUrl));
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Image link copied to clipboard.'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

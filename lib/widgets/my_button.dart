import 'package:flutter/material.dart';

/// الزر الموحّد المستخدم في التطبيق.
class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.color,
    required this.title,
    required this.onPressed,
  });

  /// لون خلفية الزر.
  final Color color;
  final String title;

  /// null = الزر معطّل.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        elevation: 5,
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: MaterialButton(
          onPressed: onPressed,
          minWidth: 200,
          height: 42,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

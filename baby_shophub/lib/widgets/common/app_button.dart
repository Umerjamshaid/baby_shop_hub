import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double? width;
  final String variant; // 'primary', 'secondary', 'outline'

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.variant = 'primary',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (variant) {
      case 'secondary':
        backgroundColor = theme.colorScheme.secondary;
        foregroundColor = Colors.white;
        borderColor = theme.colorScheme.secondary;
        break;
      case 'outline':
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primaryColor;
        borderColor = theme.primaryColor;
        break;
      default: // primary
        backgroundColor = theme.primaryColor;
        foregroundColor = Colors.white;
        borderColor = theme.primaryColor;
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double? width;
  final String variant; // 'primary', 'secondary', 'outline'
  final String? size; // 'small', 'medium', 'large'
  final Color? color; // Custom color

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.variant = 'primary',
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    double verticalPadding;
    double horizontalPadding;
    double fontSize;

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
    // Set size-based properties
    switch (size) {
      case 'small':
        verticalPadding = 8;
        horizontalPadding = 16;
        fontSize = 14;
        break;
      case 'large':
        verticalPadding = 16;
        horizontalPadding = 32;
        fontSize = 18;
        break;
      default: // medium
        verticalPadding = 12;
        horizontalPadding = 24;
        fontSize = 16;
    }




    switch (variant) {
      case 'secondary':
        backgroundColor = color ?? theme.colorScheme.secondary;
        foregroundColor = Colors.white;
        borderColor = color ?? theme.colorScheme.secondary;
        break;
      case 'outline':
        backgroundColor = Colors.transparent;
        foregroundColor = color ?? theme.primaryColor;
        borderColor = color ?? theme.primaryColor;
        break;
      default: // primary
        backgroundColor = color ?? theme.primaryColor;
        foregroundColor = Colors.white;
        borderColor = color ?? theme.primaryColor;
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

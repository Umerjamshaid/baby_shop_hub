import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double? width;
  final String variant; // 'primary', 'secondary', 'outline'
  final String? size; // 'small', 'medium', 'large'
  final Color? color;
  final bool loading; // ✅ make it bool

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.variant = 'primary',
    this.size,
    this.color,
    this.loading = false, // ✅ default false
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

    // Variant styles
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
        onPressed: loading ? null : onPressed, // ✅ disable when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  text,
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

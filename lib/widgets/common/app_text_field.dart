import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Convenience shared outlined text field used by forms across the app.
/// Centralises the border radius + outline decoration so every form uses the
/// same look without repeating the InputDecoration.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
    this.textInputAction,
    this.suffixIcon,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textAlignVertical,
    this.alignLabelWithHint = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextAlignVertical? textAlignVertical;
  final bool alignLabelWithHint;
  final bool enabled;

  static const double radius = 14;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      textAlignVertical: textAlignVertical,
      enabled: enabled,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        alignLabelWithHint: alignLabelWithHint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
        ),
      ),
    );
  }
}

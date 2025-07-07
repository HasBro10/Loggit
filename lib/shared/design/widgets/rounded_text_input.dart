import 'package:flutter/material.dart';
import '../color_guide.dart';
import '../spacing.dart';
import '../fonts.dart';

class RoundedTextInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const RoundedTextInput({
    super.key,
    this.controller,
    required this.hintText,
    this.icon,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LoggitColors.lightGray,
        borderRadius: BorderRadius.circular(LoggitSpacing.xl),
      ),
      padding: EdgeInsets.symmetric(horizontal: LoggitSpacing.lg),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: LoggitColors.lighterGraySubtext),
          if (icon != null) SizedBox(width: LoggitSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: LoggitFonts.body.copyWith(
                  color: LoggitColors.lighterGraySubtext,
                ),
                isDense: true,
              ),
              style: LoggitFonts.body.copyWith(
                color: LoggitColors.darkGrayText,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

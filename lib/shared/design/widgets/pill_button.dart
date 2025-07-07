import 'package:flutter/material.dart';
import '../spacing.dart';
import '../fonts.dart';
import '../shadows.dart';

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(LoggitSpacing.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(LoggitSpacing.xl),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: LoggitSpacing.xl,
            vertical: LoggitSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoggitSpacing.xl),
            boxShadow: [LoggitShadows.button],
            border: selected ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: selected ? Colors.white : color, size: 20),
              if (icon != null) SizedBox(width: LoggitSpacing.sm),
              Text(
                label,
                style: LoggitFonts.button.copyWith(
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../color_guide.dart';
import '../spacing.dart';
import '../fonts.dart';
import '../shadows.dart';

class StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final Color backgroundColor;
  final Color textColor;
  final Color? dotColor;

  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      padding: EdgeInsets.symmetric(
        vertical: LoggitSpacing.xl,
        horizontal: LoggitSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? LoggitColors.darkCard : backgroundColor,
        borderRadius: BorderRadius.circular(LoggitSpacing.borderRadius),
        boxShadow: [LoggitShadows.card],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                backgroundColor: isDark
                    ? LoggitColors.darkAccent.withOpacity(0.5)
                    : backgroundColor.withOpacity(0.5),
                radius: 24,
                child: Icon(
                  icon,
                  color: isDark ? LoggitColors.darkText : textColor,
                  size: 28,
                ),
              ),
              if (dotColor != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? LoggitColors.darkAccent : dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: LoggitSpacing.md),
          Text(
            value.toString(),
            style: LoggitFonts.headline.copyWith(
              color: isDark ? LoggitColors.darkText : textColor,
              fontSize: 24,
            ),
          ),
          SizedBox(height: LoggitSpacing.xs),
          Text(
            title,
            style: LoggitFonts.body.copyWith(
              color: isDark ? LoggitColors.darkText : textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

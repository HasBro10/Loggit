import 'package:flutter/material.dart';
import '../color_guide.dart';
import '../spacing.dart';

class FeatureCardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color cardColor;
  final bool selected;
  final VoidCallback? onTap;
  final Color? textColor;

  const FeatureCardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.cardColor,
    this.selected = false,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = 20;
            double iconSize = 32;
            double avatarRadius = 24;
            double horizontalPadding = 24;
            if (constraints.maxWidth < 180) {
              fontSize = 14;
              iconSize = 20;
              avatarRadius = 16;
              horizontalPadding = 8;
            } else if (constraints.maxWidth < 240) {
              fontSize = 16;
              iconSize = 24;
              avatarRadius = 18;
              horizontalPadding = 12;
            } else if (constraints.maxWidth < 320) {
              fontSize = 18;
              iconSize = 28;
              avatarRadius = 20;
              horizontalPadding = 16;
            }
            return Container(
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: isDark ? LoggitColors.darkCard : cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  CircleAvatar(
                    backgroundColor: isDark
                        ? LoggitColors.darkAccent
                        : iconBgColor,
                    radius: avatarRadius,
                    child: Icon(icon, color: iconColor, size: iconSize),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color:
                              textColor ??
                              (isDark
                                  ? LoggitColors.darkText
                                  : LoggitColors.darkGrayText),
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

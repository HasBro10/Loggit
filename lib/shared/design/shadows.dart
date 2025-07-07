import 'package:flutter/material.dart';
import 'color_guide.dart';

/// Loggit Shadow Tokens
/// Use these for all shadows in the app.
class LoggitShadows {
  static const BoxShadow card = BoxShadow(
    color: LoggitColors.mediumShadow,
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const BoxShadow button = BoxShadow(
    color: LoggitColors.softShadow,
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow divider = BoxShadow(
    color: LoggitColors.divider,
    blurRadius: 0.5,
    offset: Offset(0, 1),
  );
}

import 'package:flutter/material.dart';

/// Loggit Font Tokens
/// Defines font families and text styles for consistency.
class LoggitFonts {
  static const String primaryFont = 'Inter';
  static const String fallbackFont = 'Roboto';

  static const TextStyle headline = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    letterSpacing: -0.5,
  );
  static const TextStyle title = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.normal,
    fontSize: 16,
  );
  static const TextStyle label = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.1,
  );
  static const TextStyle button = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.2,
  );
}

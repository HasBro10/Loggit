import 'package:flutter/material.dart';
import 'dart:math';

/// Global responsive utilities for Loggit
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double maxSheetWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Clamp between 320 and 500
    return width.clamp(320, 500).toDouble();
  }

  static EdgeInsets sheetPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double responsiveFont(
    BuildContext context,
    double base, {
    double min = 12,
    double max = 28,
  }) {
    final width = MediaQuery.of(context).size.width;
    double size = base;
    if (isDesktop(context)) size = base * 1.2;
    if (isTablet(context)) size = base * 1.1;
    return size.clamp(min, max);
  }

  static double responsiveIcon(
    BuildContext context,
    double base, {
    double min = 20,
    double max = 48,
  }) {
    final width = MediaQuery.of(context).size.width;
    double size = base;
    if (isDesktop(context)) size = base * 1.2;
    if (isTablet(context)) size = base * 1.1;
    return size.clamp(min, max);
  }
}

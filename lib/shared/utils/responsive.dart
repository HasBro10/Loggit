import 'package:flutter/material.dart';
import 'dart:math';

/// Global responsive utilities for Loggit
class Responsive {
  // Enhanced breakpoints
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
  
  // Additional breakpoints for better granularity
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 375;
  static bool isLargeMobile(BuildContext context) =>
      MediaQuery.of(context).size.width >= 375 && 
      MediaQuery.of(context).size.width < 600;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

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

  // Enhanced responsive spacing
  static EdgeInsets screenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    if (isSmallMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double cardPadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    if (isSmallMobile(context)) return 16;
    return 20;
  }

  static double responsiveFont(
    BuildContext context,
    double base, {
    double min = 12,
    double max = 28,
  }) {
    final width = MediaQuery.of(context).size.width;
    double size = base;
    
    if (isDesktop(context)) {
      size = base * 1.2;
    } else if (isTablet(context)) {
      size = base * 1.1;
    } else if (isSmallMobile(context)) {
      size = base * 0.9;
    }
    
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
    
    if (isDesktop(context)) {
      size = base * 1.2;
    } else if (isTablet(context)) {
      size = base * 1.1;
    } else if (isSmallMobile(context)) {
      size = base * 0.9;
    }
    
    return size.clamp(min, max);
  }

  // Adaptive spacing based on screen size
  static double adaptiveSpacing(BuildContext context, double base) {
    if (isDesktop(context)) return base * 1.5;
    if (isTablet(context)) return base * 1.2;
    if (isSmallMobile(context)) return base * 0.8;
    return base;
  }

  // Responsive grid columns
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  // Responsive max width for content
  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isDesktop(context)) return min(width * 0.8, 1200);
    if (isTablet(context)) return min(width * 0.9, 800);
    return width;
  }

  // Safe area helper
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Responsive button size
  static Size buttonSize(BuildContext context) {
    if (isDesktop(context)) return const Size(200, 56);
    if (isTablet(context)) return const Size(180, 52);
    if (isSmallMobile(context)) return const Size(140, 44);
    return const Size(160, 48);
  }
}

import 'package:flutter/material.dart';

/// Loggit Color Tokens
/// All app colors are defined here for consistency.
class LoggitColors {
  // Primary Accents
  static const Color teal = Color(0xFF14B8A6); // Tasks, FAB
  static const Color tealDark = Color(0xFF0D9488); // Active teal
  static const Color indigo = Color(0xFF6366F1); // Expenses
  static const Color indigoLight = Color(0xFFEEF2FF); // Expense cards

  // Backgrounds
  static const Color lightGray = Color(0xFFF9FAFB); // General background
  static const Color pureWhite = Color(0xFFFFFFFF); // Chat/cards
  static const Color darkCharcoal = Color(0xFF1F2937); // Dark mode bg
  static const Color darkGrayCard = Color(0xFF374151); // Dark mode card

  // Text
  static const Color darkGrayText = Color(0xFF111827); // Main text
  static const Color lighterGraySubtext = Color(0xFF6B7280); // Subtext
  static const Color lightGrayDarkMode = Color(0xFFD1D5DB); // Subtext dark
  static const Color pureWhiteText = Color(0xFFF9FAFB); // Text dark mode

  // Status (Cards)
  static const Color pendingTasksBg = Color(0xFFFFF7ED);
  static const Color pendingTasksText = Color(0xFF92400E);
  static const Color completedTasksBg = Color(0xFFECFDF5);
  static const Color completedTasksText = Color(0xFF065F46);
  static const Color expensesBg = Color(0xFFEEF2FF);
  static const Color expensesText = Color(0xFF3730A3);
  static const Color remindersBg = Color(0xFFFEF2F2);
  static const Color remindersText = Color(0xFF991B1B);

  // Dividers & Shadows
  static const Color divider = Color(0xFFE5E7EB);
  static const Color mediumShadow = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color softShadow = Color(0x1A000000); // rgba(0,0,0,0.10)

  // ChatGPT Dark Mode Palette
  static const Color darkBg = Color(0xFF343541); // Main background
  static const Color darkCard = Color(0xFF444654); // Card/sheet/chat AI bubble
  static const Color darkUserBubble = Color(0xFF2A2B32); // User chat bubble
  static const Color darkText = Color(0xFFFFFFFF); // Main text
  static const Color darkSubtext = Color(0xFFECECF1); // Subtle text
  static const Color darkAccent = Color(0xFF10A37F); // Accent (teal/green)
  static const Color darkBorder = Color(0xFF565869); // Borders/dividers
  static const Color darkPressed = Color(0xFF565869); // Pressed/hover state
}

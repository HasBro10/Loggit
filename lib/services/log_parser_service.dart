import '../features/expenses/expense_model.dart';
import '../features/tasks/task_model.dart' as tasks;
import '../features/reminders/reminder_model.dart' as reminders;
import '../features/notes/note_model.dart';
import '../features/gym/gym_log_model.dart';
import '../models/log_entry.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef DeleteIntent = Map<String, dynamic>;

enum LogType { reminder, task, gym, expense, unknown }

class ParsedLog {
  final LogType type;
  final String? action;
  final DateTime? dateTime;
  final double? amount;
  final String? category;
  final String? recurrence;
  final String? raw;

  ParsedLog({
    required this.type,
    this.action,
    this.dateTime,
    this.amount,
    this.category,
    this.recurrence,
    this.raw,
  });
}

class LogParserService {
  static ParsedLog parseUserInput(String input) {
    final normalized = input.trim().toLowerCase();

    // Patterns for each type (add more as you learn)
    final patterns = [
      // Reminders
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'(remind me|set a reminder|create a reminder)[^a-zA-Z0-9]*(to )?(?<action>.+?)( at | on | for )?(?<datetime>.+)?',
          caseSensitive: false,
        ),
      },
      // Tasks
      {
        'type': LogType.task,
        'regex': RegExp(
          r'(add|create|set) (a )?task[^a-zA-Z0-9]*(to )?(?<action>.+?)( at | on | for )?(?<datetime>.+)?',
          caseSensitive: false,
        ),
      },
      // Expenses
      {
        'type': LogType.expense,
        'regex': RegExp(
          r'(spent|pay|bought|purchase|expense)[^a-zA-Z0-9]*(?<amount>\d+(\.\d+)?)( on )?(?<category>.+)?',
          caseSensitive: false,
        ),
      },
      // Gym logs
      {
        'type': LogType.gym,
        'regex': RegExp(
          r'(gym|workout|exercise|did|completed)[^a-zA-Z0-9]*(?<action>.+?)( at | on | for )?(?<datetime>.+)?',
          caseSensitive: false,
        ),
      },
    ];

    for (final pattern in patterns) {
      final match = pattern['regex']!.firstMatch(normalized);
      if (match != null) {
        final type = pattern['type'] as LogType;
        final action = match.namedGroup('action');
        final dateTimeStr = match.namedGroup('datetime');
        final amountStr = match.namedGroup('amount');
        final category = match.namedGroup('category');

        // Parse date/time and amount if present
        DateTime? dateTime;
        if (dateTimeStr != null) {
          dateTime = _parseSimpleDateTime(dateTimeStr);
        }
        double? amount;
        if (amountStr != null) {
          amount = double.tryParse(amountStr);
        }

        return ParsedLog(
          type: type,
          action: action,
          dateTime: dateTime,
          amount: amount,
          category: category,
          raw: input,
        );
      }
    }

    // Fallback: unknown type
    return ParsedLog(type: LogType.unknown, raw: input);
  }

  // --- 2. Simple Date/Time Parsing ---
  static DateTime? _parseSimpleDateTime(String input) {
    final now = DateTime.now();
    final lower = input.toLowerCase().trim();

    if (lower.contains('tomorrow')) {
      // e.g. "tomorrow at 2pm"
      final timeMatch = RegExp(
        r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      int hour = 9;
      int minute = 0;
      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = timeMatch.group(3) != null
            ? int.parse(timeMatch.group(3)!)
            : 0;
        final ampm = timeMatch.group(4);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
      }
      final tomorrow = now.add(Duration(days: 1));
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      );
    }

    // e.g. "on the 18th", "for 19th"
    final dateMatch = RegExp(r'(\d{1,2})(st|nd|rd|th)?').firstMatch(lower);
    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      final month = now.month;
      final year = now.year;
      return DateTime(year, month, day, 9, 0); // Default 9am
    }

    // e.g. "at 2pm"
    final timeMatch = RegExp(
      r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(3) != null
          ? int.parse(timeMatch.group(3)!)
          : 0;
      final ampm = timeMatch.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    // Add more patterns as needed!
    return null;
  }
}

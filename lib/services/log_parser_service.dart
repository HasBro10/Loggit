import '../features/expenses/expense_model.dart';
import '../features/tasks/task_model.dart' as tasks;
import '../features/reminders/reminder_model.dart' as reminders;
import '../features/notes/note_model.dart';
import '../features/gym/gym_log_model.dart';
import '../models/log_entry.dart';
import 'package:flutter/material.dart';

class LogParserService {
  static LogEntry? parseMessage(String message) {
    // Try parsing as expense first (existing functionality)
    final expense = _parseExpense(message);
    if (expense != null) return expense;

    // Try parsing as task
    final task = _parseTask(message);
    if (task != null) return task;

    // Try parsing as reminder
    final reminder = _parseReminder(message);
    if (reminder != null) return reminder;

    // Try parsing as note
    final note = _parseNote(message);
    if (note != null) return note;

    // Try parsing as gym log
    final gymLog = _parseGymLog(message);
    if (gymLog != null) return gymLog;

    return null;
  }

  static Expense? _parseExpense(String message) {
    final regex = RegExp(r'^(.+?)\s+£?(\d+\.?\d*)$');
    final match = regex.firstMatch(message.trim());

    if (match != null) {
      final category = match.group(1)!.trim();
      final amountStr = match.group(2)!;
      final amount = double.tryParse(amountStr);

      if (amount != null && amount > 0) {
        return Expense(
          category: category,
          amount: amount,
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  static tasks.Task? _parseTask(String message) {
    // Remove colon and recognize 'task' at the start
    final cleaned = message.trim().replaceFirst(
      RegExp(r'^(task|todo|t)[:\s]+', caseSensitive: false),
      '',
    );
    final lower = cleaned.toLowerCase();
    String title = cleaned;
    DateTime? dueDate;
    tasks.RecurrenceType recurrenceType = tasks.RecurrenceType.none;
    List<int>? customDays;
    int? interval;
    TimeOfDay? timeOfDay;

    // Date/time patterns
    final now = DateTime.now();
    if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      dueDate = now.add(const Duration(days: 1));
    } else if (RegExp(r'\btoday\b').hasMatch(lower)) {
      dueDate = now;
    } else if (RegExp(r'\bnext week\b').hasMatch(lower)) {
      dueDate = now.add(const Duration(days: 7));
    } else if (RegExp(r'\bin (\d+) days?\b').hasMatch(lower)) {
      final match = RegExp(r'\bin (\d+) days?\b').firstMatch(lower);
      if (match != null) {
        dueDate = now.add(Duration(days: int.parse(match.group(1)!)));
      }
    } else if (RegExp(r'\bon the (\d+)(st|nd|rd|th)').hasMatch(lower)) {
      final match = RegExp(r'\bon the (\d+)(st|nd|rd|th)').firstMatch(lower);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        dueDate = DateTime(now.year, now.month, day);
      }
    }

    // Time pattern
    final timeMatch = RegExp(
      r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null
          ? int.parse(timeMatch.group(2)!)
          : 0;
      final ampm = timeMatch.group(3);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      timeOfDay = TimeOfDay(hour: hour, minute: minute);
    }

    // Recurrence patterns
    if (RegExp(r'every day|daily').hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.daily;
      customDays = [1, 2, 3, 4, 5];
    } else if (RegExp(r'every weekend').hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.custom;
      customDays = [6, 7];
    } else if (RegExp(r'every week|weekly').hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.weekly;
    } else if (RegExp(r'every month|monthly').hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.monthly;
    } else if (RegExp(r'every other day').hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.everyNDays;
      interval = 2;
    } else if (RegExp(r'every (\d+) days?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) days?').firstMatch(lower);
      if (match != null) {
        recurrenceType = tasks.RecurrenceType.everyNDays;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(r'every (\d+) weeks?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) weeks?').firstMatch(lower);
      if (match != null) {
        recurrenceType = tasks.RecurrenceType.everyNWeeks;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(r'every (\d+) months?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) months?').firstMatch(lower);
      if (match != null) {
        recurrenceType = tasks.RecurrenceType.everyNMonths;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(
      r'every (monday|tuesday|wednesday|thursday|friday|saturday|sunday)( and (monday|tuesday|wednesday|thursday|friday|saturday|sunday))*',
    ).hasMatch(lower)) {
      recurrenceType = tasks.RecurrenceType.custom;
      final days = <int>[];
      final dayMap = {
        'monday': 1,
        'tuesday': 2,
        'wednesday': 3,
        'thursday': 4,
        'friday': 5,
        'saturday': 6,
        'sunday': 7,
      };
      final matches = RegExp(
        r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
      ).allMatches(lower);
      for (final m in matches) {
        days.add(dayMap[m.group(1)!]!);
      }
      customDays = days;
    }

    // Remove recurrence/date/time phrases from title
    title = title
        .replaceAll(
          RegExp(
            r'every (day|weekday|weekend|week|month|other day|\d+ days?|\d+ weeks?|\d+ months?|monday|tuesday|wednesday|thursday|friday|saturday|sunday|daily|weekly|monthly)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'at \d{1,2}(:\d{2})?\s*(am|pm)?', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'tomorrow|today|next week|in \d+ days?|on the \d+(st|nd|rd|th)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isNotEmpty) {
      return tasks.Task(
        title: title,
        dueDate: dueDate,
        recurrenceType: recurrenceType,
        customDays: customDays,
        interval: interval,
        timeOfDay: timeOfDay,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  static reminders.Reminder? _parseReminder(String message) {
    // Remove colon and recognize 'reminder' or 'remind' at the start
    final cleaned = message.trim().replaceFirst(
      RegExp(r'^(reminder|remind)[:\s]+', caseSensitive: false),
      '',
    );
    final lower = cleaned.toLowerCase();
    String title = cleaned;
    DateTime? reminderTime;
    TimeOfDay? timeOfDay;
    reminders.RecurrenceType recurrenceType = reminders.RecurrenceType.none;
    List<int>? customDays;
    int? interval;
    DateTime? endDate;
    // Date/time patterns (same as task)
    final now = DateTime.now();
    if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      reminderTime = now.add(const Duration(days: 1));
    } else if (RegExp(r'\btoday\b').hasMatch(lower)) {
      reminderTime = now;
    } else if (RegExp(r'\bnext week\b').hasMatch(lower)) {
      reminderTime = now.add(const Duration(days: 7));
    } else if (RegExp(r'\bin (\d+) days?\b').hasMatch(lower)) {
      final match = RegExp(r'\bin (\d+) days?\b').firstMatch(lower);
      if (match != null) {
        reminderTime = now.add(Duration(days: int.parse(match.group(1)!)));
      }
    } else if (RegExp(r'\bon the (\d+)(st|nd|rd|th)').hasMatch(lower)) {
      final match = RegExp(r'\bon the (\d+)(st|nd|rd|th)').firstMatch(lower);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        reminderTime = DateTime(now.year, now.month, day);
      }
    }
    // Time pattern
    final timeMatch = RegExp(
      r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null
          ? int.parse(timeMatch.group(2)!)
          : 0;
      final ampm = timeMatch.group(3);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      timeOfDay = TimeOfDay(hour: hour, minute: minute);
    }
    // Recurrence patterns (same as task)
    if (RegExp(r'every day|daily').hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.daily;
      customDays = [1, 2, 3, 4, 5];
    } else if (RegExp(r'every weekend').hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.custom;
      customDays = [6, 7];
    } else if (RegExp(r'every week|weekly').hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.weekly;
    } else if (RegExp(r'every month|monthly').hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.monthly;
    } else if (RegExp(r'every other day').hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.everyNDays;
      interval = 2;
    } else if (RegExp(r'every (\d+) days?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) days?').firstMatch(lower);
      if (match != null) {
        recurrenceType = reminders.RecurrenceType.everyNDays;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(r'every (\d+) weeks?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) weeks?').firstMatch(lower);
      if (match != null) {
        recurrenceType = reminders.RecurrenceType.everyNWeeks;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(r'every (\d+) months?').hasMatch(lower)) {
      final match = RegExp(r'every (\d+) months?').firstMatch(lower);
      if (match != null) {
        recurrenceType = reminders.RecurrenceType.everyNMonths;
        interval = int.parse(match.group(1)!);
      }
    } else if (RegExp(
      r'every (monday|tuesday|wednesday|thursday|friday|saturday|sunday)( and (monday|tuesday|wednesday|thursday|friday|saturday|sunday))*',
    ).hasMatch(lower)) {
      recurrenceType = reminders.RecurrenceType.custom;
      final days = <int>[];
      final dayMap = {
        'monday': 1,
        'tuesday': 2,
        'wednesday': 3,
        'thursday': 4,
        'friday': 5,
        'saturday': 6,
        'sunday': 7,
      };
      final matches = RegExp(
        r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
      ).allMatches(lower);
      for (final m in matches) {
        days.add(dayMap[m.group(1)!]!);
      }
      customDays = days;
    }
    // Remove recurrence/date/time phrases from title
    title = title
        .replaceAll(
          RegExp(
            r'every (day|weekday|weekend|week|month|other day|\d+ days?|\d+ weeks?|\d+ months?|monday|tuesday|wednesday|thursday|friday|saturday|sunday|daily|weekly|monthly)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'at \d{1,2}(:\d{2})?\s*(am|pm)?', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'tomorrow|today|next week|in \d+ days?|on the \d+(st|nd|rd|th)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isNotEmpty) {
      return reminders.Reminder(
        title: title,
        reminderTime:
            reminderTime ?? DateTime.now().add(const Duration(hours: 1)),
        timestamp: DateTime.now(),
        recurrenceType: recurrenceType,
        customDays: customDays,
        interval: interval,
        endDate: endDate,
      );
    }
    return null;
  }

  static Note? _parseNote(String message) {
    // Patterns for notes:
    // "Note: Client prefers phone calls"
    // "Note that John likes coffee"
    final notePatterns = [
      RegExp(r'^note[:\s]+(.+) 24', caseSensitive: false),
      RegExp(r'^note that\s+(.+) 24', caseSensitive: false),
    ];

    for (final pattern in notePatterns) {
      final match = pattern.firstMatch(message.trim());
      if (match != null) {
        final content = match.group(1)!.trim();
        if (content.isNotEmpty) {
          return Note(
            title: 'Note',
            content: content,
            timestamp: DateTime.now(),
          );
        }
      }
    }

    return null;
  }

  static GymLog? _parseGymLog(String message) {
    // Patterns for gym logs:
    // "Squats 3 sets x 10 reps"
    // "Bench press 5x5 80kg"
    // "Workout: Deadlifts 3x8"
    final gymPatterns = [
      RegExp(
        r'^(.+?)\s+(\d+)\s*sets?\s*x\s*(\d+)\s*reps?(?:\s+(\d+(?:\.\d+)?)\s*kg)?$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?)\s+(\d+)x(\d+)(?:\s+(\d+(?:\.\d+)?)\s*kg)?$',
        caseSensitive: false,
      ),
      RegExp(
        r'^workout[:\s]+(.+?)\s+(\d+)\s*sets?\s*x\s*(\d+)\s*reps?(?:\s+(\d+(?:\.\d+)?)\s*kg)?$',
        caseSensitive: false,
      ),
    ];

    for (final pattern in gymPatterns) {
      final match = pattern.firstMatch(message.trim());
      if (match != null) {
        final exerciseName = match.group(1)!.trim();
        final sets = int.tryParse(match.group(2)!) ?? 0;
        final reps = int.tryParse(match.group(3)!) ?? 0;
        final weight = match.group(4) != null
            ? double.tryParse(match.group(4)!)
            : null;

        if (exerciseName.isNotEmpty && sets > 0 && reps > 0) {
          final exercise = Exercise(
            name: exerciseName,
            sets: sets,
            reps: reps,
            weight: weight,
          );

          return GymLog(
            workoutName: 'Workout',
            exercises: [exercise],
            timestamp: DateTime.now(),
          );
        }
      }
    }

    return null;
  }
}

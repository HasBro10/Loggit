import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../features/expenses/expense_model.dart';
import '../features/tasks/task_model.dart' as tasks;
import '../features/reminders/reminder_model.dart' as reminders;
import '../features/gym/gym_log_model.dart';

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
  final bool hasTime; // true if time was present in the input

  ParsedLog({
    required this.type,
    this.action,
    this.dateTime,
    this.amount,
    this.category,
    this.recurrence,
    this.raw,
    this.hasTime = true,
  });
}

class LogParserService {
  static LogEntry? parseMessage(String input) {
    final parsed = parseUserInput(input);

    if (parsed.type == LogType.unknown) {
      return null;
    }

    switch (parsed.type) {
      case LogType.reminder:
        if (parsed.dateTime != null) {
          return reminders.Reminder(
            title: parsed.action ?? 'Reminder',
            reminderTime: parsed.dateTime!,
            timestamp: DateTime.now(),
          );
        }
        break;
      case LogType.task:
        return tasks.Task(
          title: parsed.action ?? 'Task',
          description: null,
          dueDate: parsed.dateTime,
          timeOfDay: parsed.dateTime != null
              ? TimeOfDay(
                  hour: parsed.dateTime!.hour,
                  minute: parsed.dateTime!.minute,
                )
              : null,
          priority: tasks.TaskPriority.medium,
          status: tasks.TaskStatus.notStarted,
          reminder: tasks.ReminderType.none,
          category: parsed.category,
          timestamp: DateTime.now(),
        );
      case LogType.expense:
        if (parsed.amount != null) {
          return Expense(
            category: parsed.category ?? 'Other',
            amount: parsed.amount!,
            timestamp: DateTime.now(),
          );
        }
        break;
      case LogType.gym:
        if (parsed.action != null) {
          return GymLog(
            workoutName: parsed.action!,
            exercises: [
              Exercise(name: parsed.action!, sets: 1, reps: 10, weight: null),
            ],
            timestamp: DateTime.now(),
          );
        }
        break;
      case LogType.unknown:
        return null;
    }

    return null;
  }

  static ParsedLog parseUserInput(String input) {
    final normalized = input.trim().toLowerCase();
    print('DEBUG: [parseUserInput] input: $input');

    // Patterns for each type (add more as you learn)
    final patterns = [
      // Time-only task input (e.g., 'add a task doctor's appointment 6:30 pm' or 'add a task doctor's appointment, 6:30 pm')
      {
        'type': LogType.task,
        'regex': RegExp(
          r'^(add|create|set|new)\s+(a\s+)?(task|todo|item)(?:\s*(to|for))?\s+(.+?)[,]?\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)$',
          caseSensitive: false,
        ),
      },
      // Tasks - MUST COME AFTER the time-only pattern to avoid greedy match
      {
        'type': LogType.task,
        // (1) trigger, (2) optional "a", (3) task/todo/item, (4) optional to/for, (5) action, (6) date/time
        'regex': RegExp(
          r'^(add|create|set|new)\s+(a\s+)?(task|todo|item)(?:\s*(to|for))?\s+(.+?)\s*(tomorrow|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|\d{1,2}(:\d{2})?\s*(am|pm)?\s+\d{1,2}(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)|\d{1,2}(:\d{2})?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(st|nd|rd|th)?)?$',
          caseSensitive: false,
        ),
      },
      // Reminders
      {
        'type': LogType.reminder,
        // (1) trigger, (2) to/for, (3) action, (4) date/time
        'regex': RegExp(
          r'(remind me|set reminder|create reminder|reminder|set a reminder|create a reminder|add reminder|new reminder|set up reminder|put reminder|add a reminder|schedule a reminder|set up a reminder|remind me to|remind me about|remind me of)(?:\s*(to|for))?\s*(.+?)\s*(tomorrow|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|\d{1,2}(:\d{2})?\s*(am|pm)?\s+\d{1,2}(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)|\d{1,2}(:\d{2})?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(st|nd|rd|th)?)?$',
          caseSensitive: false,
        ),
      },
      // Standalone time input (for when user just types a time)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
          caseSensitive: false,
        ),
      },
      // "for [time]" input (common when adding time to existing task/reminder)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^for\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
          caseSensitive: false,
        ),
      },
      // Standalone date input (for when user just types a date)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$',
          caseSensitive: false,
        ),
      },
      // Standalone date input (month day format)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?$',
          caseSensitive: false,
        ),
      },
      // Combined time and date input (for when user types both together)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$',
          caseSensitive: false,
        ),
      },
      // Combined time and date input (month day format)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?$',
          caseSensitive: false,
        ),
      },

      // Expenses
      {
        'type': LogType.expense,
        // (1) trigger, (2) amount, (3) decimal, (4) category
        'regex': RegExp(
          r'(spent|pay|bought|purchase|expense)[^a-zA-Z0-9]*(\d+(?:\.\d+)?)(?: on )?(.*)?',
          caseSensitive: false,
        ),
      },
      // Gym logs
      {
        'type': LogType.gym,
        // (1) trigger, (2) action, (3) datetime
        'regex': RegExp(
          r'(gym|workout|exercise|did|completed)[^a-zA-Z0-9]*(.+?)(?: at | on | for )?(.*)?',
          caseSensitive: false,
        ),
      },
    ];

    for (final pattern in patterns) {
      final regex = pattern['regex'] as RegExp;
      final match = regex.firstMatch(normalized);
      if (match != null) {
        print('DEBUG: [parseUserInput] matched pattern: ${regex.pattern}');
        print('DEBUG: Full match: ${match.group(0)}');
        for (int i = 0; i <= match.groupCount; i++) {
          print('DEBUG: Group $i: ${match.group(i)}');
        }
        final type = pattern['type'] as LogType;
        String? action;
        String? dateTimeStr;
        String? amountStr;
        String? category;
        bool hasTime = true;

        // Handle time-only task pattern
        if (type == LogType.task &&
            match.groupCount >= 8 &&
            match.group(5) != null &&
            match.group(6) != null) {
          // Example: add a task doctor's appointment 6:30 pm
          action = match.group(5)!.trim();
          int hour = int.parse(match.group(6)!);
          int minute = match.group(8) != null ? int.parse(match.group(8)!) : 0;
          final ampm = match.group(9)?.toLowerCase();
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          // Instead of assigning a date, leave dateTime as null to prompt for date
          print('DEBUG: [time-only task] extracted action: "$action"');
          print('DEBUG: [time-only task] extracted time: $hour:$minute $ampm');
          return ParsedLog(
            type: type,
            action: action,
            dateTime: null, // No date assigned
            hasTime: true,
            raw: input,
          );
        }

        switch (type) {
          case LogType.reminder:
          case LogType.task:
            // Check if this is a standalone time input first
            print(
              'DEBUG: Checking standalone time - groupCount: ${match.groupCount}',
            );
            print(
              'DEBUG: Group 1: ${match.group(1)}, Group 3: ${match.group(3)}',
            );

            // Simple check: if the entire input matches the standalone time pattern
            final standaloneTimePattern = RegExp(
              r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
              caseSensitive: false,
            );
            if (standaloneTimePattern.hasMatch(input.toLowerCase())) {
              print('DEBUG: Input matches standalone time pattern');
              final timeMatch = standaloneTimePattern.firstMatch(
                input.toLowerCase(),
              );
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(2)!);
                int minute = timeMatch.group(4) != null
                    ? int.parse(timeMatch.group(4)!)
                    : 0;
                final ampm = timeMatch.group(5);
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                // For standalone time input, don't set a date - let the conversation continuation handle it
                // This prevents overwriting the original date from pending tasks
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: null, // Don't set date for standalone time
                  hasTime: true,
                  raw: input,
                );
              }
            }

            // Check for "for [time]" pattern (common when adding time to existing task/reminder)
            final forTimePattern = RegExp(
              r'^for\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
              caseSensitive: false,
            );
            if (forTimePattern.hasMatch(input.toLowerCase())) {
              print('DEBUG: Input matches "for [time]" pattern');
              final timeMatch = forTimePattern.firstMatch(input.toLowerCase());
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(1)!);
                int minute = timeMatch.group(3) != null
                    ? int.parse(timeMatch.group(3)!)
                    : 0;
                final ampm = timeMatch.group(4);
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                final now = DateTime.now();
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  ),
                  hasTime: true,
                  raw: input,
                );
              }
            }

            if (match.groupCount == 4 &&
                match.group(1) == null &&
                match.group(3) == null) {
              // This is a standalone time input (like "6 pm")
              final timeMatch = RegExp(
                r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
                caseSensitive: false,
              ).firstMatch(input.toLowerCase());
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(2)!);
                int minute = timeMatch.group(4) != null
                    ? int.parse(timeMatch.group(4)!)
                    : 0;
                final ampm = timeMatch.group(5);
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                final now = DateTime.now();
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  ),
                  hasTime: true,
                  raw: input,
                );
              }
            }
            // Check if this is a standalone date input
            final dtResult = parseSimpleDateTimeWithTimeFlag(input);
            if (dtResult.dateTime != null) {
              // Standalone date input: always treat as date, not as action/title
              return ParsedLog(
                type: LogType.reminder, // or LogType.task if merging
                action: null, // <-- always null for date-only
                dateTime: dtResult.dateTime,
                hasTime: dtResult.hasTime,
                raw: input,
              );
            }
            // Check if this is a combined time and date input
            if (match.groupCount >= 6) {
              // This could be a combined time and date input (like "6 pm 15 July")
              print(
                'DEBUG: Detected potential combined time+date input: $input',
              );
              final dtResult = parseSimpleDateTimeWithTimeFlag(input);
              if (dtResult.dateTime != null) {
                print(
                  'DEBUG: Successfully parsed combined time+date: ${dtResult.dateTime}, hasTime: ${dtResult.hasTime}',
                );
                // Extract action/title by removing trigger and date/time from input
                String temp = input;
                // Remove reminder trigger - improved pattern to catch all variations
                temp = temp.replaceFirst(
                  RegExp(
                    r'^(remind me|set reminder|create reminder|reminder|set a reminder|create a reminder|add reminder|new reminder|set up reminder|put reminder|add a reminder|schedule a reminder|set up a reminder|remind me to|remind me about|remind me of)[,\s]*(to|for)?[,\s]*',
                    caseSensitive: false,
                  ),
                  '',
                );

                // Remove task trigger - improved pattern to catch all variations
                temp = temp.replaceFirst(
                  RegExp(
                    r'^(add|create|set|new)\s+(a\s+)?(task|todo|item)(?:\s*(to|for))?[,\s]*',
                    caseSensitive: false,
                  ),
                  '',
                );

                // Remove all date/time patterns from the end
                final dateTimePatterns = [
                  // "7 pm, 15 July" format
                  RegExp(
                    r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s*,\s*(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
                    caseSensitive: false,
                  ),
                  // "15 July, 7 pm" format
                  RegExp(
                    r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*,\s*(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
                    caseSensitive: false,
                  ),
                  // "7 pm 15 July" format
                  RegExp(
                    r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
                    caseSensitive: false,
                  ),
                  // "15 July 7 pm" format
                  RegExp(
                    r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
                    caseSensitive: false,
                  ),
                ];

                bool patternRemoved = false;
                for (final pattern in dateTimePatterns) {
                  if (pattern.hasMatch(temp)) {
                    temp = temp.replaceFirst(pattern, '').trim();
                    patternRemoved = true;
                    break;
                  }
                }

                // Clean up any trailing commas, punctuation, or leading/trailing whitespace
                temp = temp.replaceAll(RegExp(r'[,\s]+$'), '').trim();
                temp = temp.replaceAll(RegExp(r'^[,\s]+'), '').trim();

                // Remove any remaining "to" or "for" at the beginning
                temp = temp.replaceFirst(
                  RegExp(r'^(to|for)\s+', caseSensitive: false),
                  '',
                );

                // Capitalize the action (title case)
                if (temp.isNotEmpty) {
                  temp = temp
                      .split(' ')
                      .map((word) {
                        if (word.isEmpty) return word;
                        return word[0].toUpperCase() +
                            word.substring(1).toLowerCase();
                      })
                      .join(' ');
                }

                print('DEBUG: [combined time+date] extracted action: "$temp"');
                return ParsedLog(
                  type: type,
                  action: temp.isNotEmpty ? temp : null,
                  dateTime: dtResult.dateTime,
                  hasTime: dtResult.hasTime,
                  raw: input,
                );
              }
            }
            // --- Enhanced action extraction logic ---
            if (type == LogType.task) {
              // For tasks, the action is in group 5 (after the trigger and "task" word)
              action = (match.groupCount >= 5 && match.group(5) != null)
                  ? match.group(5)!.trim()
                  : null;
              dateTimeStr = (match.groupCount >= 6 && match.group(6) != null)
                  ? match.group(6)!.trim()
                  : null;

              // --- Always run improved date/time extraction on action ---
              if (action != null) {
                // Extract and remove date words anywhere in the action
                final datePattern = RegExp(
                  r'(the\s*)?(\d{1,2})(st|nd|rd|th)?\s+of\s+\w+|(the\s*)?(\d{1,2})(st|nd|rd|th)?\s+\w+',
                  caseSensitive: false,
                );
                final dateMatch = datePattern.firstMatch(action);
                DateTime? extractedDate;
                if (dateMatch != null) {
                  int day = 0;
                  int month = 0;
                  int year = DateTime.now().year;
                  try {
                    if ((dateMatch.groupCount >= 2 &&
                            dateMatch.group(2) != null) ||
                        (dateMatch.groupCount >= 6 &&
                            dateMatch.group(6) != null)) {
                      day = int.parse(
                        dateMatch.group(2) ?? dateMatch.group(6)!,
                      );
                    }
                    String? monthStr = dateMatch.group(4) ?? dateMatch.group(7);
                    if (monthStr == null) {
                      // Try to extract month from the last word
                      final words = action.split(' ');
                      if (words.isNotEmpty) {
                        monthStr = words.last;
                      }
                    }
                    if (monthStr != null) {
                      final months = [
                        'january',
                        'february',
                        'march',
                        'april',
                        'may',
                        'june',
                        'july',
                        'august',
                        'september',
                        'october',
                        'november',
                        'december',
                        'jan',
                        'feb',
                        'mar',
                        'apr',
                        'may',
                        'jun',
                        'jul',
                        'aug',
                        'sep',
                        'oct',
                        'nov',
                        'dec',
                      ];
                      int idx = months.indexWhere(
                        (m) => m.toLowerCase() == monthStr!.toLowerCase(),
                      );
                      if (idx != -1) {
                        month = (idx % 12) + 1;
                        extractedDate = DateTime(year, month, day);
                      }
                    }
                  } catch (e) {}
                  // Remove the date phrase from the action
                  action = action.replaceFirst(datePattern, '').trim();
                }
                // Remove time words anywhere in the action
                final timePattern = RegExp(
                  r'at\s+\d{1,2}(:\d{2})?\s*(am|pm)?',
                  caseSensitive: false,
                );
                final timeMatch = timePattern.firstMatch(action);
                TimeOfDay? extractedTime;
                if (timeMatch != null) {
                  try {
                    int hour = int.parse(
                      timeMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                    int minute = 0;
                    if (timeMatch.group(1) != null) {
                      minute = int.parse(
                        timeMatch.group(1)!.replaceAll(':', ''),
                      );
                    }
                    final ampm = timeMatch.group(2);
                    if (ampm == 'pm' && hour < 12) hour += 12;
                    if (ampm == 'am' && hour == 12) hour = 0;
                    extractedTime = TimeOfDay(hour: hour, minute: minute);
                  } catch (e) {}
                  action = action.replaceFirst(timePattern, '').trim();
                }
                // Remove any remaining date/time keywords
                final dateTimePatterns = [
                  RegExp(r'\btomorrow\b', caseSensitive: false),
                  RegExp(r'\btoday\b', caseSensitive: false),
                  RegExp(r'\byesterday\b', caseSensitive: false),
                  RegExp(r'\bnext\s+\w+\b', caseSensitive: false),
                  RegExp(r'\bon\s+\w+\b', caseSensitive: false),
                  RegExp(r'\bthis\s+\w+\b', caseSensitive: false),
                  RegExp(
                    r'\bfor\s+\d{1,2}(:\d{2})?\s*(am|pm)?',
                    caseSensitive: false,
                  ),
                  RegExp(
                    r'\b\d{1,2}(st|nd|rd|th)?\s+\w+',
                    caseSensitive: false,
                  ),
                ];
                for (final pattern in dateTimePatterns) {
                  action = action?.replaceAll(pattern, '').trim();
                }
                action = action
                    ?.replaceAll(RegExp(r'^[,\s]+|[,\s]+\u00000'), '')
                    .trim();
                // If we extracted a date/time, return immediately with the cleaned action and date/time
                if (extractedDate != null) {
                  return ParsedLog(
                    type: LogType.task,
                    action: action,
                    dateTime: extractedTime != null
                        ? DateTime(
                            extractedDate.year,
                            extractedDate.month,
                            extractedDate.day,
                            extractedTime.hour,
                            extractedTime.minute,
                          )
                        : extractedDate,
                    hasTime: extractedTime != null,
                    raw: input,
                  );
                }
              }
            } else {
              // For reminders, use the original logic
              action = (match.groupCount >= 3 && match.group(3) != null)
                  ? match.group(3)!.trim()
                  : null;
              dateTimeStr = (match.groupCount >= 4 && match.group(4) != null)
                  ? match.group(4)!.trim()
                  : null;
            }
            // If action is present and dateTimeStr is present at the end of action, remove it
            if (action != null &&
                dateTimeStr != null &&
                action.toLowerCase().endsWith(dateTimeStr.toLowerCase())) {
              action = action
                  .substring(0, action.length - dateTimeStr.length)
                  .trim();
            }
            // If action is just a comma or empty, try to extract from the input minus the trigger and date/time
            if (action == null ||
                action.isEmpty ||
                action == ',' ||
                action == ',') {
              // Remove trigger and date/time from input
              String temp = input;
              // Remove trigger
              temp = temp.replaceFirst(
                RegExp(
                  r'^(remind me|set reminder|create reminder|reminder|set a reminder|create a reminder|add reminder|new reminder|set up reminder|put reminder|add a reminder|schedule a reminder|set up a reminder|remind me to|remind me about|remind me of)[,\s]*',
                  caseSensitive: false,
                ),
                '',
              );
              // Remove date/time at the end
              if (dateTimeStr != null &&
                  temp.toLowerCase().endsWith(dateTimeStr.toLowerCase())) {
                temp = temp
                    .substring(0, temp.length - dateTimeStr.length)
                    .trim();
              }
              action = temp.trim();
            }

            // Clean up action by removing trigger phrases and common fillers
            if (action != null) {
              // Remove trigger phrases from the beginning
              action = action.replaceFirst(
                RegExp(
                  r'^(add|set|create|new|schedule|put|set up|add a|create a|set up a)\s+(reminder|a reminder)?\s*',
                  caseSensitive: false,
                ),
                '',
              );

              // Remove "reminder" word if it appears
              action = action.replaceAll(
                RegExp(r'\breminder\b', caseSensitive: false),
                '',
              );

              // Remove task-specific trigger phrases
              action = action.replaceFirst(
                RegExp(
                  r'^(add|set|create|new|schedule|put|set up|add a|create a|set up a)\s+(task|todo|item|a task|a todo|an item)?\s*',
                  caseSensitive: false,
                ),
                '',
              );

              // Remove "task", "todo", "item" words if they appear
              action = action.replaceAll(
                RegExp(r'\b(task|todo|item)\b', caseSensitive: false),
                '',
              );

              // Remove leading "a" or "an" if it's followed by a space
              action = action.replaceFirst(
                RegExp(r'^(a|an)\s+', caseSensitive: false),
                '',
              );

              // Clean up extra whitespace and punctuation
              action = action.trim().replaceAll(RegExp(r'\s+'), ' ');
            }
            print('DEBUG: Extracted action: $action');
            print('DEBUG: Extracted dateTimeStr: $dateTimeStr');
            // If 'tomorrow' is present anywhere in the input, ensure dateTimeStr includes it
            if (input.toLowerCase().contains('tomorrow')) {
              dateTimeStr =
                  'tomorrow' +
                  (dateTimeStr != null && dateTimeStr.isNotEmpty
                      ? ' ' + dateTimeStr
                      : '');
              print(
                'DEBUG: Overriding dateTimeStr to include "tomorrow": $dateTimeStr',
              );
            }
            // --- New: Post-process action for multi-sentence and filler removal ---
            if (action != null) {
              // 1. If input contains multiple sentences, use the last non-empty, non-date/time sentence as the action
              final sentences = action.split(RegExp(r'[.!?]'));
              String? candidateAction;
              final dateTimeWords = [
                'tomorrow',
                'today',
                'yesterday',
                'tonight',
                'morning',
                'afternoon',
                'evening',
                'at',
                'on',
                'next',
                'am',
                'pm',
              ];
              for (var i = sentences.length - 1; i >= 0; i--) {
                final s = sentences[i].trim();
                // Skip empty or date/time-only sentences
                if (s.isEmpty) continue;
                final isDateTimeOnly = dateTimeWords.any(
                  (w) =>
                      RegExp(
                        '^' + w + r'(\s|$)',
                        caseSensitive: false,
                      ).hasMatch(s) &&
                      s
                          .replaceAll(RegExp(w, caseSensitive: false), '')
                          .trim()
                          .isEmpty,
                );
                if (!isDateTimeOnly) {
                  candidateAction = s;
                  break;
                }
              }
              if (candidateAction != null && candidateAction.isNotEmpty) {
                action = candidateAction;
              }
              // 2. Remove leading filler phrases
              action = action.replaceFirst(
                RegExp(
                  r'^(i need to|i have to|i must|please|can you|could you|would you|i want to|i should|i will|i am going to|i gotta|i got to|i ought to|i wish to|i plan to|i intend to|i would like to)\s+',
                  caseSensitive: false,
                ),
                '',
              );
              // 3. Remove all standalone date/time words (e.g., 'tomorrow', 'at 2 pm', etc.)
              action = action
                  .replaceAll(
                    RegExp(
                      r'\b(tomorrow|today|yesterday|tonight|morning|afternoon|evening|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|am|pm)\b',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
              // 4. Remove any leading/trailing punctuation or whitespace
              action = action.replaceAll(
                RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'),
                '',
              );
            }
            // --- End enhanced action extraction ---
            // Semantic mapping for natural titles
            if (action != null) {
              final actionMappings = {
                RegExp(r'go to the doctor(s)?', caseSensitive: false):
                    "doctor's appointment",
                RegExp(r'go to the dentist', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'car wash', caseSensitive: false): "car wash",
                RegExp(r'meet (a )?friend(s)?', caseSensitive: false):
                    "meet with friends",
                RegExp(r'restaurant|dinner reservation', caseSensitive: false):
                    "restaurant reservation",
                RegExp(r'work meeting|team meeting', caseSensitive: false):
                    "work meeting",
                RegExp(r'buy groceries|grocery shopping', caseSensitive: false):
                    "grocery shopping",
                RegExp(r'call (.+)', caseSensitive: false): (Match m) =>
                    "call ${m.group(1)}",
                RegExp(r'email (.+)', caseSensitive: false): (Match m) =>
                    "email ${m.group(1)}",
                RegExp(r'pay bills?', caseSensitive: false): "pay bills",
                RegExp(r'pick up (kids?|child)', caseSensitive: false):
                    "pick up kids",
                RegExp(r'walk the dog', caseSensitive: false): "walk the dog",
                RegExp(r'take medicine|take pills', caseSensitive: false):
                    "take medicine",
                RegExp(r'birthday( party)?', caseSensitive: false):
                    "birthday party",
                RegExp(r'anniversary( dinner)?', caseSensitive: false):
                    "anniversary",
                RegExp(r'gym|workout|exercise', caseSensitive: false):
                    "gym session",
                RegExp(r'laundry|do laundry', caseSensitive: false): "laundry",
                RegExp(r'clean (house|the house)', caseSensitive: false):
                    "clean house",
                RegExp(r'study( session)?', caseSensitive: false):
                    "study session",
                RegExp(r'submit report|send report', caseSensitive: false):
                    "submit report",
                RegExp(
                  r'renew (insurance|car insurance)',
                  caseSensitive: false,
                ): "renew insurance",
                RegExp(r'pay rent', caseSensitive: false): "pay rent",
                RegExp(r'book (flight|hotel)', caseSensitive: false):
                    "book travel",
                RegExp(r'grocery delivery', caseSensitive: false):
                    "grocery delivery",
                RegExp(r'hair (appointment|cut|haircut)', caseSensitive: false):
                    "hair appointment",
                RegExp(r'vet appointment', caseSensitive: false):
                    "vet appointment",
                RegExp(r'parent(-| )teacher meeting', caseSensitive: false):
                    "parent-teacher meeting",
                RegExp(r'shopping|go shopping', caseSensitive: false):
                    "shopping",
                RegExp(r'movie night|go to the movies', caseSensitive: false):
                    "movie night",
                RegExp(r'pick up (parcel|package)', caseSensitive: false):
                    "pick up parcel",
                RegExp(r'dentist cleaning', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'oil change', caseSensitive: false): "car maintenance",
                RegExp(r'renew passport', caseSensitive: false):
                    "renew passport",
                RegExp(r'pay credit card', caseSensitive: false):
                    "pay credit card",
                RegExp(r'send flowers', caseSensitive: false): "send flowers",
                RegExp(r'volunteer(ing)?', caseSensitive: false):
                    "volunteering",
                RegExp(r'meditation|meditate', caseSensitive: false):
                    "meditation",
                RegExp(r'yoga class', caseSensitive: false): "yoga class",
                RegExp(r'book club', caseSensitive: false): "book club",
                RegExp(r'parent meeting', caseSensitive: false):
                    "parent meeting",
                RegExp(
                  r'soccer practice|football practice',
                  caseSensitive: false,
                ): "soccer practice",
                RegExp(r'piano lesson|music lesson', caseSensitive: false):
                    "music lesson",
                RegExp(r'library visit', caseSensitive: false): "library visit",
                RegExp(r'walk the cat', caseSensitive: false): "walk the cat",
                RegExp(r'feed the (dog|cat|pets?)', caseSensitive: false):
                    "feed pets",
                RegExp(r'change lightbulb', caseSensitive: false):
                    "change lightbulb",
                RegExp(r'water (plants|the plants)', caseSensitive: false):
                    "water plants",
                RegExp(r'charge (phone|laptop|device)', caseSensitive: false):
                    "charge device",
                RegExp(r'backup (phone|computer|device)', caseSensitive: false):
                    "backup device",
                RegExp(r'update (software|app)', caseSensitive: false):
                    "update software",
                RegExp(r'car (mot|inspection)', caseSensitive: false):
                    "car inspection",
                RegExp(r'renew driving license', caseSensitive: false):
                    "renew driving license",
                RegExp(r'pay parking ticket', caseSensitive: false):
                    "pay parking ticket",
                RegExp(r'dentist checkup', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'eye exam|optician appointment', caseSensitive: false):
                    "eye exam",
                RegExp(r'get groceries delivered', caseSensitive: false):
                    "grocery delivery",
                RegExp(r'take out (trash|rubbish)', caseSensitive: false):
                    "take out trash",
                RegExp(r'recycling day', caseSensitive: false): "recycling day",
                RegExp(r'meal prep|meal planning', caseSensitive: false):
                    "meal prep",
                RegExp(r'pack lunch', caseSensitive: false): "pack lunch",
                RegExp(r'school run', caseSensitive: false): "school run",
                RegExp(r'after school club', caseSensitive: false):
                    "after school club",
                RegExp(r'football match|soccer match', caseSensitive: false):
                    "football match",
                RegExp(r'swimming lesson', caseSensitive: false):
                    "swimming lesson",
                RegExp(r'driving lesson', caseSensitive: false):
                    "driving lesson",
                RegExp(
                  r'renew netflix|renew subscription',
                  caseSensitive: false,
                ): "renew subscription",
                RegExp(r'pay council tax', caseSensitive: false):
                    "pay council tax",
                RegExp(r'pay water bill', caseSensitive: false):
                    "pay water bill",
                RegExp(r'pay electricity bill', caseSensitive: false):
                    "pay electricity bill",
                RegExp(r'pay gas bill', caseSensitive: false): "pay gas bill",
                RegExp(r'pay phone bill', caseSensitive: false):
                    "pay phone bill",
                RegExp(r'pay internet bill', caseSensitive: false):
                    "pay internet bill",
                RegExp(r'pay tv license', caseSensitive: false):
                    "pay TV license",
                RegExp(r'pay insurance', caseSensitive: false): "pay insurance",
                RegExp(r'pay mortgage', caseSensitive: false): "pay mortgage",
                RegExp(r'pay loan', caseSensitive: false): "pay loan",
                RegExp(r'pay tuition', caseSensitive: false): "pay tuition",
                RegExp(r'pay childcare', caseSensitive: false): "pay childcare",
                RegExp(r'pay gym membership', caseSensitive: false):
                    "pay gym membership",
                RegExp(r'pay club fees', caseSensitive: false): "pay club fees",
                RegExp(r'pay subscription', caseSensitive: false):
                    "pay subscription",
                // Dynamic patterns
                RegExp(r'meet (with )?(.+)', caseSensitive: false): (Match m) =>
                    "meet ${m.group(2)}",
                RegExp(r'lunch with (.+)', caseSensitive: false): (Match m) =>
                    "lunch with ${m.group(1)}",
                RegExp(r'dinner with (.+)', caseSensitive: false): (Match m) =>
                    "dinner with ${m.group(1)}",
                RegExp(r'coffee with (.+)', caseSensitive: false): (Match m) =>
                    "coffee with ${m.group(1)}",
                RegExp(r'visit (.+)', caseSensitive: false): (Match m) =>
                    "visit ${m.group(1)}",
                RegExp(r'pick up (.+)', caseSensitive: false): (Match m) =>
                    "pick up ${m.group(1)}",
                RegExp(r'drop off (.+)', caseSensitive: false): (Match m) =>
                    "drop off ${m.group(1)}",
                RegExp(r'return (.+)', caseSensitive: false): (Match m) =>
                    "return ${m.group(1)}",
                RegExp(r'send (.+) to (.+)', caseSensitive: false): (Match m) =>
                    "send ${m.group(1)} to ${m.group(2)}",
                RegExp(r'book (.+)', caseSensitive: false): (Match m) =>
                    "book ${m.group(1)}",
                RegExp(r'order (.+)', caseSensitive: false): (Match m) =>
                    "order ${m.group(1)}",
                RegExp(r'collect (.+)', caseSensitive: false): (Match m) =>
                    "collect ${m.group(1)}",
                RegExp(r'deliver (.+)', caseSensitive: false): (Match m) =>
                    "deliver ${m.group(1)}",
                RegExp(r'pay for (.+)', caseSensitive: false): (Match m) =>
                    "pay for ${m.group(1)}",
                RegExp(r'schedule (.+)', caseSensitive: false): (Match m) =>
                    "schedule ${m.group(1)}",
                RegExp(r'attend (.+)', caseSensitive: false): (Match m) =>
                    "attend ${m.group(1)}",
                RegExp(r'rsvp to (.+)', caseSensitive: false): (Match m) =>
                    "RSVP to ${m.group(1)}",
                RegExp(
                  r'remind (.+) to (.+)',
                  caseSensitive: false,
                ): (Match m) =>
                    "remind ${m.group(1)} to ${m.group(2)}",
              };
              for (final entry in actionMappings.entries) {
                final reg = entry.key;
                final val = entry.value;
                final matchMap = reg.firstMatch(action!);
                if (matchMap != null) {
                  action = val is String ? val : (val as Function)(matchMap);
                  print('DEBUG: Semantic mapping applied, new action: $action');
                  break;
                }
              }
            }
            break;
          case LogType.task:
            // Task-specific parsing logic
            action = (match.groupCount >= 5 && match.group(5) != null)
                ? match.group(5)!.trim()
                : null;
            dateTimeStr = (match.groupCount >= 6 && match.group(6) != null)
                ? match.group(6)!.trim()
                : null;

            // If action is present and dateTimeStr is present at the end of action, remove it
            if (action != null &&
                dateTimeStr != null &&
                action.toLowerCase().endsWith(dateTimeStr.toLowerCase())) {
              action = action
                  .substring(0, action.length - dateTimeStr.length)
                  .trim();
            }

            // If action is just a comma or empty, try to extract from the input minus the trigger and date/time
            if (action == null ||
                action.isEmpty ||
                action == ',' ||
                action == ',') {
              // Remove trigger and date/time from input
              String temp = input;
              // Remove trigger
              temp = temp.replaceFirst(
                RegExp(
                  r'^(add|create|set|new) (a )?(task|todo|item)(?:\s*(to|for))?[,\s]*',
                  caseSensitive: false,
                ),
                '',
              );
              // Remove date/time at the end
              if (dateTimeStr != null &&
                  temp.toLowerCase().endsWith(dateTimeStr.toLowerCase())) {
                temp = temp
                    .substring(0, temp.length - dateTimeStr.length)
                    .trim();
              }
              action = temp.trim();
            }

            // Clean up action by removing trigger phrases and common fillers
            if (action != null) {
              // Remove trigger phrases from the beginning
              action = action.replaceFirst(
                RegExp(
                  r'^(add|set|create|new|schedule|put|set up|add a|create a|set up a)\s+(task|todo|item|a task|a todo|an item)?\s*',
                  caseSensitive: false,
                ),
                '',
              );

              // Remove "task", "todo", "item" words if they appear
              action = action.replaceAll(
                RegExp(r'\b(task|todo|item)\b', caseSensitive: false),
                '',
              );

              // Remove leading "a" or "an" if it's followed by a space
              action = action.replaceFirst(
                RegExp(r'^(a|an)\s+', caseSensitive: false),
                '',
              );

              // Clean up extra whitespace and punctuation
              action = action.trim().replaceAll(RegExp(r'\s+'), ' ');
            }

            print('DEBUG: [TASK] Extracted action: $action');
            print('DEBUG: [TASK] Extracted dateTimeStr: $dateTimeStr');

            // If 'tomorrow' is present anywhere in the input, ensure dateTimeStr includes it
            if (input.toLowerCase().contains('tomorrow')) {
              dateTimeStr =
                  'tomorrow' +
                  (dateTimeStr != null && dateTimeStr.isNotEmpty
                      ? ' ' + dateTimeStr
                      : '');
              print(
                'DEBUG: [TASK] Overriding dateTimeStr to include "tomorrow": $dateTimeStr',
              );
            }

            // Post-process action for multi-sentence and filler removal
            if (action != null) {
              // 1. If input contains multiple sentences, use the last non-empty, non-date/time sentence as the action
              final sentences = action.split(RegExp(r'[.!?]'));
              String? candidateAction;
              final dateTimeWords = [
                'tomorrow',
                'today',
                'yesterday',
                'tonight',
                'morning',
                'afternoon',
                'evening',
                'at',
                'on',
                'next',
                'am',
                'pm',
              ];
              for (var i = sentences.length - 1; i >= 0; i--) {
                final s = sentences[i].trim();
                // Skip empty or date/time-only sentences
                if (s.isEmpty) continue;
                final isDateTimeOnly = dateTimeWords.any(
                  (w) =>
                      RegExp(
                        '^' + w + r'(\s|$)',
                        caseSensitive: false,
                      ).hasMatch(s) &&
                      s
                          .replaceAll(RegExp(w, caseSensitive: false), '')
                          .trim()
                          .isEmpty,
                );
                if (!isDateTimeOnly) {
                  candidateAction = s;
                  break;
                }
              }
              if (candidateAction != null && candidateAction.isNotEmpty) {
                action = candidateAction;
              }

              // 2. Remove leading filler phrases
              action = action.replaceFirst(
                RegExp(
                  r'^(i need to|i have to|i must|please|can you|could you|would you|i want to|i should|i will|i am going to|i gotta|i got to|i ought to|i wish to|i plan to|i intend to|i would like to)\s+',
                  caseSensitive: false,
                ),
                '',
              );

              // 3. Remove all standalone date/time words
              action = action
                  .replaceAll(
                    RegExp(
                      r'\b(tomorrow|today|yesterday|tonight|morning|afternoon|evening|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|am|pm)\b',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();

              // 4. Remove any leading/trailing punctuation or whitespace
              action = action.replaceAll(
                RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'),
                '',
              );
            }
            break;
          case LogType.expense:
            amountStr = match.group(2)?.trim();
            category = match.group(3)?.trim();
            break;
          default:
            break;
        }

        // Parse date/time and amount if present
        DateTime? dateTime;
        hasTime = true;
        if (dateTimeStr != null && dateTimeStr.isNotEmpty) {
          final dtResult = parseSimpleDateTimeWithTimeFlag(dateTimeStr);
          dateTime = dtResult.dateTime;
          hasTime = dtResult.hasTime;
          print('DEBUG: Parsed dateTime: $dateTime, hasTime: $hasTime');
        }
        double? amount;
        if (amountStr != null && amountStr.isNotEmpty) {
          amount = double.tryParse(amountStr);
        }

        print(
          'DEBUG: [parseUserInput] returning ParsedLog: type=$type, action=$action, dateTime=$dateTime, hasTime=$hasTime',
        );
        return ParsedLog(
          type: type,
          action: action,
          dateTime: dateTime,
          amount: amount,
          category: category,
          raw: input,
          hasTime: hasTime,
        );
      }
    }

    // Fallback: unknown type
    print('DEBUG: [parseUserInput] no pattern matched, returning unknown');
    return ParsedLog(type: LogType.unknown, raw: input);
  }

  // --- 2. Simple Date/Time Parsing ---
  // Returns both DateTime and a flag indicating if time was present
  static _DateTimeWithFlag parseSimpleDateTimeWithTimeFlag(String input) {
    final now = DateTime.now();
    final lower = input.toLowerCase().trim();

    // Month name lists for all parsing logic
    final monthNames = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final monthShort = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    // Helper to get month index from string
    int _parseMonth(String monthStr) {
      monthStr = monthStr.toLowerCase();
      int idx = monthNames.indexOf(monthStr);
      if (idx != -1) return idx + 1;
      idx = monthShort.indexOf(monthStr);
      if (idx != -1) return idx + 1;
      return 0;
    }

    // --- Robust combined date+time parsing ---
    // Accepts: '6 pm 15th July', '15th July 6 pm', 'July 15 at 6 pm', etc.
    final combinedPatterns = [
      // NEW: "16 July 6pm" format (day month time) - MUST BE FIRST!
      RegExp(
        r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
        caseSensitive: false,
      ),
      // 6 pm 15th July
      RegExp(
        r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
        caseSensitive: false,
      ),
      // 6 pm July 15
      RegExp(
        r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?',
        caseSensitive: false,
      ),
      // 15th July 6 pm
      RegExp(
        r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
        caseSensitive: false,
      ),
      // July 15 6 pm
      RegExp(
        r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?\s+(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
        caseSensitive: false,
      ),
      // NEW: Comma-separated formats like "7 pm, 15 July" or "15 July, 7 pm"
      RegExp(
        r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s*,\s*(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*,\s*(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
        caseSensitive: false,
      ),
    ];
    for (final pattern in combinedPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        int day = 0;
        int month = 0;
        int year = now.year;
        int hour = 0;
        int minute = 0;
        bool hasTime = false;

        // Check if this is the "16 July 6pm" format (day month time) - FIRST PATTERN
        if (pattern.pattern.startsWith(
          '(\\d{1,2})(st|nd|rd|th)?\\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\\s+(\\d{1,2})',
        )) {
          // "16 July 6pm" format
          try {
            if (match.groupCount >= 1 && match.group(1) != null) {
              day = int.parse(match.group(1)!);
            } else {
              return _DateTimeWithFlag(null, false);
            }
          } catch (e) {
            print('DEBUG: Invalid day:  [31m[31m[0m');
            return _DateTimeWithFlag(null, false);
          }
          if (match.groupCount >= 3 && match.group(3) != null) {
            String monthStr = match.group(3)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print('DEBUG: Invalid month parsed: [31m$monthStr -> $month [0m');
              return _DateTimeWithFlag(null, false);
            }
          } else {
            return _DateTimeWithFlag(null, false);
          }
          if (match.groupCount >= 4 && match.group(4) != null) {
            try {
              hour = int.parse(match.group(4)!);
            } catch (e) {
              print('DEBUG: Invalid hour:  [31m${match.group(4)} [0m');
              return _DateTimeWithFlag(null, false);
            }
          }
          minute = (match.groupCount >= 6 && match.group(6) != null)
              ? int.parse(match.group(6)!)
              : 0;
          final ampm = (match.groupCount >= 7) ? match.group(7) : null;
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          hasTime = (match.groupCount >= 4 && match.group(4) != null);
        }
        // Pattern 1: 6 pm 15th July
        else if (pattern.pattern.startsWith('(\\d{1,2}')) {
          try {
            hour = int.parse(match.group(1)!);
          } catch (e) {
            print('DEBUG: Invalid hour:  [31m${match.group(1)} [0m');
            return _DateTimeWithFlag(null, false);
          }
          minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
          final ampm = match.group(4);
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          hasTime = true;
          if (pattern.pattern.contains('january')) {
            // 6 pm 15th July
            try {
              day = int.parse(match.group(5)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(5)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            String monthStr = match.group(7)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }
          } else {
            // 6 pm July 15
            String monthStr = match.group(5)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }

            try {
              day = int.parse(match.group(6)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(6)} [0m');
              return _DateTimeWithFlag(null, false);
            }
          }
        } else if (pattern.pattern.contains(',\\s*(\\d{1,2})')) {
          // NEW: Comma-separated patterns
          if (pattern.pattern.startsWith('(\\d{1,2})(:') &&
              pattern.pattern.contains('am|pm')) {
            // "7 pm, 15 July" format
            try {
              hour = int.parse(match.group(1)!);
            } catch (e) {
              print('DEBUG: Invalid hour:  [31m${match.group(1)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
            final ampm = match.group(4);
            if (ampm == 'pm' && hour < 12) hour += 12;
            if (ampm == 'am' && hour == 12) hour = 0;
            hasTime = true;
            try {
              day = int.parse(match.group(5)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(5)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            String monthStr = match.group(7)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }
          } else {
            // "15 July, 7 pm" format
            try {
              day = int.parse(match.group(1)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(1)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            String monthStr = match.group(3)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }

            try {
              hour = int.parse(match.group(4)!);
            } catch (e) {
              print('DEBUG: Invalid hour:  [31m${match.group(4)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
            final ampm = match.group(7);
            if (ampm == 'pm' && hour < 12) hour += 12;
            if (ampm == 'am' && hour == 12) hour = 0;
            hasTime = true;
          }
        } else {
          // Pattern 3/4: 15th July 6 pm or July 15 6 pm
          if (pattern.pattern.startsWith('(\\d{1,2}')) {
            // "15th July 6 pm" format
            try {
              day = int.parse(match.group(1)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(1)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            String monthStr = match.group(3)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }

            try {
              hour = int.parse(match.group(5)!);
            } catch (e) {
              print('DEBUG: Invalid hour:  [31m${match.group(5)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            minute = match.group(7) != null ? int.parse(match.group(7)!) : 0;
            final ampm = match.group(8);
            if (ampm == 'pm' && hour < 12) hour += 12;
            if (ampm == 'am' && hour == 12) hour = 0;
            hasTime = true;
          } else {
            String monthStr = match.group(1)!.toLowerCase();
            month = _parseMonth(monthStr);
            if (month < 1 || month > 12) {
              print(
                'DEBUG: Invalid month parsed: '
                ' [31m$monthStr -> $month [0m',
              );
              return _DateTimeWithFlag(null, false);
            }

            try {
              day = int.parse(match.group(2)!);
            } catch (e) {
              print('DEBUG: Invalid day:  [31m${match.group(2)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            try {
              hour = int.parse(match.group(5)!);
            } catch (e) {
              print('DEBUG: Invalid hour:  [31m${match.group(5)} [0m');
              return _DateTimeWithFlag(null, false);
            }
            minute = match.group(7) != null ? int.parse(match.group(7)!) : 0;
            final ampm = match.group(8);
            if (ampm == 'pm' && hour < 12) hour += 12;
            if (ampm == 'am' && hour == 12) hour = 0;
            hasTime = true;
          }
        }
        DateTime candidate = DateTime(year, month, day, hour, minute);
        if (candidate.isBefore(now)) {
          // If the date+time is in the past, roll over to next year
          candidate = DateTime(year + 1, month, day, hour, minute);
        }
        return _DateTimeWithFlag(candidate, hasTime);
      }
    }

    // e.g. "tomorrow at 2pm"
    if (lower.contains('tomorrow')) {
      final timeMatch = RegExp(
        r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      int hour = 9;
      int minute = 0;
      bool hasTime = false;
      if (timeMatch != null) {
        try {
          hour = int.parse(timeMatch.group(1)!);
        } catch (e) {
          print('DEBUG: Invalid hour:  [31m${timeMatch.group(1)} [0m');
          return _DateTimeWithFlag(null, false);
        }
        minute = timeMatch.group(3) != null
            ? int.parse(timeMatch.group(3)!)
            : 0;
        final ampm = timeMatch.group(4);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      final tomorrow = now.add(Duration(days: 1));
      return _DateTimeWithFlag(
        DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          hasTime ? hour : 0,
          hasTime ? minute : 0,
        ),
        hasTime,
      );
    }

    // --- New: Month name date parsing ---
    // e.g. "14th July", "July 14", "14 July at 2pm"
    final dayMonthPattern = RegExp(
      r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(?:\s+at\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    final monthDayPattern = RegExp(
      r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?(?:\s+at\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    Match? match = dayMonthPattern.firstMatch(lower);
    if (match != null) {
      int day = 0;
      int month = 0;
      int year = now.year;
      int hour = 0;
      int minute = 0;
      bool hasTime = false;
      try {
        day = int.parse(match.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${match.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      String monthStr = match.group(3)!.toLowerCase();
      month = _parseMonth(monthStr);
      if (month < 1 || month > 12) {
        print(
          'DEBUG: Invalid month parsed: '
          ' [31m$monthStr -> $month [0m',
        );
        return _DateTimeWithFlag(null, false);
      }
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      if (match.group(4) != null) {
        try {
          hour = int.parse(match.group(4)!);
        } catch (e) {
          print('DEBUG: Invalid hour:  [31m${match.group(4)} [0m');
          return _DateTimeWithFlag(null, false);
        }
        minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        final ampm = match.group(7);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      print('DEBUG: Parsed date - day: $day, month: $month, year: $year');
      print('DEBUG: Original input: $input, lower: $lower');
      print('DEBUG: Match groups: ${match.groups([1, 2, 3])}');
      return _DateTimeWithFlag(
        DateTime(year, month, day, hasTime ? hour : 0, hasTime ? minute : 0),
        hasTime,
      );
    }
    match = monthDayPattern.firstMatch(lower);
    if (match != null) {
      int day = 0;
      int month = 0;
      int year = now.year;
      int hour = 0;
      int minute = 0;
      bool hasTime = false;
      String monthStr = match.group(1)!.toLowerCase();
      month = _parseMonth(monthStr);
      if (month < 1 || month > 12) {
        print(
          'DEBUG: Invalid month parsed: '
          ' [31m$monthStr -> $month [0m',
        );
        return _DateTimeWithFlag(null, false);
      }
      try {
        day = int.parse(match.group(2)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${match.group(2)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      if (match.group(4) != null) {
        try {
          hour = int.parse(match.group(4)!);
        } catch (e) {
          print('DEBUG: Invalid hour:  [31m${match.group(4)} [0m');
          return _DateTimeWithFlag(null, false);
        }
        minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        final ampm = match.group(7);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      return _DateTimeWithFlag(
        DateTime(year, month, day, hasTime ? hour : 0, hasTime ? minute : 0),
        hasTime,
      );
    }
    // --- End month name date parsing ---

    // --- New: Combined time and date parsing ---
    // e.g. "6 pm 15 July", "2:30 pm July 15"
    final combinedTimeDatePattern1 = RegExp(
      r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
      caseSensitive: false,
    );
    final combinedTimeDatePattern2 = RegExp(
      r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?',
      caseSensitive: false,
    );
    // NEW: Pattern for "16 july 6pm" format
    final combinedTimeDatePattern3 = RegExp(
      r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    match = combinedTimeDatePattern1.firstMatch(lower);
    if (match != null) {
      int hour = 0;
      int minute = 0;
      int day = 0;
      int month = 0;
      int year = now.year;
      try {
        hour = int.parse(match.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid hour:  [31m${match.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      final ampm = match.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      try {
        day = int.parse(match.group(5)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${match.group(5)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      String monthStr = match.group(7)!.toLowerCase();
      month = _parseMonth(monthStr);
      if (month < 1 || month > 12) {
        print(
          'DEBUG: Invalid month parsed: '
          ' [31m$monthStr -> $month [0m',
        );
        return _DateTimeWithFlag(null, false);
      }
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      return _DateTimeWithFlag(DateTime(year, month, day, hour, minute), true);
    }

    match = combinedTimeDatePattern2.firstMatch(lower);
    if (match != null) {
      int hour = 0;
      int minute = 0;
      int day = 0;
      int month = 0;
      int year = now.year;
      try {
        hour = int.parse(match.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid hour:  [31m${match.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      final ampm = match.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      String monthStr = match.group(5)!.toLowerCase();
      month = _parseMonth(monthStr);
      if (month < 1 || month > 12) {
        print(
          'DEBUG: Invalid month parsed: '
          ' [31m$monthStr -> $month [0m',
        );
        return _DateTimeWithFlag(null, false);
      }
      try {
        day = int.parse(match.group(6)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${match.group(6)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      return _DateTimeWithFlag(DateTime(year, month, day, hour, minute), true);
    }

    // NEW: Handle "16 july 6pm" format
    match = combinedTimeDatePattern3.firstMatch(lower);
    if (match != null) {
      int day = 0;
      int month = 0;
      int hour = 0;
      int minute = 0;
      int year = now.year;
      try {
        day = int.parse(match.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${match.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      String monthStr = match.group(3)!.toLowerCase();
      month = _parseMonth(monthStr);
      if (month < 1 || month > 12) {
        print(
          'DEBUG: Invalid month parsed: '
          ' [31m$monthStr -> $month [0m',
        );
        return _DateTimeWithFlag(null, false);
      }
      try {
        hour = int.parse(match.group(4)!);
      } catch (e) {
        print('DEBUG: Invalid hour:  [31m${match.group(4)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      final ampm = match.group(7);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      return _DateTimeWithFlag(DateTime(year, month, day, hour, minute), true);
    }

    // e.g. "on the 18th", "for 19th"
    final dateMatch = RegExp(r'(\d{1,2})(st|nd|rd|th)?').firstMatch(lower);
    if (dateMatch != null) {
      int day = 0;
      int month = now.month;
      int year = now.year;
      int hour = 0;
      int minute = 0;
      bool hasTime = false;
      try {
        day = int.parse(dateMatch.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid day:  [31m${dateMatch.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      final timeMatch = RegExp(
        r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      if (timeMatch != null) {
        try {
          hour = int.parse(timeMatch.group(1)!);
        } catch (e) {
          print('DEBUG: Invalid hour:  [31m${timeMatch.group(1)} [0m');
          return _DateTimeWithFlag(null, false);
        }
        minute = timeMatch.group(3) != null
            ? int.parse(timeMatch.group(3)!)
            : 0;
        final ampm = timeMatch.group(4);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      return _DateTimeWithFlag(
        DateTime(year, month, day, hasTime ? hour : 0, hasTime ? minute : 0),
        hasTime,
      );
    }

    // e.g. "at 2pm"
    final timeMatch = RegExp(
      r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (timeMatch != null) {
      int hour = 0;
      int minute = 0;
      try {
        hour = int.parse(timeMatch.group(1)!);
      } catch (e) {
        print('DEBUG: Invalid hour:  [31m${timeMatch.group(1)} [0m');
        return _DateTimeWithFlag(null, false);
      }
      minute = timeMatch.group(3) != null ? int.parse(timeMatch.group(3)!) : 0;
      final ampm = timeMatch.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return _DateTimeWithFlag(
        DateTime(now.year, now.month, now.day, hour, minute),
        true,
      );
    }

    // Standalone date pattern: e.g. '1 august'
    final datePattern = RegExp(
      r'^(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$',
      caseSensitive: false,
    );
    final standaloneDateMatch = datePattern.firstMatch(lower);
    if (standaloneDateMatch != null) {
      int day = 0;
      int month = 0;
      int year = now.year;
      try {
        if (standaloneDateMatch.groupCount >= 1 &&
            standaloneDateMatch.group(1) != null) {
          day = int.parse(standaloneDateMatch.group(1)!);
        } else {
          return _DateTimeWithFlag(null, false);
        }
        if (standaloneDateMatch.groupCount >= 3 &&
            standaloneDateMatch.group(3) != null) {
          String monthStr = standaloneDateMatch.group(3)!.toLowerCase();
          month = _parseMonth(monthStr);
          if (month < 1 || month > 12) return _DateTimeWithFlag(null, false);
        } else {
          return _DateTimeWithFlag(null, false);
        }
      } catch (e) {
        return _DateTimeWithFlag(null, false);
      }
      return _DateTimeWithFlag(DateTime(year, month, day), false);
    }

    // If no recognizable date/time, return null (do not default to today)
    return _DateTimeWithFlag(null, false);
  }
}

class _DateTimeWithFlag {
  final DateTime? dateTime;
  final bool hasTime;
  _DateTimeWithFlag(this.dateTime, this.hasTime);
}

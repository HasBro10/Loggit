import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/favorite_feature.dart';
import '../../models/log_entry.dart';
import '../../services/ai_service.dart';
import '../../services/favorites_service.dart';
import '../../services/reminders_service.dart';
import '../../services/tasks_service.dart';
// import '../../services/log_parser_service.dart'; // DISCONNECTED: Keeping for future Phase 5 implementation
import '../../shared/design/color_guide.dart';
import '../../shared/design/fonts.dart';
import '../../shared/design/spacing.dart';
import '../../shared/design/widgets/feature_card_button.dart';
import '../../shared/design/widgets/header.dart';
import '../../shared/design/widgets/pill_button.dart';
import '../../shared/design/widgets/rounded_text_input.dart';
import '../../shared/design/widgets/status_card.dart';
import '../../shared/utils/responsive.dart';
import '../expenses/expense_model.dart';
import '../gym/gym_log_model.dart';
import '../notes/note_model.dart';
import '../../services/notes_service.dart';
import '../reminders/reminder_edit_modal.dart';
import '../reminders/reminder_model.dart';
import '../tasks/task_model.dart' hide RecurrenceType;
import '../tasks/task_model.dart' as task_model show RecurrenceType;
import '../tasks/tasks_screen_new.dart';
import 'chat_message.dart';

class ChatScreenNew extends StatefulWidget {
  final void Function(Expense)? onExpenseLogged;
  final void Function(Task)? onTaskLogged;
  final void Function(Reminder)? onReminderLogged;
  final List<Task> Function()? getTasks;
  final void Function(Note)? onNoteLogged;
  final void Function(GymLog)? onGymLogLogged;
  final void Function()? onShowTasks;
  final void Function()? onShowReminders;
  final void Function()? onShowNotes;
  final VoidCallback? onShowGym;
  final VoidCallback? onThemeToggle;
  final ThemeMode currentThemeMode;

  const ChatScreenNew({
    super.key,
    this.onExpenseLogged,
    this.onTaskLogged,
    this.onReminderLogged,
    this.getTasks,
    this.onNoteLogged,
    this.onGymLogLogged,
    this.onShowTasks,
    this.onShowReminders,
    this.onShowNotes,
    this.onShowGym,
    this.onThemeToggle,
    required this.currentThemeMode,
  });

  @override
  State<ChatScreenNew> createState() => _ChatScreenNewState();
}

class _ChatScreenNewState extends State<ChatScreenNew>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController(
    text: 'John Doe',
  );
  final List<_ChatMessage> _messages = [];
  LogEntry? _pendingLog;
  final ScrollController _scrollController = ScrollController();
  late BuildContext _rootContext;

  // Animated typing effect for actions
  final List<String> _actions = [
    'log an expense',
    'set a reminder',
    'save a note',
    'record a workout',
  ];
  int _actionIndex = 0;
  int _charIndex = 0;
  bool _isTyping = true;
  String _currentTyped = '';
  Timer? _typingTimer;
  Timer? _pauseTimer;
  final FocusNode _focusNode = FocusNode();
  bool _isInputFocused = false;
  bool _isLoading = false; // Add loading state

  // Add a variable to hold the current editing/creating task's timestamp
  DateTime? _currentTaskTimestamp;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _startTyping();
    // Ensure demo name is set
    _profileNameController.text = 'John Doe';
  }

  void _startTyping() {
    _isTyping = true;
    _typingTimer?.cancel();
    _pauseTimer?.cancel();
    _charIndex = 0;
    _currentTyped = '';
    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_charIndex < _actions[_actionIndex].length) {
        setState(() {
          _currentTyped += _actions[_actionIndex][_charIndex];
          _charIndex++;
        });
      } else {
        _typingTimer?.cancel();
        _pauseTimer = Timer(const Duration(seconds: 2), () {
          _startErasing();
        });
      }
    });
  }

  void _startErasing() {
    _isTyping = false;
    _typingTimer?.cancel();
    _pauseTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_currentTyped.isNotEmpty) {
        setState(() {
          _currentTyped = _currentTyped.substring(0, _currentTyped.length - 1);
        });
      } else {
        _typingTimer?.cancel();
        _actionIndex = (_actionIndex + 1) % _actions.length;
        _pauseTimer = Timer(const Duration(milliseconds: 800), () {
          _startTyping();
        });
      }
    });
  }

  void _handleFocusChange() {
    setState(() {
      _isInputFocused = _focusNode.hasFocus;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (reminderDate == today) {
      dateStr = 'Today';
    } else if (reminderDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  int? _getWeekdayFromName(String dayName) {
    final weekdays = {
      'monday': 1,
      'mon': 1,
      'tuesday': 2,
      'tue': 2,
      'wednesday': 3,
      'wed': 3,
      'thursday': 4,
      'thu': 4,
      'friday': 5,
      'fri': 5,
      'saturday': 6,
      'sat': 6,
      'sunday': 7,
      'sun': 7,
    };
    return weekdays[dayName.toLowerCase()];
  }

  // Helper method to extract time from various message formats (including typos)
  TimeOfDay? _extractTimeFromMessage(String message) {
    final cleanMessage = message.toLowerCase().trim();
    print('DEBUG: _extractTimeFromMessage - input: "$cleanMessage"');

    // Try various time formats
    // 1. Standard format: "9am", "9 am", "9:30am", "9:30 am"
    final standardMatch = RegExp(
      r'^(\d{1,2})(:(\d{2}))?\s*(am|pm)$',
      caseSensitive: false,
    ).firstMatch(cleanMessage);

    if (standardMatch != null) {
      int hour = int.parse(standardMatch.group(1)!);
      int minute = standardMatch.group(3) != null
          ? int.parse(standardMatch.group(3)!)
          : 0;
      final ampm = standardMatch.group(4)?.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      print('DEBUG: _extractTimeFromMessage - standard match: $hour:$minute');
      return TimeOfDay(hour: hour, minute: minute);
    }

    // 2. Simple format: "530", "5:30" (assume PM)
    final simpleMatch = RegExp(
      r'^(\d{1,2})(:(\d{2}))?$',
    ).firstMatch(cleanMessage);
    if (simpleMatch != null) {
      int hour = int.parse(simpleMatch.group(1)!);
      int minute = simpleMatch.group(3) != null
          ? int.parse(simpleMatch.group(3)!)
          : 0;
      if (hour < 12) hour += 12; // Assume PM
      print('DEBUG: _extractTimeFromMessage - simple match: $hour:$minute');
      return TimeOfDay(hour: hour, minute: minute);
    }

    // 3. Handle typos like "p a.m." (with spaces and dots)
    final typoMatch = RegExp(
      r'^(\d{1,2})\s*(a\.?m\.?|p\.?m\.?)$',
      caseSensitive: false,
    ).firstMatch(cleanMessage);

    if (typoMatch != null) {
      int hour = int.parse(typoMatch.group(1)!);
      final ampm = typoMatch.group(2)?.toLowerCase().replaceAll('.', '');
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      print('DEBUG: _extractTimeFromMessage - typo match: $hour:0');
      return TimeOfDay(hour: hour, minute: 0);
    }

    // 4. Handle more typos like "9a.m.", "9p.m." (no spaces)
    final noSpaceTypoMatch = RegExp(
      r'^(\d{1,2})(a\.?m\.?|p\.?m\.?)$',
      caseSensitive: false,
    ).firstMatch(cleanMessage);

    if (noSpaceTypoMatch != null) {
      int hour = int.parse(noSpaceTypoMatch.group(1)!);
      final ampm = noSpaceTypoMatch.group(2)?.toLowerCase().replaceAll('.', '');
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      print('DEBUG: _extractTimeFromMessage - no space typo match: $hour:0');
      return TimeOfDay(hour: hour, minute: 0);
    }

    // 5. Handle very short inputs that might be typos
    if (cleanMessage.length <= 4 && RegExp(r'^\d+$').hasMatch(cleanMessage)) {
      int hour = int.parse(cleanMessage);
      if (hour >= 1 && hour <= 12) {
        // Assume PM for single digit hours
        if (hour < 12) hour += 12;
        print('DEBUG: _extractTimeFromMessage - short number match: $hour:0');
        return TimeOfDay(hour: hour, minute: 0);
      }
    }

    print('DEBUG: _extractTimeFromMessage - no match found');
    return null;
  }

  // Helper method to parse common time-related queries when AI fails
  Map<String, dynamic>? _parseTimeQueryFallback(String message) {
    final cleanMessage = message.toLowerCase().trim();
    print('DEBUG: _parseTimeQueryFallback - input: "$message"');
    print('DEBUG: _parseTimeQueryFallback - cleanMessage: "$cleanMessage"');

    // Check for view reminders queries
    if (cleanMessage.contains('reminder') ||
        cleanMessage.contains('reminders')) {
      print('DEBUG: _parseTimeQueryFallback - detected reminders query');

      if (cleanMessage.contains('this week') || cleanMessage.contains('week')) {
        print('DEBUG: _parseTimeQueryFallback - matched "this week"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'this week'},
        };
      } else if (cleanMessage.contains('next week') ||
          cleanMessage.contains('following week') ||
          cleanMessage.contains('upcoming week')) {
        print('DEBUG: _parseTimeQueryFallback - matched "next week"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'next week'},
        };
      } else if (cleanMessage.contains('this month') ||
          cleanMessage.contains('current month') ||
          cleanMessage.contains('month')) {
        print('DEBUG: _parseTimeQueryFallback - matched "this month"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'this month'},
        };
      } else if (cleanMessage.contains('next month') ||
          cleanMessage.contains('following month') ||
          cleanMessage.contains('upcoming month')) {
        print('DEBUG: _parseTimeQueryFallback - matched "next month"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'next month'},
        };
      } else if (cleanMessage.contains('today')) {
        print('DEBUG: _parseTimeQueryFallback - matched "today"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'today'},
        };
      } else if (cleanMessage.contains('tomorrow') ||
          cleanMessage.contains("tomorrow's") ||
          cleanMessage.contains('for tomorrow')) {
        print('DEBUG: _parseTimeQueryFallback - matched "tomorrow"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'tomorrow'},
        };
      } else if (cleanMessage.contains('all')) {
        print('DEBUG: _parseTimeQueryFallback - matched "all"');
        return {
          'intent': 'view_reminders',
          'fields': {'timeframe': 'all'},
        };
      }
    }

    // Check for view tasks queries
    if (cleanMessage.contains('task') || cleanMessage.contains('tasks')) {
      print('DEBUG: _parseTimeQueryFallback - detected tasks query');

      if (cleanMessage.contains('this week') || cleanMessage.contains('week')) {
        print('DEBUG: _parseTimeQueryFallback - matched "this week"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'this week'},
        };
      } else if (cleanMessage.contains('next week') ||
          cleanMessage.contains('following week') ||
          cleanMessage.contains('upcoming week')) {
        print('DEBUG: _parseTimeQueryFallback - matched "next week"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'next week'},
        };
      } else if (cleanMessage.contains('this month') ||
          cleanMessage.contains('current month') ||
          cleanMessage.contains('month')) {
        print('DEBUG: _parseTimeQueryFallback - matched "this month"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'this month'},
        };
      } else if (cleanMessage.contains('next month') ||
          cleanMessage.contains('following month') ||
          cleanMessage.contains('upcoming month')) {
        print('DEBUG: _parseTimeQueryFallback - matched "next month"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'next month'},
        };
      } else if (cleanMessage.contains('today')) {
        print('DEBUG: _parseTimeQueryFallback - matched "today"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'today'},
        };
      } else if (cleanMessage.contains('tomorrow') ||
          cleanMessage.contains("tomorrow's") ||
          cleanMessage.contains('for tomorrow')) {
        print('DEBUG: _parseTimeQueryFallback - matched "tomorrow"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'tomorrow'},
        };
      } else if (cleanMessage.contains('all')) {
        print('DEBUG: _parseTimeQueryFallback - matched "all"');
        return {
          'intent': 'view_tasks',
          'fields': {'timeframe': 'all'},
        };
      }
    }

    print('DEBUG: _parseTimeQueryFallback - no match found');
    return null;
  }

  String _capitalizeTitle(String title) {
    if (title.isEmpty) return title;

    // Split by spaces and capitalize first letter of each word
    final words = title.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return capitalizedWords.join(' ');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _messages.isNotEmpty &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Clear text field immediately
      _messageController.clear();

      setState(() {
        _messages.add(
          _ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
        );
        _isLoading = true; // Start loading
        // Add loading message in the same setState
        _messages.add(
          _ChatMessage(
            text: "🤖 Processing...",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();

      // --- NEW: Use AIService to process the message and extract fields ---
      try {
        // Add timeout to prevent hanging
        final result = await AIService.processUserMessage(message).timeout(
          const Duration(seconds: 15), // 15 second timeout
          onTimeout: () {
            print('DEBUG: AI service timeout after 15 seconds');
            return {'error': 'timeout'};
          },
        );

        // Debug: Print the raw AI response
        print('DEBUG: Raw AI response for message "$message": $result');

        // Check if AI returned an error or invalid response
        if (result.containsKey('error')) {
          print('DEBUG: AI returned error: ${result['error']}');

          // Try fallback parsing for common time queries
          final fallbackResult = _parseTimeQueryFallback(message);
          if (fallbackResult != null) {
            print('DEBUG: Using fallback parser result: $fallbackResult');
            // Process the fallback result as if it came from AI
            final intent = fallbackResult['intent'];
            final fields = fallbackResult['fields'] as Map<String, dynamic>;

            // Handle the fallback result
            if (intent == 'view_reminders') {
              await _handleReminderQuery(fields['timeframe']);
            } else if (intent == 'view_tasks') {
              await _handleTaskQuery(fields['timeframe']);
            }
            return;
          }

          // --- NEW: Focused Conversation Logic for Errors ---
          // Check if there's a pending confirmation when AI returns an error
          if (_pendingLog != null && _hasPendingConfirmation()) {
            print(
              'DEBUG: Focused conversation check for error - pending log: ${_pendingLog?.logType}',
            );
            print(
              'DEBUG: Focused conversation check for error - AI error: ${result['error']}',
            );

            setState(() {
              // Remove loading message
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }

              // Convert previous confirmation messages to regular messages (remove buttons)
              for (int i = 0; i < _messages.length; i++) {
                if (_messages[i].isConfirmation &&
                    _messages[i].pendingLogEntry != null) {
                  // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                  _messages[i] = _ChatMessage(
                    text: _messages[i].text,
                    isUser: false,
                    timestamp: _messages[i].timestamp,
                    isConfirmation: false, // This removes the buttons
                  );
                }
              }

              // Show focused reminder message with confirmation buttons instead of error
              String reminderMessage = _getFocusedReminderMessage();
              _messages.add(
                _ChatMessage(
                  text: reminderMessage,
                  isUser: false,
                  timestamp: DateTime.now(),
                  isConfirmation: true,
                  onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                      _handleLogConfirmation(confirmed, updatedLogEntry),
                  pendingLogEntry: _pendingLog,
                  canConfirm: _hasRequiredFields(_pendingLog!),
                  showEdit: true,
                ),
              );
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }

          // If no fallback worked, show helpful error message
          setState(() {
            // Remove loading message
            if (_messages.isNotEmpty &&
                _messages.last.text == "🤖 Processing...") {
              _messages.removeLast();
            }

            String errorMessage = _getHelpfulErrorMessage(
              result['error'],
              message,
            );

            _messages.add(
              _ChatMessage(
                text: errorMessage,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }

        if (result.containsKey('intent') && result.containsKey('fields')) {
          final intent = result['intent'];
          final fields = result['fields'] as Map<String, dynamic>;

          // --- NEW: Focused Conversation Logic ---
          // Check if there's a pending confirmation and the new message is not related
          if (_pendingLog != null && _hasPendingConfirmation()) {
            print(
              'DEBUG: Focused conversation check - pending log: ${_pendingLog?.logType}',
            );
            print('DEBUG: Focused conversation check - new intent: $intent');

            // Check if the new intent is NOT related to the current pending confirmation
            // Block any intent that's not a continuation or general query
            bool shouldBlock = false;

            // Block creation intents
            if (intent == 'create_task' ||
                intent == 'create_reminder' ||
                intent == 'create_note' ||
                intent == 'log_expense' ||
                intent == 'log_gym' ||
                intent == 'set_reminder') {
              shouldBlock = true;
            }

            // Also block any other intents that aren't continuation-related
            // Allow only: continue_conversation, view_tasks, view_reminders, general queries
            if (!shouldBlock &&
                intent != 'continue_conversation' &&
                intent != 'view_tasks' &&
                intent != 'view_reminders' &&
                !intent.startsWith('view_')) {
              shouldBlock = true;
            }

            if (shouldBlock) {
              print('DEBUG: Blocking new intent due to pending confirmation');
              // User is trying to create something new while we have a pending confirmation
              setState(() {
                // Remove loading message
                if (_messages.isNotEmpty &&
                    _messages.last.text == "🤖 Processing...") {
                  _messages.removeLast();
                }

                // Convert previous confirmation messages to regular messages (remove buttons)
                for (int i = 0; i < _messages.length; i++) {
                  if (_messages[i].isConfirmation &&
                      _messages[i].pendingLogEntry != null) {
                    // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                    _messages[i] = _ChatMessage(
                      text: _messages[i].text,
                      isUser: false,
                      timestamp: _messages[i].timestamp,
                      isConfirmation: false, // This removes the buttons
                    );
                  }
                }

                // Show focused reminder message with confirmation buttons
                String reminderMessage = _getFocusedReminderMessage();
                _messages.add(
                  _ChatMessage(
                    text: reminderMessage,
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: _pendingLog,
                    canConfirm: _hasRequiredFields(_pendingLog!),
                    showEdit: true,
                  ),
                );
                _isLoading = false;
              });
              _scrollToBottom();
              return;
            }
          }

          // --- NEW: AI Conversation continuation ---
          // If we have a pending log entry, try to merge AI response with it
          if (_pendingLog != null) {
            print(
              'DEBUG: AI Conversation continuation - merging with pending log',
            );

            // Check if this looks like a description addition to the pending item
            bool isDescriptionAddition = _isLikelyDescriptionAddition(
              message,
              intent,
              fields,
            );
            if (isDescriptionAddition) {
              print('DEBUG: Detected description addition to pending item');
              _addDescriptionToPendingItem(message);
              return;
            }

            // If we have a pending task and AI returns task or reminder intent, treat it as task continuation
            if (_pendingLog is Task &&
                (intent == 'create_task' ||
                    intent == 'set_reminder' ||
                    intent == 'create_reminder')) {
              final pending = _pendingLog as Task;

              // Keep the original title unless a meaningful new title is provided
              // If AI returns generic titles like "reminder", "task", etc., keep the original title
              String title = pending.title;
              if (fields['title'] != null &&
                  fields['title'].toString().isNotEmpty) {
                final aiTitle = fields['title'].toString().toLowerCase();
                // Only use AI title if it's not a generic placeholder
                if (aiTitle != 'reminder' &&
                    aiTitle != 'task' &&
                    aiTitle != 'reminder' &&
                    aiTitle.length > 3) {
                  // Avoid very short generic titles
                  title = _capitalizeTitle(fields['title']);
                }
              }

              final description = fields['description'] ?? '';

              // Parse AI's date and time
              DateTime? dueDate = pending.dueDate;
              TimeOfDay? timeOfDay = pending.timeOfDay;

              print('DEBUG: Original pending dueDate: $dueDate');
              print('DEBUG: Original pending timeOfDay: $timeOfDay');

              // Handle both dueDate and reminderTime fields (AI might use either)
              String? dateField = fields['dueDate'] ?? fields['reminderDate'];
              String? timeField =
                  fields['timeOfDay'] ??
                  fields['time'] ??
                  fields['reminderTime'];

              print('DEBUG: AI dateField: $dateField');
              print('DEBUG: AI timeField: $timeField');

              // Only process date field if it's actually a date (not a time)
              // IMPORTANT: If only time is provided, preserve the original date from pending task
              if (dateField != null) {
                final now = DateTime.now();
                final dateStr = dateField.toLowerCase();

                // Check if this is just a time input (like "today 09:00") - if so, preserve original date
                if (dateStr.contains('today') && timeField != null) {
                  // This is likely just a time input, preserve the original date
                  dueDate = pending.dueDate;
                  print(
                    'DEBUG: Preserving original date for time-only input: $dueDate',
                  );
                } else if (dateStr == 'tomorrow') {
                  // Set only the date part, not the time
                  dueDate = DateTime(now.year, now.month, now.day + 1);
                } else if (dateStr == 'today') {
                  // Set only the date part, not the time
                  dueDate = DateTime(now.year, now.month, now.day);
                } else if (dateStr.startsWith('next ')) {
                  final dayName = dateStr.substring(5);
                  final targetWeekday = _getWeekdayFromName(dayName);
                  if (targetWeekday != null) {
                    final daysUntilTarget =
                        (targetWeekday - now.weekday + 7) % 7;
                    // Set only the date part, not the time
                    dueDate = DateTime(
                      now.year,
                      now.month,
                      now.day + daysUntilTarget,
                    );
                  }
                } else if (dateStr.startsWith('the ')) {
                  final dayMatch = RegExp(
                    r'the (\d{1,2})(st|nd|rd|th)?',
                  ).firstMatch(dateStr);
                  if (dayMatch != null) {
                    final day = int.parse(dayMatch.group(1)!);
                    final currentMonth = now.month;
                    final currentYear = now.year;
                    var testDate = DateTime(currentYear, currentMonth, day);
                    if (testDate.isBefore(now)) {
                      testDate = DateTime(currentYear, currentMonth + 1, day);
                    }
                    dueDate = testDate;
                  }
                } else {
                  dueDate = DateTime.tryParse(dateField);
                }
              }

              if (timeField != null) {
                print('DEBUG: Processing time field: "$timeField"');

                // Handle "today 19:00" format by extracting just the time part
                String timeStr = timeField;
                if (timeField.contains(' ')) {
                  final parts = timeField.split(' ');
                  if (parts.length >= 2) {
                    timeStr = parts.last; // Get the last part (the time)
                  }
                }

                final timeMatch = RegExp(
                  r'^(\d{1,2})(?::(\d{2}))?',
                ).firstMatch(timeStr);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = timeMatch.group(2) != null
                      ? int.parse(timeMatch.group(2)!)
                      : 0;
                  timeOfDay = TimeOfDay(hour: hour, minute: minute);
                  print(
                    'DEBUG: Extracted time: ${timeOfDay.hour}:${timeOfDay.minute}',
                  );
                }
              }

              TaskPriority priorityEnum = TaskPriority.medium;
              if (fields['priority'] is String &&
                  fields['priority'].isNotEmpty) {
                final p = fields['priority'].toString().toLowerCase();
                if (p == 'low') {
                  priorityEnum = TaskPriority.low;
                } else if (p == 'high')
                  priorityEnum = TaskPriority.high;
                else if (p == 'medium')
                  priorityEnum = TaskPriority.medium;
              }

              // Set default category to Personal if not specified (matching dropdown options)
              String category = pending.category ?? 'Personal';
              if (fields['category'] is String &&
                  fields['category'].isNotEmpty) {
                category = fields['category'].toString().toLowerCase();
                // Capitalize first letter to match dropdown options
                category = category[0].toUpperCase() + category.substring(1);
              }

              final updatedTask = Task(
                title: title,
                description: description,
                category: category,
                priority: priorityEnum,
                dueDate: dueDate,
                timeOfDay: timeOfDay,
                timestamp: DateTime.now(),
              );

              setState(() {
                _pendingLog = updatedTask;
                // Remove loading message if it exists
                if (_messages.isNotEmpty &&
                    _messages.last.text == "🤖 Processing...") {
                  _messages.removeLast();
                }

                // Convert previous task confirmation messages to regular messages (remove buttons but keep text)
                for (int i = 0; i < _messages.length; i++) {
                  if (_messages[i].isConfirmation &&
                      _messages[i].pendingLogEntry?.logType == 'task') {
                    // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                    _messages[i] = _ChatMessage(
                      text: _messages[i].text,
                      isUser: false,
                      timestamp: _messages[i].timestamp,
                      isConfirmation: false, // This removes the buttons
                    );
                  }
                }

                _messages.add(
                  _ChatMessage(
                    text: _getConfirmationMessage(updatedTask),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: updatedTask,
                    canConfirm: _hasRequiredFields(updatedTask),
                    showEdit: true,
                  ),
                );
                _isLoading = false; // Stop loading
              });
              _scrollToBottom();
              return;
            }
          }

          // Handle reminder conversation continuation
          if (_pendingLog is Reminder &&
              (intent == 'create_reminder' || intent == 'set_reminder')) {
            final pending = _pendingLog as Reminder;

            // Keep the original title unless a meaningful new title is provided
            String title = pending.title;
            if (fields['title'] != null &&
                fields['title'].toString().isNotEmpty) {
              final aiTitle = fields['title'].toString().toLowerCase();
              // Only use AI title if it's not a generic placeholder
              if (aiTitle != 'reminder' &&
                  aiTitle != 'task' &&
                  aiTitle.length > 3) {
                title = _capitalizeTitle(fields['title']);
              }
            }

            // Parse AI's date and time
            DateTime? reminderDate = pending.reminderTime;
            TimeOfDay? reminderTime = TimeOfDay.fromDateTime(
              pending.reminderTime,
            );

            print('DEBUG: Original pending reminderTime: $reminderDate');
            print('DEBUG: Original pending reminderTime: $reminderTime');

            // Handle reminder date and time fields
            String? dateField = fields['reminderDate'] ?? fields['dueDate'];
            String? timeField = fields['reminderTime'] ?? fields['time'];

            print('DEBUG: AI reminder dateField: $dateField');
            print('DEBUG: AI reminder timeField: $timeField');

            // Only process date field if it's actually a date (not a time)
            if (dateField != null) {
              final now = DateTime.now();
              final dateStr = dateField.toLowerCase();

              if (dateStr == 'tomorrow') {
                reminderDate = DateTime(now.year, now.month, now.day + 1);
              } else if (dateStr == 'today') {
                reminderDate = DateTime(now.year, now.month, now.day);
              } else {
                reminderDate = DateTime.tryParse(dateField);
              }
            }

            if (timeField != null) {
              print('DEBUG: Processing reminder time field: "$timeField"');

              // Handle "today 14:00" format by extracting just the time part
              String timeStr = timeField;
              if (timeField.contains(' ')) {
                final parts = timeField.split(' ');
                if (parts.length >= 2) {
                  timeStr = parts.last; // Get the last part (the time)
                }
              }

              final timeMatch = RegExp(
                r'^(\d{1,2})(?::(\d{2}))?',
              ).firstMatch(timeStr);
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(1)!);
                int minute = timeMatch.group(2) != null
                    ? int.parse(timeMatch.group(2)!)
                    : 0;
                reminderTime = TimeOfDay(hour: hour, minute: minute);
                print(
                  'DEBUG: Extracted reminder time: ${reminderTime.hour}:${reminderTime.minute}',
                );
              }
            }

            // Combine date and time into a single DateTime for reminderTime
            DateTime finalReminderTime = reminderDate ?? pending.reminderTime;
            finalReminderTime = DateTime(
              finalReminderTime.year,
              finalReminderTime.month,
              finalReminderTime.day,
              reminderTime.hour,
              reminderTime.minute,
            );

            // Handle repeat functionality
            RecurrenceType recurrenceType = RecurrenceType.none;
            List<int>? customDays;
            int? interval;
            DateTime? endDate;

            if (fields['repeatType'] != null) {
              final repeatType = fields['repeatType'] as String;
              switch (repeatType) {
                case 'daily':
                  recurrenceType = RecurrenceType.daily;
                  break;
                case 'weekly':
                  recurrenceType = RecurrenceType.weekly;
                  break;
                case 'monthly':
                  recurrenceType = RecurrenceType.monthly;
                  break;
                case 'everyNDays':
                  recurrenceType = RecurrenceType.everyNDays;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNWeeks':
                  recurrenceType = RecurrenceType.everyNWeeks;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNMonths':
                  recurrenceType = RecurrenceType.everyNMonths;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'custom':
                  recurrenceType = RecurrenceType.custom;
                  if (fields['repeatDays'] != null) {
                    customDays = List<int>.from(fields['repeatDays']);
                  }
                  break;
              }

              // Handle end date
              if (fields['repeatEndDate'] != null) {
                final endDateStr = fields['repeatEndDate'] as String;
                endDate = DateTime.tryParse(endDateStr);
              }
            }

            final reminder = Reminder(
              title: title,
              description: pending.description,
              reminderTime: finalReminderTime,
              timestamp: DateTime.now(),
              advanceTiming:
                  fields['reminderAdvance'] != null &&
                      (fields['reminderAdvance'] as String).isNotEmpty
                  ? fields['reminderAdvance'] as String
                  : null,
              recurrenceType: recurrenceType,
              customDays: customDays,
              interval: interval,
              endDate: endDate,
            );

            setState(() {
              _pendingLog = reminder;
              // Remove loading message if it exists
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }

              // Convert previous reminder confirmation messages to regular messages (remove buttons but keep text)
              for (int i = 0; i < _messages.length; i++) {
                if (_messages[i].isConfirmation &&
                    _messages[i].pendingLogEntry?.logType == 'reminder') {
                  // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                  _messages[i] = _ChatMessage(
                    text: _messages[i].text,
                    isUser: false,
                    timestamp: _messages[i].timestamp,
                    isConfirmation: false, // This removes the buttons
                  );
                }
              }

              _messages.add(
                _ChatMessage(
                  text: _getConfirmationMessage(reminder),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isConfirmation: true,
                  onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                      _handleLogConfirmation(confirmed, updatedLogEntry),
                  pendingLogEntry: reminder,
                  canConfirm: true,
                  showEdit: true,
                ),
              );
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          }

          // --- Handle continue_conversation intent ---
          if (intent == 'continue_conversation' && _pendingLog != null) {
            print('DEBUG: Continue conversation intent detected');

            // Try to extract time from the message
            TimeOfDay? extractedTime = _extractTimeFromMessage(message);
            print(
              'DEBUG: Continue conversation - extracted time: $extractedTime',
            );

            if (_pendingLog is Task) {
              final pending = _pendingLog as Task;
              if (extractedTime != null && pending.dueDate != null) {
                // Update task with extracted time
                final updatedTask = Task(
                  id: pending.id,
                  title: pending.title,
                  dueDate: pending.dueDate,
                  timeOfDay: extractedTime,
                  timestamp: DateTime.now(),
                );

                setState(() {
                  _pendingLog = updatedTask;
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Convert previous task confirmation messages to regular messages
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i].isConfirmation &&
                        _messages[i].pendingLogEntry?.logType == 'task') {
                      _messages[i] = _ChatMessage(
                        text: _messages[i].text,
                        isUser: false,
                        timestamp: _messages[i].timestamp,
                        isConfirmation: false,
                      );
                    }
                  }

                  _messages.add(
                    _ChatMessage(
                      text: _getConfirmationMessage(updatedTask),
                      isUser: false,
                      timestamp: DateTime.now(),
                      isConfirmation: true,
                      onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                          _handleLogConfirmation(confirmed, updatedLogEntry),
                      pendingLogEntry: updatedTask,
                      canConfirm: _hasRequiredFields(updatedTask),
                      showEdit: true,
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              } else {
                // No time extracted or no due date - just continue the conversation
                setState(() {
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Add a helpful message to continue the conversation
                  _messages.add(
                    _ChatMessage(
                      text:
                          "⏰ I didn't understand that time format. Please try again with a time like '9am', '2:30pm', or '14:30'.",
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              }
            } else if (_pendingLog is Reminder) {
              final pending = _pendingLog as Reminder;
              if (extractedTime != null) {
                // Update reminder with extracted time
                final updatedReminder = Reminder(
                  title: pending.title,
                  description: pending.description,
                  reminderTime: DateTime(
                    pending.reminderTime.year,
                    pending.reminderTime.month,
                    pending.reminderTime.day,
                    extractedTime.hour,
                    extractedTime.minute,
                  ),
                  timestamp: DateTime.now(),
                  advanceTiming: pending.advanceTiming,
                );

                setState(() {
                  _pendingLog = updatedReminder;
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Convert previous reminder confirmation messages to regular messages
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i].isConfirmation &&
                        _messages[i].pendingLogEntry?.logType == 'reminder') {
                      _messages[i] = _ChatMessage(
                        text: _messages[i].text,
                        isUser: false,
                        timestamp: _messages[i].timestamp,
                        isConfirmation: false,
                      );
                    }
                  }

                  _messages.add(
                    _ChatMessage(
                      text: _getConfirmationMessage(updatedReminder),
                      isUser: false,
                      timestamp: DateTime.now(),
                      isConfirmation: true,
                      onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                          _handleLogConfirmation(confirmed, updatedLogEntry),
                      pendingLogEntry: updatedReminder,
                      canConfirm: true,
                      showEdit: true,
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              } else {
                // No time extracted - just continue the conversation
                setState(() {
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Add a helpful message to continue the conversation
                  _messages.add(
                    _ChatMessage(
                      text:
                          "⏰ I didn't understand that time format. Please try again with a time like '9am', '2:30pm', or '14:30'.",
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              }
            }
          }

          // --- FALLBACK: Handle any input when there's a pending log entry (for typos, etc.) ---
          if (_pendingLog != null &&
              (intent == 'create_task' || intent == 'create_reminder') &&
              fields['title'] != null &&
              (fields['title'].toString().toLowerCase() == 'reminder' ||
                  fields['title'].toString().toLowerCase() == 'task' ||
                  fields['title'].toString().length <= 3 ||
                  _extractTimeFromMessage(message) != null)) {
            print(
              'DEBUG: Fallback continuation - treating as time/date input for pending log',
            );

            if (_pendingLog is Task) {
              final pending = _pendingLog as Task;
              // Try to extract time from the original message
              TimeOfDay? extractedTime = _extractTimeFromMessage(message);

              // If we extracted a time and have a due date, update the task
              if (extractedTime != null && pending.dueDate != null) {
                // Create updated task with extracted time
                final updatedTask = Task(
                  id: pending.id,
                  title: pending.title,
                  dueDate: DateTime(
                    pending.dueDate!.year,
                    pending.dueDate!.month,
                    pending.dueDate!.day,
                    extractedTime.hour,
                    extractedTime.minute,
                  ),
                  timeOfDay: extractedTime,
                  timestamp: DateTime.now(),
                );

                setState(() {
                  _pendingLog = updatedTask;
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Convert previous task confirmation messages to regular messages
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i].isConfirmation &&
                        _messages[i].pendingLogEntry?.logType == 'task') {
                      _messages[i] = _ChatMessage(
                        text: _messages[i].text,
                        isUser: false,
                        timestamp: _messages[i].timestamp,
                        isConfirmation: false,
                      );
                    }
                  }

                  _messages.add(
                    _ChatMessage(
                      text: _getConfirmationMessage(updatedTask),
                      isUser: false,
                      timestamp: DateTime.now(),
                      isConfirmation: true,
                      onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                          _handleLogConfirmation(confirmed, updatedLogEntry),
                      pendingLogEntry: updatedTask,
                      canConfirm: _hasRequiredFields(updatedTask),
                      showEdit: true,
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              } else {
                // No time extracted or no due date - just continue the conversation
                setState(() {
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              }
            } else if (_pendingLog is Reminder) {
              final pending = _pendingLog as Reminder;
              // Try to extract time from the original message
              TimeOfDay? extractedTime = _extractTimeFromMessage(message);

              if (extractedTime != null) {
                // Create updated reminder with extracted time
                final updatedReminder = Reminder(
                  title: pending.title,
                  description: pending.description,
                  reminderTime: DateTime(
                    pending.reminderTime.year,
                    pending.reminderTime.month,
                    pending.reminderTime.day,
                    extractedTime.hour,
                    extractedTime.minute,
                  ),
                  timestamp: DateTime.now(),
                  advanceTiming: pending.advanceTiming,
                );

                setState(() {
                  _pendingLog = updatedReminder;
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }

                  // Convert previous reminder confirmation messages to regular messages
                  for (int i = 0; i < _messages.length; i++) {
                    if (_messages[i].isConfirmation &&
                        _messages[i].pendingLogEntry?.logType == 'reminder') {
                      _messages[i] = _ChatMessage(
                        text: _messages[i].text,
                        isUser: false,
                        timestamp: _messages[i].timestamp,
                        isConfirmation: false,
                      );
                    }
                  }

                  _messages.add(
                    _ChatMessage(
                      text: _getConfirmationMessage(updatedReminder),
                      isUser: false,
                      timestamp: DateTime.now(),
                      isConfirmation: true,
                      onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                          _handleLogConfirmation(confirmed, updatedLogEntry),
                      pendingLogEntry: updatedReminder,
                      canConfirm: true,
                      showEdit: true,
                    ),
                  );
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              } else {
                // No time extracted - just continue the conversation
                setState(() {
                  // Remove loading message if it exists
                  if (_messages.isNotEmpty &&
                      _messages.last.text == "🤖 Processing...") {
                    _messages.removeLast();
                  }
                  _isLoading = false;
                });
                _scrollToBottom();
                return;
              }
            }
          }

          // Original AI logic for new tasks/reminders
          if (intent == 'create_task') {
            final title = _capitalizeTitle(fields['title'] ?? '');
            final description = fields['description'] ?? '';

            // Set default priority to medium if not specified
            TaskPriority priorityEnum = TaskPriority.medium;
            print('DEBUG: Processing priority field: ${fields['priority']}');
            if (fields['priority'] is String && fields['priority'].isNotEmpty) {
              final p = fields['priority'].toString().toLowerCase();
              print('DEBUG: Priority string: $p');
              if (p == 'low') {
                priorityEnum = TaskPriority.low;
              } else if (p == 'high')
                priorityEnum = TaskPriority.high;
              else if (p == 'medium')
                priorityEnum = TaskPriority.medium;
            }
            print('DEBUG: Final priority enum: $priorityEnum');

            // Set default category to Personal if not specified (matching dropdown options)
            String category = 'Personal';
            if (fields['category'] is String && fields['category'].isNotEmpty) {
              category = fields['category'].toString().toLowerCase();
              // Capitalize first letter to match dropdown options
              category = category[0].toUpperCase() + category.substring(1);
            }

            // Set default reminder to none if not specified
            ReminderType reminderType = ReminderType.none;
            final reminderAdvance = fields['reminderAdvance'] ?? '';
            print('DEBUG: Processing reminderAdvance field: $reminderAdvance');
            if (reminderAdvance.isNotEmpty) {
              if (reminderAdvance.contains('15 minutes before')) {
                reminderType = ReminderType.fifteenMinutes;
              } else if (reminderAdvance.contains('30 minutes before') ||
                  reminderAdvance.contains('half an hour before')) {
                reminderType = ReminderType.thirtyMinutes;
              } else if (reminderAdvance.contains('1 hour before') ||
                  reminderAdvance.contains('one hour before')) {
                reminderType = ReminderType.oneHour;
              } else if (reminderAdvance.contains('2 hours before')) {
                reminderType = ReminderType.twoHours;
              } else if (reminderAdvance.contains('1 day before')) {
                reminderType = ReminderType.oneDay;
              } else if (reminderAdvance.contains('5 minutes before')) {
                reminderType = ReminderType.fiveMinutes;
              } else if (reminderAdvance.contains('20 minutes before')) {
                reminderType = ReminderType.twentyMinutes;
              }
            }
            print('DEBUG: Final reminder type: $reminderType');

            DateTime? dueDate;
            if (fields['dueDate'] != null && fields['dueDate'] is String) {
              final now = DateTime.now();
              final dateStr = fields['dueDate'].toLowerCase();

              if (dateStr == 'tomorrow') {
                // Set only the date part, not the time
                dueDate = DateTime(now.year, now.month, now.day + 1);
              } else if (dateStr == 'today') {
                // Set only the date part, not the time
                dueDate = DateTime(now.year, now.month, now.day);
              } else if (dateStr.startsWith('next ')) {
                // Handle "next monday", "next tuesday", etc.
                final dayName = dateStr.substring(5); // Remove "next "
                final targetWeekday = _getWeekdayFromName(dayName);
                if (targetWeekday != null) {
                  // Fix: Calculate days until next occurrence of target weekday
                  int daysUntilTarget = targetWeekday - now.weekday;
                  if (daysUntilTarget <= 0) {
                    // If target is today or in the past, get next week's occurrence
                    daysUntilTarget += 7;
                  }
                  print(
                    'DEBUG: Next day calculation - targetWeekday: $targetWeekday, now.weekday: ${now.weekday}, daysUntilTarget: $daysUntilTarget',
                  );
                  // Set only the date part, not the time
                  dueDate = DateTime(
                    now.year,
                    now.month,
                    now.day + daysUntilTarget,
                  );
                  print('DEBUG: Calculated dueDate: $dueDate');
                }
              } else if (dateStr.startsWith('the ')) {
                // Handle "the 22nd", "the 15th", etc.
                final dayMatch = RegExp(
                  r'the (\d{1,2})(st|nd|rd|th)?',
                ).firstMatch(dateStr);
                if (dayMatch != null) {
                  final day = int.parse(dayMatch.group(1)!);
                  final currentMonth = now.month;
                  final currentYear = now.year;

                  // Try current month first
                  var testDate = DateTime(currentYear, currentMonth, day);
                  if (testDate.isBefore(now)) {
                    // If it's in the past, try next month
                    testDate = DateTime(currentYear, currentMonth + 1, day);
                  }
                  dueDate = testDate;
                }
              } else {
                print(
                  'DEBUG: Trying to parse date string: "${fields['dueDate']}"',
                );
                dueDate = DateTime.tryParse(fields['dueDate']);
                print('DEBUG: Parsed dueDate: $dueDate');
              }
            }
            TimeOfDay? timeOfDay;
            if (fields['timeOfDay'] != null && fields['timeOfDay'] is String) {
              final timeMatch = RegExp(
                r'^(\d{1,2})(?::(\d{2}))?',
              ).firstMatch(fields['timeOfDay']);
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(1)!);
                int minute = timeMatch.group(2) != null
                    ? int.parse(timeMatch.group(2)!)
                    : 0;
                timeOfDay = TimeOfDay(hour: hour, minute: minute);
              }
            }
            // Handle repeat functionality for tasks
            task_model.RecurrenceType recurrenceType =
                task_model.RecurrenceType.none;
            List<int>? customDays;
            int? interval;

            if (fields['repeatType'] != null) {
              final repeatType = fields['repeatType'] as String;
              switch (repeatType) {
                case 'daily':
                  recurrenceType = task_model.RecurrenceType.daily;
                  break;
                case 'weekly':
                  // If repeatDays is provided, use custom instead of weekly
                  if (fields['repeatDays'] != null) {
                    recurrenceType = task_model.RecurrenceType.custom;
                    customDays = List<int>.from(fields['repeatDays']);
                  } else {
                    recurrenceType = task_model.RecurrenceType.weekly;
                  }
                  break;
                case 'monthly':
                  recurrenceType = task_model.RecurrenceType.monthly;
                  break;
                case 'everyNDays':
                  recurrenceType = task_model.RecurrenceType.everyNDays;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNWeeks':
                  recurrenceType = task_model.RecurrenceType.everyNWeeks;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNMonths':
                  recurrenceType = task_model.RecurrenceType.everyNMonths;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'custom':
                  recurrenceType = task_model.RecurrenceType.custom;
                  if (fields['repeatDays'] != null) {
                    customDays = List<int>.from(fields['repeatDays']);
                  }
                  break;
              }
            }

            // Create the Task object
            print(
              'DEBUG: Creating Task with priority: $priorityEnum, reminder: $reminderType, recurrence: $recurrenceType',
            );
            // Parse limited duration fields
            int? repeatDuration;
            String? repeatDurationType;
            if (fields['repeatDuration'] != null) {
              repeatDuration = int.tryParse(
                fields['repeatDuration'].toString(),
              );
            }
            if (fields['repeatDurationType'] != null) {
              repeatDurationType = fields['repeatDurationType'].toString();
            }

            final newTask = Task(
              title: title,
              description: description,
              category: category,
              priority: priorityEnum,
              dueDate: dueDate,
              timeOfDay: timeOfDay,
              reminder: reminderType,
              timestamp: DateTime.now(),
              recurrenceType: recurrenceType,
              customDays: customDays,
              interval: interval,
              repeatDuration: repeatDuration,
              repeatDurationType: repeatDurationType,
            );
            print(
              'DEBUG: Created Task - priority: ${newTask.priority}, reminder: ${newTask.reminder}',
            );
            setState(() {
              _pendingLog = newTask;
              // Remove loading message if it exists
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }

              // Check if task has a time set
              bool hasTime =
                  (newTask.timeOfDay != null) ||
                  (newTask.dueDate != null &&
                      (newTask.dueDate!.hour != 0 ||
                          newTask.dueDate!.minute != 0));

              // Debug: Print time check details
              print(
                'DEBUG: Task time check - timeOfDay: ${newTask.timeOfDay}, dueDate: ${newTask.dueDate}, hasTime: $hasTime',
              );

              if (hasTime) {
                // Show confirmation if task has time
                _messages.add(
                  _ChatMessage(
                    text: _getConfirmationMessage(newTask),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: newTask,
                    canConfirm: _hasRequiredFields(newTask),
                    showEdit: true,
                  ),
                );
              } else {
                // Show message that time is required with captured information
                _messages.add(
                  _ChatMessage(
                    text: _getTaskTimeRequiredMessage(newTask),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: newTask,
                    canConfirm: false, // Disable Yes button when no time is set
                    showEdit: true,
                  ),
                );
              }
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          } else if (intent == 'create_reminder') {
            final title = _capitalizeTitle(fields['title'] ?? '');
            final description = fields['description'] ?? '';
            final reminderAdvance = fields['reminderAdvance'] ?? '';
            DateTime reminderTime = DateTime.now();

            // Debug: Print the AI response
            print('DEBUG: AI Response for reminder - fields: $fields');

            // Handle reminderDate + reminderTime format (what AI is actually returning)
            if (fields['reminderDate'] != null &&
                fields['reminderTime'] != null) {
              final reminderDateStr = fields['reminderDate'] as String;
              final reminderTimeStr = fields['reminderTime'] as String;

              // Parse the date
              DateTime? reminderDate = DateTime.tryParse(reminderDateStr);
              if (reminderDate != null) {
                // Parse the time (format: "13:00" or "1:00 PM")
                final timeMatch = RegExp(
                  r'(\d{1,2}):(\d{2})',
                ).firstMatch(reminderTimeStr);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = int.parse(timeMatch.group(2)!);

                  // Handle 24-hour format
                  if (hour >= 24) hour = hour % 24;

                  reminderTime = DateTime(
                    reminderDate.year,
                    reminderDate.month,
                    reminderDate.day,
                    hour,
                    minute,
                  );
                } else {
                  // Fallback to 9 AM if time parsing fails
                  reminderTime = DateTime(
                    reminderDate.year,
                    reminderDate.month,
                    reminderDate.day,
                    9,
                    0,
                  );
                }
              }
            }
            // Handle reminderDate only (no time specified)
            else if (fields['reminderDate'] != null &&
                fields['reminderDate'] is String) {
              final reminderDateStr = fields['reminderDate'] as String;
              DateTime? reminderDate = DateTime.tryParse(reminderDateStr);
              if (reminderDate != null) {
                // Set to midnight (00:00) to indicate no specific time
                reminderTime = DateTime(
                  reminderDate.year,
                  reminderDate.month,
                  reminderDate.day,
                  0,
                  0,
                );
              }
            }
            // Handle reminderTime format (e.g., "tomorrow 08:00")
            else if (fields['reminderTime'] != null &&
                fields['reminderTime'] is String) {
              final reminderTimeStr = fields['reminderTime'] as String;
              final now = DateTime.now();

              // Parse reminder time string like "tomorrow 11:00" or "today 9:30"
              if (reminderTimeStr.toLowerCase().contains('tomorrow')) {
                // Extract time from "tomorrow 11:00" format
                final timeMatch = RegExp(
                  r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
                  caseSensitive: false,
                ).firstMatch(reminderTimeStr);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = timeMatch.group(2) != null
                      ? int.parse(timeMatch.group(2)!)
                      : 0;
                  final ampm = timeMatch.group(3)?.toLowerCase();
                  if (ampm == 'pm' && hour < 12) hour += 12;
                  if (ampm == 'am' && hour == 12) hour = 0;

                  final tomorrow = now.add(Duration(days: 1));
                  reminderTime = DateTime(
                    tomorrow.year,
                    tomorrow.month,
                    tomorrow.day,
                    hour,
                    minute,
                  );
                } else {
                  // No time specified, set to tomorrow at midnight (no specific time)
                  final tomorrow = now.add(Duration(days: 1));
                  reminderTime = DateTime(
                    tomorrow.year,
                    tomorrow.month,
                    tomorrow.day,
                    0, // Midnight - indicates no specific time
                    0,
                  );
                }
              } else if (reminderTimeStr.toLowerCase().contains('today')) {
                // Extract time from "today 11:00" format
                final timeMatch = RegExp(
                  r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
                  caseSensitive: false,
                ).firstMatch(reminderTimeStr);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = timeMatch.group(2) != null
                      ? int.parse(timeMatch.group(2)!)
                      : 0;
                  final ampm = timeMatch.group(3)?.toLowerCase();
                  if (ampm == 'pm' && hour < 12) hour += 12;
                  if (ampm == 'am' && hour == 12) hour = 0;

                  reminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  );
                } else {
                  // No time specified, set to today at midnight (no specific time)
                  reminderTime = DateTime(now.year, now.month, now.day, 0, 0);
                }
              } else {
                // Try to parse as date/time string
                reminderTime = DateTime.tryParse(reminderTimeStr) ?? now;
              }
            }

            // Create reminder and show confirmation instead of opening modal directly

            // Handle reminder advance timing
            DateTime finalReminderTime = reminderTime;
            if (reminderAdvance.isNotEmpty) {
              if (reminderAdvance.contains('15 minutes before')) {
                finalReminderTime = reminderTime.subtract(
                  Duration(minutes: 15),
                );
              } else if (reminderAdvance.contains('30 minutes before') ||
                  reminderAdvance.contains('half an hour before')) {
                finalReminderTime = reminderTime.subtract(
                  Duration(minutes: 30),
                );
              } else if (reminderAdvance.contains('1 hour before') ||
                  reminderAdvance.contains('one hour before')) {
                finalReminderTime = reminderTime.subtract(Duration(hours: 1));
              } else if (reminderAdvance.contains('2 hours before')) {
                finalReminderTime = reminderTime.subtract(Duration(hours: 2));
              } else if (reminderAdvance.contains('1 day before')) {
                finalReminderTime = reminderTime.subtract(Duration(days: 1));
              } else if (reminderAdvance.contains('5 minutes before')) {
                finalReminderTime = reminderTime.subtract(Duration(minutes: 5));
              } else if (reminderAdvance.contains('20 minutes before')) {
                finalReminderTime = reminderTime.subtract(
                  Duration(minutes: 20),
                );
              }
            }

            // Handle repeat functionality
            RecurrenceType recurrenceType = RecurrenceType.none;
            List<int>? customDays;
            int? interval;
            DateTime? endDate;

            if (fields['repeatType'] != null) {
              final repeatType = fields['repeatType'] as String;
              switch (repeatType) {
                case 'daily':
                  recurrenceType = RecurrenceType.daily;
                  break;
                case 'weekly':
                  recurrenceType = RecurrenceType.weekly;
                  break;
                case 'monthly':
                  recurrenceType = RecurrenceType.monthly;
                  break;
                case 'everyNDays':
                  recurrenceType = RecurrenceType.everyNDays;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNWeeks':
                  recurrenceType = RecurrenceType.everyNWeeks;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'everyNMonths':
                  recurrenceType = RecurrenceType.everyNMonths;
                  interval = fields['repeatInterval'] as int? ?? 1;
                  break;
                case 'custom':
                  recurrenceType = RecurrenceType.custom;
                  if (fields['repeatDays'] != null) {
                    customDays = List<int>.from(fields['repeatDays']);
                  }
                  break;
              }

              // Handle end date
              if (fields['repeatEndDate'] != null) {
                final endDateStr = fields['repeatEndDate'] as String;
                endDate = DateTime.tryParse(endDateStr);
              }
            }

            final reminder = Reminder(
              title: title,
              description: description.isNotEmpty ? description : null,
              reminderTime: finalReminderTime,
              timestamp: DateTime.now(),
              advanceTiming:
                  fields['reminderAdvance'] != null &&
                      (fields['reminderAdvance'] as String).isNotEmpty
                  ? fields['reminderAdvance'] as String
                  : null,
              recurrenceType: recurrenceType,
              customDays: customDays,
              interval: interval,
              endDate: endDate,
              repeatDuration: fields['repeatDuration'] != null
                  ? int.tryParse(fields['repeatDuration'].toString())
                  : null,
              repeatDurationType: fields['repeatDurationType']?.toString(),
            );
            setState(() {
              _pendingLog =
                  reminder; // Set pending log for conversation continuation
              // Remove loading message if it exists
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }

              // Check if reminder has a specific time
              bool hasTime = reminderTime.hour != 0 || reminderTime.minute != 0;

              if (hasTime) {
                // Show confirmation if reminder has time
                _messages.add(
                  _ChatMessage(
                    text: _getConfirmationMessage(reminder),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: reminder,
                    canConfirm: _hasRequiredFields(reminder),
                    showEdit: true,
                  ),
                );
              } else {
                // Show message that time is required with captured information
                _messages.add(
                  _ChatMessage(
                    text: _getReminderTimeRequiredMessage(reminder),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: reminder,
                    canConfirm: false, // Disable Yes button when no time is set
                    showEdit: true,
                  ),
                );
              }
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          } else if (intent == 'view_reminders') {
            final timeframe = fields['timeframe'] ?? 'all';

            // Handle reminder query asynchronously
            _handleReminderQuery(timeframe);
            return;
          } else if (intent == 'note') {
            final title = fields['title'] ?? '';
            final content = fields['content'] ?? '';
            final note = Note(
              id: NotesService.generateId(),
              title: title,
              content: content,
            );
            setState(() {
              _messages.add(
                _ChatMessage(
                  text: _getConfirmationMessage(note),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isConfirmation: true,
                  onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                      _handleLogConfirmation(confirmed, updatedLogEntry),
                  pendingLogEntry: note,
                  canConfirm: true,
                  showEdit: true,
                ),
              );
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          } else if (intent == 'gym') {
            final workoutName = fields['workoutName'] ?? '';
            final exercises = fields['exercises'] ?? [];
            final gymLog = GymLog(
              workoutName: workoutName,
              exercises: exercises
                  .map(
                    (e) => Exercise(
                      name: e['name'],
                      sets: e['sets'],
                      reps: e['reps'],
                    ),
                  )
                  .toList(),
              timestamp: DateTime.now(),
            );
            setState(() {
              _pendingLog = gymLog;
              // Remove loading message if it exists
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }
              _messages.add(
                _ChatMessage(
                  text: _getConfirmationMessage(gymLog),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isConfirmation: true,
                  onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                      _handleLogConfirmation(confirmed, updatedLogEntry),
                  pendingLogEntry: gymLog,
                  canConfirm: true,
                  showEdit: true,
                ),
              );
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          } else if (intent == 'view_tasks') {
            final timeframe = fields['timeframe'] ?? 'all';

            // Handle task query asynchronously
            _handleTaskQuery(timeframe);
            return;
          }
          // Add more intents as needed
        }
        // If AI response is not usable, fallback to local parser
      } catch (e) {
        print('DEBUG: AIService error: $e');
        // Remove loading message if it exists
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          setState(() {
            _messages.removeLast();
            _isLoading = false; // Stop loading
          });
        }

        // Add error message for timeout
        if (e.toString().contains('timeout')) {
          setState(() {
            _messages.add(
              _ChatMessage(
                text: "⚠️ AI is taking too long. Please try again.",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });
        }
      }

      // --- FALLBACK PARSER DISCONNECTED FOR AI-ONLY OPERATION ---
      // Keeping this code for future Phase 5 implementation (AI Learning & Local Intelligence)
      /*
      // --- FALLBACK: Use local parser if AI fails ---
      try {
        final parsed = LogParserService.parseUserInput(message);
        print('DEBUG: [Fallback Parser] result: $parsed');
        print('DEBUG: Parser result: $parsed');
        print('DEBUG: Parsed type: ${parsed.type}');
        print('DEBUG: Parsed dateTime: ${parsed.dateTime}');
        print('DEBUG: Parsed hasTime: ${parsed.hasTime}');
        print('DEBUG: Parsed action: ${parsed.action}');

        LogEntry? logEntry;

        // --- NEW: Conversation continuation logic ---
        // If we have a pending log entry and user types date/time info, merge it
        if (_pendingLog != null &&
            (parsed.type == LogType.unknown ||
                parsed.hasTime ||
                // Handle simple time formats like "530", "5:30", etc.
                RegExp(
                  r'^\d{1,2}(:\d{2})?\s*(am|pm)?$',
                  caseSensitive: false,
                ).hasMatch(message))) {
          print(
            'DEBUG: Conversation continuation - merging date/time info with pending log',
          );

          if (_pendingLog is Task) {
            final pending = _pendingLog as Task;
            DateTime? newDueDate;
            TimeOfDay? newTimeOfDay;

            // Extract date and time from the message
            if (parsed.dateTime != null) {
              newDueDate = parsed.dateTime;
              if (parsed.hasTime) {
                newTimeOfDay = TimeOfDay(
                  hour: parsed.dateTime!.hour,
                  minute: parsed.dateTime!.minute,
                );
              }
            } else if (parsed.hasTime ||
                RegExp(
                  r'^\d{1,2}(:\d{2})?\s*(am|pm)?$',
                  caseSensitive: false,
                ).hasMatch(message)) {
              // Extract time from message like "10 am tomorrow", "530", "5:30", etc.
              TimeOfDay? extractedTime;

              // Try standard time format first (with or without space before am/pm)
              final timeMatch = RegExp(
                r'^(\d{1,2})(:(\d{2}))?\s*(am|pm)$',
                caseSensitive: false,
              ).firstMatch(message);

              print('DEBUG: Time extraction - message: "$message"');
              print('DEBUG: Time extraction - timeMatch: $timeMatch');

              if (timeMatch != null) {
                print('DEBUG: Time extraction - matched groups:');
                for (int i = 0; i <= timeMatch.groupCount; i++) {
                  print(
                    'DEBUG: Time extraction - group $i: ${timeMatch.group(i)}',
                  );
                }

                int hour = int.parse(timeMatch.group(1)!);
                int minute = timeMatch.group(3) != null
                    ? int.parse(timeMatch.group(3)!)
                    : 0;
                final ampm = timeMatch.group(4)?.toLowerCase();
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;
                extractedTime = TimeOfDay(hour: hour, minute: minute);
                print(
                  'DEBUG: Time extraction - extracted time: $extractedTime',
                );
              } else {
                // Try simple time format like "530" or "5:30"
                final simpleTimeMatch = RegExp(
                  r'^(\d{1,2})(:(\d{2}))?$',
                ).firstMatch(message);
                if (simpleTimeMatch != null) {
                  int hour = int.parse(simpleTimeMatch.group(1)!);
                  int minute = simpleTimeMatch.group(3) != null
                      ? int.parse(simpleTimeMatch.group(3)!)
                      : 0;
                  // Assume PM for times like "530" (5:30 PM)
                  if (hour < 12) hour += 12;
                  extractedTime = TimeOfDay(hour: hour, minute: minute);
                }
              }

              if (extractedTime != null) {
                newTimeOfDay = extractedTime;
              }

              // Check for date keywords
              final now = DateTime.now();
              if (message.toLowerCase().contains('tomorrow')) {
                // Set only the date part, not the time
                newDueDate = DateTime(now.year, now.month, now.day + 1);
              } else if (message.toLowerCase().contains('today')) {
                // Set only the date part, not the time
                newDueDate = DateTime(now.year, now.month, now.day);
              }
              // If no date keywords found, preserve the original date from pending task
              // This prevents overwriting "tomorrow" with "today" when user just types time
            }

            // Create updated task with merged information
            if (newDueDate != null || newTimeOfDay != null) {
              print('DEBUG: Conversation continuation - creating updated task');
              print(
                'DEBUG: Conversation continuation - newDueDate: $newDueDate',
              );
              print(
                'DEBUG: Conversation continuation - newTimeOfDay: $newTimeOfDay',
              );
              print(
                'DEBUG: Conversation continuation - pending.dueDate: ${pending.dueDate}',
              );

              // If only time was provided, preserve the original date from pending task
              DateTime? finalDueDate;
              if (newDueDate != null) {
                finalDueDate = newDueDate;
              } else if (newTimeOfDay != null && pending.dueDate != null) {
                // Merge new time with existing date
                finalDueDate = DateTime(
                  pending.dueDate!.year,
                  pending.dueDate!.month,
                  pending.dueDate!.day,
                  newTimeOfDay.hour,
                  newTimeOfDay.minute,
                );
              } else {
                finalDueDate = pending.dueDate;
              }

              print(
                'DEBUG: Conversation continuation - finalDueDate: $finalDueDate',
              );

              logEntry = Task(
                id: pending.id,
                title: pending.title,
                dueDate: finalDueDate,
                timeOfDay: newTimeOfDay ?? pending.timeOfDay,
                timestamp: DateTime.now(),
              );
              _pendingLog = null;
              print(
                'DEBUG: Conversation continuation - created logEntry: $logEntry',
              );
            } else {
              print(
                'DEBUG: Conversation continuation - no new date or time provided',
              );
            }
          } else if (_pendingLog is Reminder) {
            final pending = _pendingLog as Reminder;
            DateTime? newReminderTime;

            // Extract date and time from the message
            if (parsed.dateTime != null) {
              newReminderTime = parsed.dateTime;
            } else if (parsed.hasTime) {
              // Extract time from message like "10 am tomorrow"
              final timeMatch = RegExp(
                r'(\d{1,2})(:(\d{2}))?\s*(am|pm)',
                caseSensitive: false,
              ).firstMatch(message);
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(1)!);
                int minute = timeMatch.group(3) != null
                    ? int.parse(timeMatch.group(3)!)
                    : 0;
                final ampm = timeMatch.group(4)?.toLowerCase();
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                // Check for date keywords
                final now = DateTime.now();
                if (message.toLowerCase().contains('tomorrow')) {
                  newReminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day + 1,
                    hour,
                    minute,
                  );
                } else if (message.toLowerCase().contains('today')) {
                  newReminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  );
                } else {
                  newReminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  );
                }
              }
            }

            // Create updated reminder with merged information
            if (newReminderTime != null) {
              logEntry = Reminder(
                id: pending.id,
                title: pending.title,
                reminderTime: newReminderTime,
                timestamp: DateTime.now(),
              );
              _pendingLog = null;
            }
          }
        } else {
          // Normal parsing (not conversation continuation)
          switch (parsed.type) {
            case LogType.task:
              logEntry = Task(
                title: parsed.action ?? '',
                dueDate: parsed.dateTime,
                timeOfDay: parsed.hasTime
                    ? TimeOfDay(
                        hour: parsed.dateTime!.hour,
                        minute: parsed.dateTime!.minute,
                      )
                    : null,
                timestamp: DateTime.now(),
              );
              break;
            case LogType.reminder:
              logEntry = Reminder(
                title: parsed.action ?? '',
                reminderTime: parsed.dateTime ?? DateTime.now(),
                timestamp: DateTime.now(),
              );
              break;
            case LogType.expense:
              logEntry = Expense(
                category: parsed.action ?? '',
                amount: parsed.amount ?? 0,
                timestamp: DateTime.now(),
              );
              break;
            case LogType.note:
              logEntry = Note(
                title: parsed.action ?? '',
                content: parsed.action ?? '',
                timestamp: DateTime.now(),
              );
              break;
            case LogType.gym:
              logEntry = GymLog(
                workoutName: parsed.action ?? '',
                exercises: [
                  Exercise(
                    name: parsed.action ?? '',
                    sets: 0,
                    reps: 0,
                  )
                ],
                timestamp: DateTime.now(),
              );
              break;
            case LogType.unknown:
              // Handle unknown input
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: "I'm not sure what you want to log. Could you be more specific?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
                _isLoading = false; // Stop loading
              });
              _scrollToBottom();
              return;
          }
        }

        // Process the parsed log entry
        if (logEntry != null) {
          print('DEBUG: Processing logEntry: $logEntry');
          bool canConfirm = false;
          bool showEdit = false;
          String confirmationMessage = '';

          // For tasks, check if we have required fields
          if (logEntry is Task) {
            final task = logEntry as Task;
            if (task.title.isNotEmpty && task.dueDate != null) {
              canConfirm = true;
              confirmationMessage = _getConfirmationMessage(task);
              showEdit = true;
            } else {
              // Store as pending and ask for missing info
              _pendingLog = task;
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: "What should I remind you about?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
                _isLoading = false; // Stop loading
              });
              _scrollToBottom();
              return;
            }
          } else {
            // For other log types, use validation method
            canConfirm = _hasRequiredFields(logEntry);
            confirmationMessage = _getConfirmationMessage(logEntry);
            showEdit = true;
          }
          print(
            'DEBUG: Adding _ChatMessage with showEdit: $showEdit, canConfirm: $canConfirm, onConfirmationResponse: ${true}',
          );
          
          // Convert previous confirmation messages to regular messages (remove buttons but keep text)
          if (logEntry is Task) {
            for (int i = 0; i < _messages.length; i++) {
              if (_messages[i].isConfirmation && _messages[i].pendingLogEntry?.logType == 'task') {
                // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                _messages[i] = _ChatMessage(
                  text: _messages[i].text,
                  isUser: false,
                  timestamp: _messages[i].timestamp,
                  isConfirmation: false, // This removes the buttons
                );
              }
            }
          } else if (logEntry is Reminder) {
            for (int i = 0; i < _messages.length; i++) {
              if (_messages[i].isConfirmation && _messages[i].pendingLogEntry?.logType == 'reminder') {
                // Convert confirmation message to regular message (removes Yes/No/Edit buttons)
                _messages[i] = _ChatMessage(
                  text: _messages[i].text,
                  isUser: false,
                  timestamp: _messages[i].timestamp,
                  isConfirmation: false, // This removes the buttons
                );
              }
            }
          }
          
          _messages.add(
            _ChatMessage(
              text: confirmationMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isConfirmation: true,
              onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                  _handleLogConfirmation(confirmed, updatedLogEntry),
              pendingLogEntry: logEntry,
              canConfirm: canConfirm,
              showEdit: showEdit,
            ),
          );
          // Remove loading message if it exists
          if (_messages.isNotEmpty &&
              _messages.last.text == "🤖 Processing...") {
            _messages.removeLast();
          }
          _isLoading = false; // Stop loading
        }
        _scrollToBottom();
      } catch (e) {
        print('DEBUG: Error handling fallback parser: $e');
        // Handle error gracefully
        setState(() {
          _messages.add(
            _ChatMessage(
              text: "❌ Error processing message: $e",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false; // Stop loading
        });
        _scrollToBottom();
      }
      */
    }
  }

  // Test AI service
  Future<void> _testAIService() async {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: "🤖 Testing AI connection...",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });

    try {
      final result = await AIService.processUserMessage(
        "Create a task for doctor appointment tomorrow at 2pm",
      );

      setState(() {
        if (result.containsKey('error')) {
          _messages.add(
            _ChatMessage(
              text: "❌ AI Error: ${result['error']}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _messages.add(
            _ChatMessage(
              text: "✅ AI Response: ${result.toString()}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          // --- AI integration: open correct modal based on intent ---
          if (result.containsKey('intent') && result.containsKey('fields')) {
            final intent = result['intent'];
            final fields = result['fields'] as Map<String, dynamic>;
            if (intent == 'create_task') {
              final title = fields['title'] ?? '';
              final description = fields['description'] ?? '';
              final priority = fields['priority'] ?? '';
              // Use AI's dueDate and timeOfDay fields directly
              DateTime? dueDate;
              if (fields['dueDate'] != null && fields['dueDate'] is String) {
                final now = DateTime.now();
                if (fields['dueDate'].toLowerCase() == 'tomorrow') {
                  dueDate = now.add(Duration(days: 1));
                } else if (fields['dueDate'].toLowerCase() == 'today') {
                  dueDate = now;
                } else {
                  // Try to parse as date string
                  dueDate = DateTime.tryParse(fields['dueDate']);
                }
              }
              TimeOfDay? timeOfDay;
              if (fields['timeOfDay'] != null &&
                  fields['timeOfDay'] is String) {
                final timeMatch = RegExp(
                  r'^(\d{1,2})(?::(\d{2}))?',
                ).firstMatch(fields['timeOfDay']);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = timeMatch.group(2) != null
                      ? int.parse(timeMatch.group(2)!)
                      : 0;
                  timeOfDay = TimeOfDay(hour: hour, minute: minute);
                }
              }
              // Map AI string to TaskPriority enum, default to medium if missing/invalid
              TaskPriority priorityEnum = TaskPriority.medium;
              if (fields['priority'] is String &&
                  fields['priority'].isNotEmpty) {
                final p = fields['priority'].toString().toLowerCase();
                if (p == 'low') {
                  priorityEnum = TaskPriority.low;
                } else if (p == 'high')
                  priorityEnum = TaskPriority.high;
                else if (p == 'medium')
                  priorityEnum = TaskPriority.medium;
              }
              showTaskModal(
                context,
                task: Task(
                  title: title,
                  description: description,
                  priority: priorityEnum,
                  dueDate: dueDate,
                  timeOfDay: timeOfDay,
                  timestamp: DateTime.now(),
                ),
              );
            } else if (intent == 'create_reminder') {
              final title = _capitalizeTitle(fields['title'] ?? '');
              final description = fields['description'] ?? '';
              final reminderAdvance = fields['reminderAdvance'] ?? '';
              DateTime reminderTime = DateTime.now();

              // Handle reminderDate + reminderTime format (what AI is actually returning)
              if (fields['reminderDate'] != null &&
                  fields['reminderTime'] != null) {
                final reminderDateStr = fields['reminderDate'] as String;
                final reminderTimeStr = fields['reminderTime'] as String;

                // Parse the date
                DateTime? reminderDate = DateTime.tryParse(reminderDateStr);
                if (reminderDate != null) {
                  // Parse the time (format: "13:00" or "1:00 PM")
                  final timeMatch = RegExp(
                    r'(\d{1,2}):(\d{2})',
                  ).firstMatch(reminderTimeStr);
                  if (timeMatch != null) {
                    int hour = int.parse(timeMatch.group(1)!);
                    int minute = int.parse(timeMatch.group(2)!);

                    // Handle 24-hour format
                    if (hour >= 24) hour = hour % 24;

                    reminderTime = DateTime(
                      reminderDate.year,
                      reminderDate.month,
                      reminderDate.day,
                      hour,
                      minute,
                    );
                  } else {
                    // Fallback to 9 AM if time parsing fails
                    reminderTime = DateTime(
                      reminderDate.year,
                      reminderDate.month,
                      reminderDate.day,
                      9,
                      0,
                    );
                  }
                }
              }
              // Handle reminderTime format (e.g., "tomorrow 08:00")
              else if (fields['reminderTime'] != null &&
                  fields['reminderTime'] is String) {
                final reminderTimeStr = fields['reminderTime'] as String;
                final now = DateTime.now();

                // Parse reminder time string like "tomorrow 11:00" or "today 9:30"
                if (reminderTimeStr.toLowerCase().contains('tomorrow')) {
                  // Extract time from "tomorrow 11:00" format
                  final timeMatch = RegExp(
                    r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
                    caseSensitive: false,
                  ).firstMatch(reminderTimeStr);
                  if (timeMatch != null) {
                    int hour = int.parse(timeMatch.group(1)!);
                    int minute = timeMatch.group(2) != null
                        ? int.parse(timeMatch.group(2)!)
                        : 0;
                    final ampm = timeMatch.group(3)?.toLowerCase();
                    if (ampm == 'pm' && hour < 12) hour += 12;
                    if (ampm == 'am' && hour == 12) hour = 0;

                    final tomorrow = now.add(Duration(days: 1));
                    reminderTime = DateTime(
                      tomorrow.year,
                      tomorrow.month,
                      tomorrow.day,
                      hour,
                      minute,
                    );
                  } else {
                    // No time specified, set to tomorrow at 9 AM
                    final tomorrow = now.add(Duration(days: 1));
                    reminderTime = DateTime(
                      tomorrow.year,
                      tomorrow.month,
                      tomorrow.day,
                      9,
                      0,
                    );
                  }
                } else if (reminderTimeStr.toLowerCase().contains('today')) {
                  // Extract time from "today 11:00" format
                  final timeMatch = RegExp(
                    r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
                    caseSensitive: false,
                  ).firstMatch(reminderTimeStr);
                  if (timeMatch != null) {
                    int hour = int.parse(timeMatch.group(1)!);
                    int minute = timeMatch.group(2) != null
                        ? int.parse(timeMatch.group(2)!)
                        : 0;
                    final ampm = timeMatch.group(3)?.toLowerCase();
                    if (ampm == 'pm' && hour < 12) hour += 12;
                    if (ampm == 'am' && hour == 12) hour = 0;

                    reminderTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      hour,
                      minute,
                    );
                  } else {
                    // No time specified, set to today at 9 AM
                    reminderTime = DateTime(now.year, now.month, now.day, 9, 0);
                  }
                } else {
                  // Try to parse as date/time string
                  reminderTime = DateTime.tryParse(reminderTimeStr) ?? now;
                }
              }
              // Create reminder and show confirmation instead of opening modal directly

              // Handle reminder advance timing
              DateTime finalReminderTime = reminderTime;
              if (reminderAdvance.isNotEmpty) {
                if (reminderAdvance.contains('15 minutes before')) {
                  finalReminderTime = reminderTime.subtract(
                    Duration(minutes: 15),
                  );
                } else if (reminderAdvance.contains('30 minutes before') ||
                    reminderAdvance.contains('half an hour before')) {
                  finalReminderTime = reminderTime.subtract(
                    Duration(minutes: 30),
                  );
                } else if (reminderAdvance.contains('1 hour before') ||
                    reminderAdvance.contains('one hour before')) {
                  finalReminderTime = reminderTime.subtract(Duration(hours: 1));
                } else if (reminderAdvance.contains('2 hours before')) {
                  finalReminderTime = reminderTime.subtract(Duration(hours: 2));
                } else if (reminderAdvance.contains('1 day before')) {
                  finalReminderTime = reminderTime.subtract(Duration(days: 1));
                } else if (reminderAdvance.contains('5 minutes before')) {
                  finalReminderTime = reminderTime.subtract(
                    Duration(minutes: 5),
                  );
                } else if (reminderAdvance.contains('20 minutes before')) {
                  finalReminderTime = reminderTime.subtract(
                    Duration(minutes: 20),
                  );
                }
              }

              // Handle repeat functionality
              RecurrenceType recurrenceType = RecurrenceType.none;
              List<int>? customDays;
              int? interval;
              DateTime? endDate;

              if (fields['repeatType'] != null) {
                final repeatType = fields['repeatType'] as String;
                switch (repeatType) {
                  case 'daily':
                    recurrenceType = RecurrenceType.daily;
                    break;
                  case 'weekly':
                    recurrenceType = RecurrenceType.weekly;
                    break;
                  case 'monthly':
                    recurrenceType = RecurrenceType.monthly;
                    break;
                  case 'everyNDays':
                    recurrenceType = RecurrenceType.everyNDays;
                    interval = fields['repeatInterval'] as int? ?? 1;
                    break;
                  case 'everyNWeeks':
                    recurrenceType = RecurrenceType.everyNWeeks;
                    interval = fields['repeatInterval'] as int? ?? 1;
                    break;
                  case 'everyNMonths':
                    recurrenceType = RecurrenceType.everyNMonths;
                    interval = fields['repeatInterval'] as int? ?? 1;
                    break;
                  case 'custom':
                    recurrenceType = RecurrenceType.custom;
                    if (fields['repeatDays'] != null) {
                      customDays = List<int>.from(fields['repeatDays']);
                    }
                    break;
                }

                // Handle end date
                if (fields['repeatEndDate'] != null) {
                  final endDateStr = fields['repeatEndDate'] as String;
                  endDate = DateTime.tryParse(endDateStr);
                }
              }

              final reminder = Reminder(
                title: title,
                description: description.isNotEmpty ? description : null,
                reminderTime: finalReminderTime,
                timestamp: DateTime.now(),
                advanceTiming:
                    fields['reminderAdvance'] != null &&
                        (fields['reminderAdvance'] as String).isNotEmpty
                    ? fields['reminderAdvance'] as String
                    : null,
                recurrenceType: recurrenceType,
                customDays: customDays,
                interval: interval,
                endDate: endDate,
              );
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: _getConfirmationMessage(reminder),
                    isUser: false,
                    timestamp: DateTime.now(),
                    isConfirmation: true,
                    onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                        _handleLogConfirmation(confirmed, updatedLogEntry),
                    pendingLogEntry: reminder,
                    canConfirm: true,
                    showEdit: true,
                  ),
                );
                _isLoading = false; // Stop loading
              });
              _scrollToBottom();
              return;
            }
            // Add more intents as needed
          }
        }
      });
    } catch (e) {
      print('DEBUG: Exception in AI processing: $e');

      setState(() {
        // Remove loading message
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          _messages.removeLast();
        }

        _messages.add(
          _ChatMessage(
            text:
                "❌ Sorry, I'm having trouble right now. Please try again in a moment.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Helper methods to convert AI response Map to app models
  Reminder? _mapToReminder(Map data) {
    final title = data['title'] ?? '';
    final dateStr = data['date'] ?? '';
    final timeStr = data['time'] ?? '';
    DateTime reminderTime = DateTime.now();
    // Parse date and time if possible
    // (Add more robust parsing as needed)
    if (dateStr.isNotEmpty || timeStr.isNotEmpty) {
      // Simple parsing: try to combine date and time
      final now = DateTime.now();
      DateTime? date;
      if (dateStr.toLowerCase() == 'tomorrow') {
        date = now.add(Duration(days: 1));
      } else if (dateStr.toLowerCase() == 'today') {
        date = now;
      }
      // Add more date parsing as needed
      int hour = 0;
      int minute = 0;
      if (timeStr.isNotEmpty) {
        final timeMatch = RegExp(
          r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
          caseSensitive: false,
        ).firstMatch(timeStr);
        if (timeMatch != null) {
          hour = int.parse(timeMatch.group(1)!);
          minute = timeMatch.group(2) != null
              ? int.parse(timeMatch.group(2)!)
              : 0;
          final ampm = timeMatch.group(3)?.toLowerCase();
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
        }
      }
      if (date != null) {
        reminderTime = DateTime(date.year, date.month, date.day, hour, minute);
      } else {
        reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      }
    }
    return Reminder(
      title: title,
      reminderTime: reminderTime,
      timestamp: DateTime.now(),
    );
  }

  Task? _mapToTask(Map data) {
    final title = data['title'] ?? '';
    return Task(title: title, timestamp: DateTime.now());
  }

  Expense? _mapToExpense(Map data) {
    final title = data['title'] ?? '';
    // You may want to parse amount from title or add an 'amount' field to the AI prompt
    return Expense(category: title, amount: 0, timestamp: DateTime.now());
  }

  Note? _mapToNote(Map data) {
    final title = data['title'] ?? '';
    return Note(id: NotesService.generateId(), title: title, content: title);
  }

  GymLog? _mapToGymLog(Map data) {
    final title = data['title'] ?? '';
    return GymLog(
      workoutName: title,
      exercises: [Exercise(name: title, sets: 0, reps: 0)],
      timestamp: DateTime.now(),
    );
  }

  // Helper method to validate if a log entry has all required fields
  bool _hasRequiredFields(LogEntry logEntry) {
    switch (logEntry.logType) {
      case 'task':
        final task = logEntry as Task;
        // Tasks require: title, dueDate, AND a specific time
        final hasTitle = task.title.isNotEmpty;
        final hasDueDate = task.dueDate != null;
        final hasTime =
            (task.timeOfDay != null) ||
            (task.dueDate != null &&
                (task.dueDate!.hour != 0 || task.dueDate!.minute != 0));

        print('DEBUG: _hasRequiredFields - task validation:');
        print('DEBUG: _hasRequiredFields - title: "$hasTitle" (${task.title})');
        print(
          'DEBUG: _hasRequiredFields - dueDate: $hasDueDate (${task.dueDate})',
        );
        print('DEBUG: _hasRequiredFields - timeOfDay: ${task.timeOfDay}');
        print('DEBUG: _hasRequiredFields - hasTime: $hasTime');

        return hasTitle && hasDueDate && hasTime;
      case 'reminder':
        final reminder = logEntry as Reminder;
        // Reminders require: title and a specific time (not 00:00)
        return reminder.title.isNotEmpty &&
            (reminder.reminderTime.hour != 0 ||
                reminder.reminderTime.minute != 0);
      case 'expense':
        final expense = logEntry as Expense;
        // Expenses require: amount > 0 and category
        return expense.amount > 0 && expense.category.isNotEmpty;
      case 'note':
        final note = logEntry as Note;
        // Notes require: content
        return note.content.isNotEmpty;
      case 'gym':
        final gymLog = logEntry as GymLog;
        // Gym logs require: at least one exercise with name
        return gymLog.exercises.isNotEmpty &&
            gymLog.exercises.first.name.isNotEmpty;
      default:
        return true; // Default to allowing confirmation
    }
  }

  String _getConfirmationMessage(LogEntry logEntry) {
    switch (logEntry.logType) {
      case 'expense':
        final expense = logEntry as Expense;
        StringBuffer message = StringBuffer();
        message.writeln("Log an expense for:");
        message.writeln("📋 ${expense.category}");
        message.writeln("💰 Amount: £${expense.amount.toStringAsFixed(2)}");
        message.writeln("🏷️ Category: ${expense.category}");

        // Date
        final date = expense.timestamp;
        final dateString =
            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        message.writeln("📅 Date: $dateString");

        return message.toString();

      case 'task':
        final task = logEntry as Task;
        // Debug: Print task details
        print(
          'DEBUG: Task confirmation - priority: ${task.priority}, reminder: ${task.reminder}',
        );
        StringBuffer message = StringBuffer();
        message.writeln("Create a task for:");
        message.writeln("📋 ${task.title}");

        // Date and time
        if (task.dueDate != null) {
          final date = task.dueDate!;
          final now = DateTime.now();
          bool hasSpecificTime =
              (task.dueDate!.hour != 0 || task.dueDate!.minute != 0) ||
              (task.timeOfDay != null);

          if (hasSpecificTime) {
            DateTime displayDateTime;
            if (task.timeOfDay != null) {
              displayDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              );
            } else {
              displayDateTime = date;
            }
            final timeString = _formatReminderTime(displayDateTime);
            message.writeln("📅 $timeString");
          } else {
            if (date.year != now.year ||
                date.month != now.month ||
                date.day != now.day) {
              final dateString =
                  "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              message.writeln("📅 $dateString (no time set)");
            } else {
              message.writeln("📅 —");
            }
          }
        } else {
          message.writeln("📅 —");
        }

        // Description
        if (task.description != null && task.description!.isNotEmpty) {
          String truncatedDescription = task.description!;
          if (truncatedDescription.length > 25) {
            truncatedDescription =
                "${truncatedDescription.substring(0, 22)}...";
          }
          message.writeln("📝 Description: $truncatedDescription");
        } else {
          message.writeln("📝 Description: —");
        }

        // Reminder
        if (task.reminder != ReminderType.none) {
          String reminderText = "";
          switch (task.reminder) {
            case ReminderType.fifteenMinutes:
              reminderText = "15 minutes before";
              break;
            case ReminderType.oneHour:
              reminderText = "1 hour before";
              break;
            case ReminderType.oneDay:
              reminderText = "1 day before";
              break;
            case ReminderType.fiveMinutes:
              reminderText = "5 minutes before";
              break;
            case ReminderType.twentyMinutes:
              reminderText = "20 minutes before";
              break;
            case ReminderType.thirtyMinutes:
              reminderText = "30 minutes before";
              break;
            case ReminderType.twoHours:
              reminderText = "2 hours before";
              break;
            default:
              reminderText = "—";
          }
          message.writeln("⏰ Reminder: $reminderText");
        } else {
          message.writeln("⏰ Reminder: —");
        }

        // Category
        message.writeln("🏷️ Category: ${task.category}");

        // Priority
        String priorityText = "";
        switch (task.priority) {
          case TaskPriority.high:
            priorityText = "High";
            break;
          case TaskPriority.medium:
            priorityText = "Medium";
            break;
          case TaskPriority.low:
            priorityText = "Low";
            break;
        }
        message.writeln("⭐ Priority: $priorityText");

        // Recurring
        if (task.recurrenceType.index != 0) {
          // 0 is 'none'
          String recurringText = "";

          // Check if we have duration info
          if (task.repeatDuration != null && task.repeatDurationType != null) {
            final duration = task.repeatDuration!;
            final durationType = task.repeatDurationType!;

            // Create duration message
            String durationMessage = '';
            if (duration == 1) {
              durationMessage =
                  '1 ${durationType.substring(0, durationType.length - 1)}'; // Remove 's' for singular
            } else {
              durationMessage = '$duration $durationType';
            }

            recurringText = durationMessage;
          } else {
            // No duration specified - infinite recurring task
            recurringText = "until further notice";
          }

          message.writeln(" Repeat: $recurringText");
        } else {
          message.writeln(" Repeat: —");
        }

        return message.toString();

      case 'reminder':
        final reminder = logEntry as Reminder;
        StringBuffer message = StringBuffer();
        message.writeln("Create a reminder for:");
        message.writeln("📋 ${reminder.title}");

        // Date and time
        if (reminder.reminderTime.hour == 0 &&
            reminder.reminderTime.minute == 0) {
          final date = reminder.reminderTime;
          final now = DateTime.now();
          if (date.year != now.year ||
              date.month != now.month ||
              date.day != now.day) {
            final dateString =
                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            message.writeln("📅 $dateString (no time set)");
          } else {
            message.writeln("📅 —");
          }
        } else {
          final timeString = _formatReminderTime(reminder.reminderTime);
          message.writeln("📅 $timeString");
        }

        // Advance timing
        if (reminder.advanceTiming != null) {
          message.writeln("⏰ Advance: ${reminder.advanceTiming}");
        } else {
          message.writeln("⏰ Advance: —");
        }

        // Description
        if (reminder.description != null && reminder.description!.isNotEmpty) {
          String truncatedDescription = reminder.description!;
          if (truncatedDescription.length > 25) {
            truncatedDescription =
                "${truncatedDescription.substring(0, 22)}...";
          }
          message.writeln("📝 Description: $truncatedDescription");
        } else {
          message.writeln("📝 Description: —");
        }

        // Repeat information
        if (reminder.recurrenceType != RecurrenceType.none) {
          String repeatText = "";

          // Check if we have duration info
          if (reminder.repeatDuration != null &&
              reminder.repeatDurationType != null) {
            final duration = reminder.repeatDuration!;
            final durationType = reminder.repeatDurationType!;

            // Create duration message
            String durationMessage = '';
            if (duration == 1) {
              durationMessage =
                  '1 ${durationType.substring(0, durationType.length - 1)}'; // Remove 's' for singular
            } else {
              durationMessage = '$duration $durationType';
            }

            repeatText = durationMessage;
          } else {
            // No duration specified - infinite recurring reminder
            repeatText = "until further notice";
          }

          message.writeln("🔄 Repeat: $repeatText");
        } else {
          message.writeln("🔄 Repeat: —");
        }

        return message.toString();

      case 'note':
        final note = logEntry as Note;
        StringBuffer message = StringBuffer();
        message.writeln("Create a note for:");
        message.writeln("📋 ${note.title}");

        // Type
        String typeText = "";
        switch (note.type) {
          case NoteType.text:
            typeText = "Text";
            break;
          case NoteType.checklist:
            typeText = "Checklist";
            break;
          case NoteType.media:
            typeText = "Media";
            break;
          case NoteType.quick:
            typeText = "Quick";
            break;
          case NoteType.linked:
            typeText = "Linked";
            break;
        }
        message.writeln("📄 Type: $typeText");

        // Category
        message.writeln("🏷️ Category: ${note.noteCategory}");

        // Priority
        String priorityText = "";
        switch (note.priority) {
          case NotePriority.high:
            priorityText = "High";
            break;
          case NotePriority.medium:
            priorityText = "Medium";
            break;
          case NotePriority.low:
            priorityText = "Low";
            break;
        }
        message.writeln("⭐ Priority: $priorityText");

        // Status
        String statusText = "";
        switch (note.status) {
          case NoteStatus.draft:
            statusText = "Draft";
            break;
          case NoteStatus.final_:
            statusText = "Final";
            break;
          case NoteStatus.archived:
            statusText = "Archived";
            break;
        }
        message.writeln("📊 Status: $statusText");

        return message.toString();

      case 'gym':
        final gymLog = logEntry as GymLog;
        StringBuffer message = StringBuffer();
        message.writeln("Log a workout for:");
        message.writeln("📋 ${gymLog.exercises.first.name}");

        // Sets and reps
        final exercise = gymLog.exercises.first;
        message.writeln("💪 Sets: ${exercise.sets} | Reps: ${exercise.reps}");

        // Weight
        if (exercise.weight != null) {
          message.writeln("🏋️ Weight: ${exercise.weight}kg");
        } else {
          message.writeln("🏋️ Weight: —");
        }

        // Date
        final date = gymLog.timestamp;
        final dateString =
            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        message.writeln("📅 Date: $dateString");

        return message.toString();

      default:
        return "Log this entry?";
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays == 1 ? '' : 's'} from now";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} from now";
    } else {
      return "in ${difference.inMinutes} minutes";
    }
  }

  String _formatReminderTime(DateTime time) {
    // UK format: Wed, 17 Jul at 18:00
    const List<String> weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[time.weekday - 1];
    final day = time.day.toString().padLeft(2, '0');
    final month = months[time.month - 1];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute';
    return "$weekday, $day $month at $timeString";
  }

  String _formatReminderDate(DateTime time) {
    // UK format: Mon, 22 Jul
    const List<String> weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[time.weekday - 1];
    final day = time.day.toString().padLeft(2, '0');
    final month = months[time.month - 1];
    return '$weekday, $day $month';
  }

  void _handleEditReminder(BuildContext context, LogEntry? logEntry) async {
    if (logEntry == null || logEntry.logType != 'reminder') return;
    final updated = await showReminderEditModal(
      context,
      initial: logEntry as Reminder,
    );
    if (updated is Reminder) {
      setState(() {
        // Remove any previous confirmation bubbles for this reminder
        _messages.removeWhere(
          (m) => m.isConfirmation && m.pendingLogEntry?.logType == 'reminder',
        );
        _messages.add(
          _ChatMessage(
            text: _getConfirmationMessage(updated),
            isUser: false,
            timestamp: DateTime.now(),
            isConfirmation: true,
            onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                _handleLogConfirmation(confirmed, updatedLogEntry ?? updated),
            pendingLogEntry: updated,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleReminderQuery(String timeframe) async {
    try {
      // Get all reminders from the service
      final allReminders = await RemindersService.loadReminders();
      print('DEBUG: _handleReminderQuery - timeframe: $timeframe');
      print(
        'DEBUG: _handleReminderQuery - allReminders count: ${allReminders.length}',
      );
      print(
        'DEBUG: _handleReminderQuery - allReminders: ${allReminders.map((r) => '${r.title} (${r.reminderTime})').toList()}',
      );

      List<Reminder> filteredReminders = [];

      // Filter reminders based on timeframe
      if (timeframe == 'this week') {
        final now = DateTime.now();

        // Smart context-aware logic: If today is Sunday, "this week" = just today
        // If today is Monday-Saturday, "this week" = full week (Monday-Sunday)
        if (now.weekday == 7) {
          // Sunday
          // Show only today's reminders
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(Duration(days: 1));

          print('DEBUG: this week filtering (Sunday) - now: $now');
          print('DEBUG: this week filtering (Sunday) - today: $today');
          print('DEBUG: this week filtering (Sunday) - tomorrow: $tomorrow');

          filteredReminders = allReminders.where((reminder) {
            final isInRange =
                reminder.reminderTime.isAfter(
                  today.subtract(Duration(seconds: 1)),
                ) &&
                reminder.reminderTime.isBefore(tomorrow);
            print(
              'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: this week filteredReminders count (Sunday): ${filteredReminders.length}',
          );
        } else {
          // Show full week (Monday-Sunday)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));

          print('DEBUG: this week filtering (full week) - now: $now');
          print(
            'DEBUG: this week filtering (full week) - startOfWeek: $startOfWeek',
          );
          print(
            'DEBUG: this week filtering (full week) - endOfWeek: $endOfWeek',
          );

          filteredReminders = allReminders.where((reminder) {
            final isInRange =
                reminder.reminderTime.isAfter(
                  startOfWeek.subtract(Duration(seconds: 1)),
                ) &&
                reminder.reminderTime.isBefore(
                  endOfWeek.add(Duration(days: 1)),
                );
            print(
              'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: this week filteredReminders count (full week): ${filteredReminders.length}',
          );
        }
      } else if (timeframe == 'next week' ||
          timeframe == 'following week' ||
          timeframe == 'upcoming week') {
        final now = DateTime.now();
        // Calculate start of next week (Monday) - set to beginning of day
        final daysToNextMonday = 8 - now.weekday;
        final nextMonday = DateTime(
          now.year,
          now.month,
          now.day + daysToNextMonday,
        );
        final endOfNextWeek = nextMonday.add(Duration(days: 6));

        print('DEBUG: next week filtering - now: $now');
        print('DEBUG: next week filtering - nextMonday: $nextMonday');
        print('DEBUG: next week filtering - endOfNextWeek: $endOfNextWeek');

        filteredReminders = allReminders.where((reminder) {
          final isInRange =
              reminder.reminderTime.isAfter(
                nextMonday.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(
                endOfNextWeek.add(Duration(days: 1)),
              );
          print(
            'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print(
          'DEBUG: next week filteredReminders count: ${filteredReminders.length}',
        );
      } else if (timeframe.startsWith('next ') && timeframe.contains('week')) {
        // Handle "next X weeks" format
        final weekMatch = RegExp(r'next (\d+) weeks?').firstMatch(timeframe);
        if (weekMatch != null) {
          final weeks = int.parse(weekMatch.group(1)!);
          final now = DateTime.now();
          final startDate = now.add(Duration(days: 1)); // Start from tomorrow
          final endDate = startDate.add(
            Duration(days: weeks * 7 - 1),
          ); // X weeks from start

          print('DEBUG: next X weeks filtering - weeks: $weeks');
          print('DEBUG: next X weeks filtering - startDate: $startDate');
          print('DEBUG: next X weeks filtering - endDate: $endDate');

          filteredReminders = allReminders.where((reminder) {
            final isInRange =
                reminder.reminderTime.isAfter(
                  startDate.subtract(Duration(seconds: 1)),
                ) &&
                reminder.reminderTime.isBefore(endDate.add(Duration(days: 1)));
            print(
              'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: next X weeks filteredReminders count: ${filteredReminders.length}',
          );
        } else {
          // Fallback to next week if parsing fails
          final now = DateTime.now();
          final startOfNextWeek = now.add(Duration(days: 8 - now.weekday));
          final endOfNextWeek = startOfNextWeek.add(Duration(days: 6));

          filteredReminders = allReminders.where((reminder) {
            return reminder.reminderTime.isAfter(
                  startOfNextWeek.subtract(Duration(days: 1)),
                ) &&
                reminder.reminderTime.isBefore(
                  endOfNextWeek.add(Duration(days: 1)),
                );
          }).toList();
        }
      } else if (timeframe == 'this month' || timeframe == 'current month') {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        print('DEBUG: this month filtering - now: $now');
        print('DEBUG: this month filtering - startOfMonth: $startOfMonth');
        print('DEBUG: this month filtering - endOfMonth: $endOfMonth');

        filteredReminders = allReminders.where((reminder) {
          final isInRange =
              reminder.reminderTime.isAfter(
                startOfMonth.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(endOfMonth.add(Duration(days: 1)));
          print(
            'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print(
          'DEBUG: this month filteredReminders count: ${filteredReminders.length}',
        );
      } else if (timeframe == 'next month' ||
          timeframe == 'following month' ||
          timeframe == 'upcoming month') {
        final now = DateTime.now();
        final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
        final endOfNextMonth = DateTime(
          now.year,
          now.month + 2,
          1,
        ).subtract(Duration(days: 1));

        print('DEBUG: next month filtering - now: $now');
        print(
          'DEBUG: next month filtering - startOfNextMonth: $startOfNextMonth',
        );
        print('DEBUG: next month filtering - endOfNextMonth: $endOfNextMonth');

        filteredReminders = allReminders.where((reminder) {
          final isInRange =
              reminder.reminderTime.isAfter(
                startOfNextMonth.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(
                endOfNextMonth.add(Duration(days: 1)),
              );
          print(
            'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print(
          'DEBUG: next month filteredReminders count: ${filteredReminders.length}',
        );
      } else if (timeframe == 'today') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(Duration(days: 1));

        print('DEBUG: today filtering - now: $now');
        print('DEBUG: today filtering - today: $today');
        print('DEBUG: today filtering - tomorrow: $tomorrow');

        filteredReminders = allReminders.where((reminder) {
          final isInRange =
              reminder.reminderTime.isAfter(
                today.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(tomorrow);
          print(
            'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print(
          'DEBUG: today filteredReminders count: ${filteredReminders.length}',
        );
      } else if (timeframe == 'tomorrow') {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final dayAfterTomorrow = tomorrow.add(Duration(days: 1));

        print('DEBUG: tomorrow filtering - now: $now');
        print('DEBUG: tomorrow filtering - tomorrow: $tomorrow');
        print(
          'DEBUG: tomorrow filtering - dayAfterTomorrow: $dayAfterTomorrow',
        );

        filteredReminders = allReminders.where((reminder) {
          final isInRange =
              reminder.reminderTime.isAfter(
                tomorrow.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(dayAfterTomorrow);
          print(
            'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print(
          'DEBUG: tomorrow filteredReminders count: ${filteredReminders.length}',
        );
      } else if (timeframe.startsWith('this ') ||
          timeframe.startsWith('next ')) {
        // Handle day-of-week queries like "this Monday", "next Tuesday"
        final now = DateTime.now();
        String targetDay = '';
        bool isNextWeek = false;

        if (timeframe.startsWith('this ')) {
          targetDay = timeframe.substring(5); // Remove "this "
        } else if (timeframe.startsWith('next ')) {
          targetDay = timeframe.substring(5); // Remove "next "
          isNextWeek = true;
        }

        print(
          'DEBUG: task day-of-week filtering - targetDay: $targetDay, isNextWeek: $isNextWeek',
        );

        // Convert day name to weekday number (1=Monday, 7=Sunday)
        int targetWeekday = 0;
        switch (targetDay.toLowerCase()) {
          case 'monday':
            targetWeekday = 1;
            break;
          case 'tuesday':
            targetWeekday = 2;
            break;
          case 'wednesday':
            targetWeekday = 3;
            break;
          case 'thursday':
            targetWeekday = 4;
            break;
          case 'friday':
            targetWeekday = 5;
            break;
          case 'saturday':
            targetWeekday = 6;
            break;
          case 'sunday':
            targetWeekday = 7;
            break;
        }

        if (targetWeekday > 0) {
          final currentWeekday = now.weekday;
          int daysToAdd = 0;

          if (isNextWeek) {
            // Next week: calculate days to next occurrence of target day
            daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
            if (daysToAdd == 0) {
              daysToAdd = 7; // If it's the same day, go to next week
            }
          } else {
            // This week: calculate days to next occurrence of target day
            daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
          }

          final targetDate = DateTime(now.year, now.month, now.day + daysToAdd);
          final nextDay = targetDate.add(Duration(days: 1));

          print('DEBUG: task day-of-week filtering - targetDate: $targetDate');
          print('DEBUG: task day-of-week filtering - nextDay: $nextDay');

          filteredReminders = allReminders.where((reminder) {
            final isInRange =
                reminder.reminderTime.isAfter(
                  targetDate.subtract(Duration(seconds: 1)),
                ) &&
                reminder.reminderTime.isBefore(nextDay);
            print(
              'DEBUG: reminder ${reminder.title} (${reminder.reminderTime}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: day-of-week filteredReminders count: ${filteredReminders.length}',
          );
        } else {
          // Invalid day name, show all reminders
          filteredReminders = allReminders;
        }
      } else {
        // Show all reminders (for "all" timeframe)
        filteredReminders = allReminders;
      }

      // Sort reminders by time
      filteredReminders.sort(
        (a, b) => a.reminderTime.compareTo(b.reminderTime),
      );

      setState(() {
        // Remove loading message if it exists
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          _messages.removeLast();
        }

        // Add header message
        if (filteredReminders.isEmpty) {
          _messages.add(
            _ChatMessage(
              text:
                  "📅 No reminders found for ${timeframe == 'all' ? 'any time' : timeframe}.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          // Add header message
          _messages.add(
            _ChatMessage(
              text:
                  "📅 Reminders for <b>${timeframe == 'all' ? 'all time' : timeframe}</b>:",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );

          // Add individual reminder bubbles
          for (final reminder in filteredReminders) {
            _messages.add(
              _ChatMessage(
                text: "", // Empty text since we'll use custom widget
                isUser: false,
                timestamp: DateTime.now(),
                customWidget: _ReminderBubble(
                  reminder: reminder,
                  onEdit: () async {
                    final edited = await showReminderEditModal(
                      context,
                      initial: reminder,
                    );
                    if (edited != null) {
                      await RemindersService.updateReminder(edited);
                      // Refresh the reminder list
                      _handleReminderQuery(timeframe);
                    }
                  },
                  onDelete: () async {
                    await RemindersService.deleteReminder(reminder);
                    // Refresh the reminder list
                    _handleReminderQuery(timeframe);
                  },
                ),
              ),
            );
          }
        }
        _isLoading = false; // Stop loading
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        // Remove loading message if it exists
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          _messages.removeLast();
        }
        _messages.add(
          _ChatMessage(
            text: "❌ Error loading reminders: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false; // Stop loading
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleTaskQuery(String timeframe) async {
    try {
      // Get all tasks from the callback
      final allTasks = widget.getTasks?.call() ?? [];
      print('DEBUG: _handleTaskQuery - timeframe: $timeframe');
      print('DEBUG: _handleTaskQuery - allTasks count: ${allTasks.length}');
      print(
        'DEBUG: _handleTaskQuery - allTasks: ${allTasks.map((t) => '${t.title} (${t.dueDate})').toList()}',
      );
      List<Task> filteredTasks = [];

      // Filter tasks based on timeframe
      if (timeframe == 'this week') {
        final now = DateTime.now();

        // Smart context-aware logic: If today is Sunday, "this week" = just today
        // If today is Monday-Saturday, "this week" = full week (Monday-Sunday)
        if (now.weekday == 7) {
          // Sunday
          // Show only today's tasks
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(Duration(days: 1));

          print('DEBUG: this week filtering (Sunday) - now: $now');
          print('DEBUG: this week filtering (Sunday) - today: $today');
          print('DEBUG: this week filtering (Sunday) - tomorrow: $tomorrow');

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            final isInRange =
                task.dueDate!.isAfter(today.subtract(Duration(seconds: 1))) &&
                task.dueDate!.isBefore(tomorrow);
            print(
              'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: this week filteredTasks count (Sunday): ${filteredTasks.length}',
          );
        } else {
          // Show full week (Monday-Sunday)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));

          print('DEBUG: this week filtering (full week) - now: $now');
          print(
            'DEBUG: this week filtering (full week) - startOfWeek: $startOfWeek',
          );
          print(
            'DEBUG: this week filtering (full week) - endOfWeek: $endOfWeek',
          );

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            final isInRange =
                task.dueDate!.isAfter(
                  startOfWeek.subtract(Duration(seconds: 1)),
                ) &&
                task.dueDate!.isBefore(endOfWeek.add(Duration(days: 1)));
            print(
              'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: this week filteredTasks count (full week): ${filteredTasks.length}',
          );
        }
      } else if (timeframe == 'next week' ||
          timeframe == 'following week' ||
          timeframe == 'upcoming week') {
        final now = DateTime.now();
        // Calculate start of next week (Monday) - set to beginning of day
        final daysToNextMonday = 8 - now.weekday;
        final nextMonday = DateTime(
          now.year,
          now.month,
          now.day + daysToNextMonday,
        );
        final endOfNextWeek = nextMonday.add(Duration(days: 6));

        print('DEBUG: next week filtering - now: $now');
        print('DEBUG: next week filtering - nextMonday: $nextMonday');
        print('DEBUG: next week filtering - endOfNextWeek: $endOfNextWeek');

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          final isInRange =
              task.dueDate!.isAfter(
                nextMonday.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfNextWeek.add(Duration(days: 1)));
          print(
            'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print('DEBUG: next week filteredTasks count: ${filteredTasks.length}');
      } else if (timeframe.startsWith('next ') && timeframe.contains('week')) {
        // Handle "next X weeks" format
        final weekMatch = RegExp(r'next (\d+) weeks?').firstMatch(timeframe);
        if (weekMatch != null) {
          final weeks = int.parse(weekMatch.group(1)!);
          final now = DateTime.now();
          final startDate = now.add(Duration(days: 1)); // Start from tomorrow
          final endDate = startDate.add(
            Duration(days: weeks * 7 - 1),
          ); // X weeks from start

          print('DEBUG: next X weeks filtering - weeks: $weeks');
          print('DEBUG: next X weeks filtering - startDate: $startDate');
          print('DEBUG: next X weeks filtering - endDate: $endDate');

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            final isInRange =
                task.dueDate!.isAfter(
                  startDate.subtract(Duration(seconds: 1)),
                ) &&
                task.dueDate!.isBefore(endDate.add(Duration(days: 1)));
            print(
              'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: next X weeks filteredTasks count: ${filteredTasks.length}',
          );
        } else {
          // Fallback to next week if parsing fails
          final now = DateTime.now();
          final startOfNextWeek = now.add(Duration(days: 8 - now.weekday));
          final endOfNextWeek = startOfNextWeek.add(Duration(days: 6));

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            return task.dueDate!.isAfter(
                  startOfNextWeek.subtract(Duration(days: 1)),
                ) &&
                task.dueDate!.isBefore(endOfNextWeek.add(Duration(days: 1)));
          }).toList();
        }
      } else if (timeframe == 'this month' || timeframe == 'current month') {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        print('DEBUG: this month filtering - now: $now');
        print('DEBUG: this month filtering - startOfMonth: $startOfMonth');
        print('DEBUG: this month filtering - endOfMonth: $endOfMonth');

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          final isInRange =
              task.dueDate!.isAfter(
                startOfMonth.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfMonth.add(Duration(days: 1)));
          print(
            'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print('DEBUG: this month filteredTasks count: ${filteredTasks.length}');
      } else if (timeframe == 'next month' ||
          timeframe == 'following month' ||
          timeframe == 'upcoming month') {
        final now = DateTime.now();
        final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
        final endOfNextMonth = DateTime(
          now.year,
          now.month + 2,
          1,
        ).subtract(Duration(days: 1));

        print('DEBUG: next month filtering - now: $now');
        print(
          'DEBUG: next month filtering - startOfNextMonth: $startOfNextMonth',
        );
        print('DEBUG: next month filtering - endOfNextMonth: $endOfNextMonth');

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          final isInRange =
              task.dueDate!.isAfter(
                startOfNextMonth.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfNextMonth.add(Duration(days: 1)));
          print(
            'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print('DEBUG: next month filteredTasks count: ${filteredTasks.length}');
      } else if (timeframe == 'today') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(Duration(days: 1));

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(today.subtract(Duration(seconds: 1))) &&
              task.dueDate!.isBefore(tomorrow);
        }).toList();
      } else if (timeframe == 'tomorrow') {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final dayAfterTomorrow = tomorrow.add(Duration(days: 1));

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(
                tomorrow.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(dayAfterTomorrow);
        }).toList();
      } else if (timeframe.startsWith('this ') ||
          timeframe.startsWith('next ')) {
        // Handle day-of-week queries like "this Monday", "next Tuesday"
        final now = DateTime.now();
        String targetDay = '';
        bool isNextWeek = false;

        if (timeframe.startsWith('this ')) {
          targetDay = timeframe.substring(5); // Remove "this "
        } else if (timeframe.startsWith('next ')) {
          targetDay = timeframe.substring(5); // Remove "next "
          isNextWeek = true;
        }

        print(
          'DEBUG: task day-of-week filtering - targetDay: $targetDay, isNextWeek: $isNextWeek',
        );

        // Convert day name to weekday number (1=Monday, 7=Sunday)
        int targetWeekday = 0;
        switch (targetDay.toLowerCase()) {
          case 'monday':
            targetWeekday = 1;
            break;
          case 'tuesday':
            targetWeekday = 2;
            break;
          case 'wednesday':
            targetWeekday = 3;
            break;
          case 'thursday':
            targetWeekday = 4;
            break;
          case 'friday':
            targetWeekday = 5;
            break;
          case 'saturday':
            targetWeekday = 6;
            break;
          case 'sunday':
            targetWeekday = 7;
            break;
        }

        if (targetWeekday > 0) {
          final currentWeekday = now.weekday;
          int daysToAdd = 0;

          if (isNextWeek) {
            // Next week: calculate days to next occurrence of target day
            daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
            if (daysToAdd == 0) {
              daysToAdd = 7; // If it's the same day, go to next week
            }
          } else {
            // This week: calculate days to next occurrence of target day
            daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
          }

          final targetDate = DateTime(now.year, now.month, now.day + daysToAdd);
          final nextDay = targetDate.add(Duration(days: 1));

          print('DEBUG: task day-of-week filtering - targetDate: $targetDate');
          print('DEBUG: task day-of-week filtering - nextDay: $nextDay');

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            final isInRange =
                task.dueDate!.isAfter(
                  targetDate.subtract(Duration(seconds: 1)),
                ) &&
                task.dueDate!.isBefore(nextDay);
            print(
              'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
            );
            return isInRange;
          }).toList();

          print(
            'DEBUG: task day-of-week filteredTasks count: ${filteredTasks.length}',
          );
        } else {
          // Invalid day name, show all tasks
          filteredTasks = allTasks;
        }
      } else {
        // Show all tasks (for "all" timeframe)
        filteredTasks = allTasks;
      }

      // Sort tasks by due date
      filteredTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      setState(() {
        // Remove loading message if it exists
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          _messages.removeLast();
        }

        // Add header message
        if (filteredTasks.isEmpty) {
          _messages.add(
            _ChatMessage(
              text:
                  "📋 No tasks found for <b>${timeframe == 'all' ? 'any time' : timeframe}</b>.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          // Add header message
          _messages.add(
            _ChatMessage(
              text:
                  "📋 Tasks for <b>${timeframe == 'all' ? 'all time' : timeframe}</b>:",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );

          // Add individual task bubbles
          for (final task in filteredTasks) {
            _messages.add(
              _ChatMessage(
                text: "", // Empty text since we'll use custom widget
                isUser: false,
                timestamp: DateTime.now(),
                customWidget: _TaskBubble(
                  task: task,
                  onEdit: () async {
                    final edited = await showTaskModal(context, task: task);
                    if (edited != null) {
                      widget.onTaskLogged?.call(edited);
                      // Refresh the task list
                      _handleTaskQuery(timeframe);
                    }
                  },
                  onDelete: () async {
                    // Use the callback to delete the task
                    widget.onTaskLogged?.call(task);
                    // Refresh the task list
                    _handleTaskQuery(timeframe);
                  },
                ),
              ),
            );
          }
        }
        _isLoading = false; // Stop loading
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        // Remove loading message if it exists
        if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
          _messages.removeLast();
        }
        _messages.add(
          _ChatMessage(
            text: "❌ Error loading tasks: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false; // Stop loading
      });
      _scrollToBottom();
    }
  }

  void _handleLogConfirmation(
    bool confirmed, [
    LogEntry? updatedLogEntry,
  ]) async {
    print(
      'DEBUG: _handleLogConfirmation called with confirmed=$confirmed, updatedLogEntry=$updatedLogEntry',
    );
    final logEntry = updatedLogEntry ?? _pendingLog;
    print('DEBUG: logEntry in _handleLogConfirmation: $logEntry');
    // If user pressed Edit (confirmed == false && updatedLogEntry == null), open edit modal for reminders and tasks only
    if (!confirmed && updatedLogEntry == null && logEntry != null) {
      if (logEntry is Reminder) {
        print('DEBUG: Opening showReminderEditModal for $logEntry');
        final edited = await showReminderEditModal(context, initial: logEntry);
        print('DEBUG: showReminderEditModal returned $edited');
        if (edited != null) {
          setState(() {
            _messages.removeWhere(
              (m) =>
                  m.isConfirmation &&
                  m.pendingLogEntry?.logType == logEntry.logType,
            );
            _messages.add(
              _ChatMessage(
                text: _getConfirmationMessage(edited),
                isUser: false,
                timestamp: DateTime.now(),
                isConfirmation: true,
                onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                    _handleLogConfirmation(
                      confirmed,
                      updatedLogEntry ?? edited,
                    ),
                pendingLogEntry: edited,
              ),
            );
          });
          _scrollToBottom();
        }
        return;
      } else if (logEntry is Task) {
        print('DEBUG: Opening showTaskModal for $logEntry');
        final edited = await showTaskModal(context, task: logEntry);
        print('DEBUG: showTaskModal returned $edited');
        if (edited != null) {
          setState(() {
            _messages.removeWhere(
              (m) =>
                  m.isConfirmation &&
                  m.pendingLogEntry?.logType == logEntry.logType,
            );
            _messages.add(
              _ChatMessage(
                text: _getConfirmationMessage(edited),
                isUser: false,
                timestamp: DateTime.now(),
                isConfirmation: true,
                onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                    _handleLogConfirmation(
                      confirmed,
                      updatedLogEntry ?? edited,
                    ),
                pendingLogEntry: edited,
              ),
            );
          });
          _scrollToBottom();
        }
        return;
      }
      // For other log types, do nothing (no pop-up dialog)
      return;
    }
    if (confirmed && logEntry != null) {
      // Special handling for reminders: require a time and check for past time
      if (logEntry.logType == 'reminder') {
        final reminder = logEntry as Reminder;
        final now = DateTime.now();
        // If the time is midnight (00:00), treat as unset (user must set a time)
        if (reminder.reminderTime.hour == 0 &&
            reminder.reminderTime.minute == 0) {
          setState(() {
            _messages.removeWhere(
              (m) =>
                  m.isConfirmation && m.pendingLogEntry?.logType == 'reminder',
            );
            _messages.add(
              _ChatMessage(
                text: _getReminderTimeRequiredMessage(reminder),
                isUser: false,
                timestamp: DateTime.now(),
                isConfirmation: true,
                onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                    _handleLogConfirmation(
                      confirmed,
                      updatedLogEntry ?? reminder,
                    ),
                pendingLogEntry: reminder,
              ),
            );
          });
          _scrollToBottom();
          return;
        }
        // If the time is in the past, prompt the user to pick a future time
        if (reminder.reminderTime.isBefore(now)) {
          setState(() {
            _messages.removeWhere(
              (m) =>
                  m.isConfirmation && m.pendingLogEntry?.logType == 'reminder',
            );
            _messages.add(
              _ChatMessage(
                text: _getPastTimeWarningMessage(reminder),
                isUser: false,
                timestamp: DateTime.now(),
                isConfirmation: true,
                onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                    _handleLogConfirmation(
                      confirmed,
                      updatedLogEntry ?? reminder,
                    ),
                pendingLogEntry: reminder,
              ),
            );
          });
          _scrollToBottom();
          return;
        }
      }
      print('DEBUG: LogEntry type:  [1m${logEntry.logType} [0m');
      switch (logEntry.logType) {
        case 'expense':
          print('DEBUG: Calling onExpenseLogged');
          widget.onExpenseLogged?.call(logEntry as Expense);
          break;
        case 'task':
          final task = logEntry as Task;
          print('DEBUG: Calling onTaskLogged with task: ${task.toJson()}');
          print('DEBUG: Task title: ${task.title}');
          print('DEBUG: Task dueDate: ${task.dueDate}');
          print('DEBUG: Task timeOfDay: ${task.timeOfDay}');
          print('DEBUG: Task category: ${task.category}');
          print('DEBUG: Task recurrence: ${task.recurrenceType}');
          print(
            'DEBUG: Task duration: ${task.repeatDuration} ${task.repeatDurationType}',
          );

          // Always call onTaskLogged - let the main app handle recurring task generation
          widget.onTaskLogged?.call(task);
          break;
        case 'reminder':
          print(
            'DEBUG: Calling onReminderLogged with reminder: ${logEntry as Reminder}',
          );
          widget.onReminderLogged?.call(logEntry);
          break;
        case 'note':
          print('DEBUG: Calling onNoteLogged');
          widget.onNoteLogged?.call(logEntry as Note);
          break;
        case 'gym':
          print('DEBUG: Calling onGymLogLogged');
          widget.onGymLogLogged?.call(logEntry as GymLog);
          break;
      }
      setState(() {
        // Remove all confirmation bubbles for this log type
        _messages.removeWhere(
          (m) =>
              m.isConfirmation &&
              m.pendingLogEntry?.logType == logEntry.logType,
        );
        _messages.add(
          _ChatMessage(
            text: "✅ ${_getSuccessMessage(logEntry)}",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } else {
      setState(() {
        // Remove all confirmation bubbles for this log type
        _messages.removeWhere(
          (m) =>
              m.isConfirmation &&
              m.pendingLogEntry?.logType == _pendingLog?.logType,
        );
        _messages.add(
          _ChatMessage(
            text: _getCancelledMessage(logEntry),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
    _pendingLog = null;
  }

  String _getSuccessMessage(LogEntry logEntry) {
    switch (logEntry.logType) {
      case 'expense':
        final expense = logEntry as Expense;
        return "Expense logged: £${expense.amount.toStringAsFixed(2)} for ${expense.category}";
      case 'task':
        final task = logEntry as Task;

        // Check if this is a recurring task with duration
        if (task.repeatDuration != null && task.repeatDurationType != null) {
          // Create a more natural duration message
          String durationMessage = '';
          if (task.repeatDuration != null && task.repeatDurationType != null) {
            final duration = task.repeatDuration!;
            final durationType = task.repeatDurationType!;

            // Make it more natural: "6 weeks" instead of "for 6 weeks"
            if (duration == 1) {
              durationMessage =
                  '1 ${durationType.substring(0, durationType.length - 1)}'; // Remove 's' for singular
            } else {
              durationMessage = '$duration $durationType';
            }
          } else {
            // No duration specified - infinite recurring task
            durationMessage = 'until further notice';
          }

          if (task.dueDate != null && task.timeOfDay != null) {
            final timeString = _formatReminderTime(
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              ),
            );
            return "Recurring task created: ${task.title} (recurring for $durationMessage) starting <b>$timeString</b>";
          } else if (task.dueDate != null) {
            final dateString =
                "${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.year}";
            return "Recurring task created: ${task.title} (recurring for $durationMessage) starting <b>$dateString</b>";
          }
          return "Recurring task created: ${task.title} (recurring for $durationMessage)";
        }

        // Regular single task
        if (task.dueDate != null && task.timeOfDay != null) {
          final timeString = _formatReminderTime(
            DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
              task.timeOfDay!.hour,
              task.timeOfDay!.minute,
            ),
          );
          return "Task created: ${task.title} due <b>$timeString</b>";
        } else if (task.dueDate != null) {
          final dateString =
              "${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.year}";
          return "Task created: ${task.title} due <b>$dateString</b>";
        }
        return "Task created: ${task.title}";
      case 'reminder':
        final reminder = logEntry as Reminder;
        final dateTimeString = _formatReminderTime(reminder.reminderTime);
        String advanceInfo = '';
        if (reminder.advanceTiming != null) {
          advanceInfo = " with reminder ${reminder.advanceTiming}";
        }

        // Check if this is a recurring reminder with duration
        if (reminder.repeatDuration != null &&
            reminder.repeatDurationType != null) {
          final duration = reminder.repeatDuration!;
          final durationType = reminder.repeatDurationType!;

          // Create duration message
          String durationMessage = '';
          if (duration == 1) {
            durationMessage =
                '1 ${durationType.substring(0, durationType.length - 1)}'; // Remove 's' for singular
          } else {
            durationMessage = '$duration $durationType';
          }

          return "Recurring reminder set: ${reminder.title} (recurring for $durationMessage) on <b>$dateTimeString</b>$advanceInfo";
        } else if (reminder.recurrenceType != RecurrenceType.none) {
          // Infinite recurring reminder
          return "Recurring reminder set: ${reminder.title} (recurring until further notice) on <b>$dateTimeString</b>$advanceInfo";
        }

        return "Reminder set: ${reminder.title} on <b>$dateTimeString</b>$advanceInfo";
      case 'note':
        final note = logEntry as Note;
        return "Note saved: ${note.content}";
      case 'gym':
        final gymLog = logEntry as GymLog;
        final exercise = gymLog.exercises.first;
        return "Workout logged: ${exercise.name}";
      default:
        return "Entry logged successfully";
    }
  }

  String _getCancelledMessage(LogEntry? logEntry) {
    if (logEntry == null) return "❌ Entry cancelled";
    switch (logEntry.logType) {
      case 'expense':
        return "❌ Expense cancelled";
      case 'task':
        return "❌ Task cancelled";
      case 'reminder':
        return "❌ Reminder cancelled";
      case 'note':
        return "❌ Note cancelled";
      case 'gym':
        return "❌ Workout cancelled";
      default:
        return "❌ Entry cancelled";
    }
  }

  String _getNoRemindersMessage(String filter, int? day) {
    switch (filter) {
      case 'today':
        return "You don't have any reminders for <b>today</b>.";
      case 'week':
        return "You don't have any reminders for <b>this week</b>.";
      case 'day':
        return "You don't have any reminders for the <b>$day${_getDaySuffix(day)}</b>.";
      default:
        return "You don't have any reminders.";
    }
  }

  String _getRemindersListMessage(String filter, int? day) {
    switch (filter) {
      case 'today':
        return "Here are your reminders for <b>today</b>:";
      case 'week':
        return "Here are your reminders for <b>this week</b>:";
      case 'day':
        return "Here are your reminders for the <b>$day${_getDaySuffix(day)}</b>:";
      default:
        return "Here are all your reminders:";
    }
  }

  String _getDaySuffix(int? day) {
    if (day == null) return '';
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _typingTimer?.cancel();
    _pauseTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rootContext = context;
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? LoggitColors.darkBg : LoggitColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Loggit',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            // Feature card buttons (Tasks, Expenses)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: LoggitSpacing.screenPadding,
                vertical: Responsive.responsiveFont(
                  context,
                  16,
                  min: 8,
                  max: 32,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Flexible(
                        child: FeatureCardButton(
                          label: 'Tasks',
                          icon: Icons.check_circle,
                          iconBgColor: LoggitColors.tealDark,
                          iconColor: Colors.white,
                          cardColor: isDark
                              ? LoggitColors.darkCard
                              : Color(0xFFECFDF5),
                          selected: true,
                          onTap: widget.onShowTasks,
                          textColor: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth < 400 ? 8 : 16),
                      Flexible(
                        child: FeatureCardButton(
                          label: 'Expenses',
                          icon: Icons.list_alt,
                          iconBgColor: LoggitColors.indigo,
                          iconColor: Colors.white,
                          cardColor: isDark
                              ? LoggitColors.darkCard
                              : Color(0xFFF4F3FF),
                          selected: false,
                          onTap: () {},
                          textColor: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Chat bubbles (including animated intro as first bubble)
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: LoggitSpacing.screenPadding,
                  vertical: Responsive.responsiveFont(
                    context,
                    16,
                    min: 8,
                    max: 40,
                  ),
                ),
                children: [
                  // Intro bubble
                  _buildIntroBubble(context, isDark),
                  SizedBox(
                    height: Responsive.responsiveFont(
                      context,
                      20,
                      min: 10,
                      max: 40,
                    ),
                  ),
                  // All chat bubbles with consistent spacing
                  for (int i = 0; i < _messages.length; i++) ...[
                    _buildChatBubble(context, _messages[i], isDark),
                    if (i != _messages.length - 1)
                      SizedBox(
                        height: Responsive.responsiveFont(
                          context,
                          20,
                          min: 10,
                          max: 40,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            // Input field above bottom nav
            Padding(
              padding: EdgeInsets.fromLTRB(
                LoggitSpacing.screenPadding,
                0,
                LoggitSpacing.screenPadding,
                Responsive.responsiveFont(context, 12, min: 6, max: 24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? LoggitColors.darkCard : Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(
                    Responsive.responsiveFont(context, 24, min: 12, max: 32),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading, // Disable during loading
                        decoration: InputDecoration(
                          hintText: _isLoading
                              ? 'Processing...'
                              : 'Type a message...',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(
                            color: isDark
                                ? LoggitColors.darkSubtext
                                : Color(0xFF6B7280),
                            fontSize: Responsive.responsiveFont(
                              context,
                              16,
                              min: 12,
                              max: 22,
                            ),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: Responsive.responsiveFont(
                              context,
                              16,
                              min: 8,
                              max: 24,
                            ),
                            horizontal: Responsive.responsiveFont(
                              context,
                              16,
                              min: 8,
                              max: 24,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: isDark
                              ? LoggitColors.darkText
                              : LoggitColors.darkGrayText,
                          fontSize: Responsive.responsiveFont(
                            context,
                            16,
                            min: 12,
                            max: 22,
                          ),
                        ),
                        onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: _isLoading
                          ? SizedBox(
                              width: Responsive.responsiveIcon(
                                context,
                                20,
                                min: 16,
                                max: 28,
                              ),
                              height: Responsive.responsiveIcon(
                                context,
                                20,
                                min: 16,
                                max: 28,
                              ),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white : LoggitColors.tealDark,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: isDark
                                  ? Colors.white
                                  : LoggitColors.tealDark,
                              size: Responsive.responsiveIcon(
                                context,
                                28,
                                min: 20,
                                max: 44,
                              ),
                            ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.smart_toy,
                        color: isDark ? Colors.white : Colors.orange,
                        size: Responsive.responsiveIcon(
                          context,
                          24,
                          min: 16,
                          max: 36,
                        ),
                      ),
                      onPressed: _testAIService,
                    ),
                  ],
                ),
              ),
            ),
            // Fixed bottom nav
            Stack(
              children: [
                _ChatBottomNav(
                  onMenuTap: () => _showLogOptionsSheet(context),
                  onProfileTap: () => _showProfileSheet(context),
                  isDark: isDark,
                ),
                // Removed floating hamburger menu button here
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }

  void _showLogOptionsSheet(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Use default backgroundColor for solid modal look
      builder: (context) {
        final logOptions = [
          _LogOption(
            icon: Icons.fitness_center,
            label: 'Gym',
            color: isDark ? LoggitColors.darkAccent : Colors.indigo,
            onTap: widget.onShowGym,
          ),
          _LogOption(
            icon: Icons.list_alt,
            label: 'Expenses',
            color: isDark ? LoggitColors.darkAccent : LoggitColors.indigo,
            onTap: () {
              /* TODO */
            },
          ),
          _LogOption(
            icon: Icons.alarm,
            label: 'Reminders',
            color: isDark ? LoggitColors.darkAccent : Colors.deepPurple,
            onTap: widget.onShowReminders,
          ),
          _LogOption(
            icon: Icons.check_circle,
            label: 'Tasks',
            color: isDark ? LoggitColors.darkAccent : LoggitColors.tealDark,
            onTap: widget.onShowTasks,
          ),
          _LogOption(
            icon: Icons.note,
            label: 'Notes',
            color: isDark ? LoggitColors.darkAccent : Colors.amber[800]!,
            onTap: widget.onShowNotes,
          ),
        ];
        return FractionallySizedBox(
          heightFactor: 0.5, // Exactly half the screen height
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxSheetWidth(context),
            ),
            decoration: BoxDecoration(
              color: isDark ? LoggitColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              // Removed boxShadow for a clean, borderless look
            ),
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: Responsive.sheetPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? LoggitColors.darkBorder
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _LogOptionGrid(
                        logOptions: logOptions,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileSheet(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? LoggitColors.darkCard : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          height: MediaQuery.of(context).size.height * 0.8,
          width: double.infinity,
          child: Column(
            children: [
              // Fixed handle at the top
              SizedBox(
                height: 48, // slightly taller to fit handle and title
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? LoggitColors.darkBorder
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable profile content (no handle here)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      TextField(
                        controller: _profileNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? LoggitColors.darkCard
                              : Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Enter your name',
                        ),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : LoggitColors.darkGrayText,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? LoggitColors.darkCard
                              : Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: LoggitColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'user@example.com',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : LoggitColors.darkGrayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? LoggitColors.darkCard
                              : Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: LoggitColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '@user123',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : LoggitColors.darkGrayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.dark_mode,
                          color: LoggitColors.teal,
                          size: 18,
                        ),
                        title: Text(
                          'Activate dark mode',
                          style: TextStyle(fontSize: 15),
                        ),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) {
                            Navigator.of(context).pop();
                            if (widget.onThemeToggle != null) {
                              widget.onThemeToggle!();
                            }
                          },
                          activeColor: LoggitColors.teal,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      _ProfileActionTile(
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help with the app',
                        onTap: () {
                          // TODO: Navigate to help
                        },
                      ),
                      SizedBox(height: 12),
                      _ProfileActionTile(
                        icon: Icons.info,
                        title: 'About',
                        subtitle: 'App version and information',
                        onTap: () {
                          // TODO: Navigate to about
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for intro and chat bubbles
  Widget _buildIntroBubble(BuildContext context, bool isDark) {
    final maxText = _actions.reduce((a, b) => a.length > b.length ? a : b);
    final maxWidth =
        (TextPainter(
          text: TextSpan(
            text: "Ask me to… $maxText",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout()).width +
        40;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: maxWidth.clamp(160.0, MediaQuery.of(context).size.width * 0.95),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? LoggitColors.darkCard : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isDark ? LoggitColors.darkBorder : Color(0xFFF3F4F6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ask me to… ",
              style: TextStyle(
                color: isDark
                    ? LoggitColors.darkSubtext
                    : LoggitColors.lighterGraySubtext,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            Text(
              _currentTyped,
              style: TextStyle(
                color: isDark
                    ? LoggitColors.darkText
                    : LoggitColors.darkGrayText,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, _ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    // If there's a custom widget, display it directly
    if (msg.customWidget != null) {
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: msg.customWidget!,
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark ? LoggitColors.darkUserBubble : LoggitColors.tealDark)
              : (isDark ? LoggitColors.darkCard : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 20 : 8),
            topRight: Radius.circular(isUser ? 8 : 20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? LoggitColors.darkBorder : Color(0xFFF3F4F6),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChatText(msg.text, isUser, isDark),
            if (msg.isConfirmation && msg.onConfirmationResponse != null) ...[
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: msg.canConfirm
                        ? () => msg.onConfirmationResponse!(
                            true,
                            msg.pendingLogEntry,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: msg.canConfirm
                          ? LoggitColors.tealDark
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        msg.onConfirmationResponse!(false, msg.pendingLogEntry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? LoggitColors.darkBorder
                          : Colors.grey[300],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (msg.pendingLogEntry != null &&
                      (msg.pendingLogEntry!.logType == 'reminder' ||
                          msg.pendingLogEntry!.logType == 'task')) ...[
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (msg.pendingLogEntry!.logType == 'reminder') {
                          final edited = await showReminderEditModal(
                            context,
                            initial: msg.pendingLogEntry as Reminder,
                          );
                          if (edited != null) {
                            setState(() {
                              _messages.removeWhere(
                                (m) =>
                                    m.isConfirmation &&
                                    m.pendingLogEntry?.logType ==
                                        msg.pendingLogEntry!.logType,
                              );
                              _messages.add(
                                _ChatMessage(
                                  text: _getConfirmationMessage(edited),
                                  isUser: false,
                                  timestamp: DateTime.now(),
                                  isConfirmation: true,
                                  onConfirmationResponse:
                                      (confirmed, [updatedLogEntry]) =>
                                          _handleLogConfirmation(
                                            confirmed,
                                            updatedLogEntry ?? edited,
                                          ),
                                  pendingLogEntry: edited,
                                  canConfirm: true,
                                  showEdit: true,
                                ),
                              );
                            });
                            _scrollToBottom();
                          }
                        } else if (msg.pendingLogEntry!.logType == 'task') {
                          final edited = await showTaskModal(
                            context,
                            task: msg.pendingLogEntry as Task,
                          );
                          if (edited != null) {
                            setState(() {
                              _messages.removeWhere(
                                (m) =>
                                    m.isConfirmation &&
                                    m.pendingLogEntry?.logType ==
                                        msg.pendingLogEntry!.logType,
                              );
                              _messages.add(
                                _ChatMessage(
                                  text: _getConfirmationMessage(edited),
                                  isUser: false,
                                  timestamp: DateTime.now(),
                                  isConfirmation: true,
                                  onConfirmationResponse:
                                      (confirmed, [updatedLogEntry]) =>
                                          _handleLogConfirmation(
                                            confirmed,
                                            updatedLogEntry ?? edited,
                                          ),
                                  pendingLogEntry: edited,
                                  canConfirm: true,
                                  showEdit: true,
                                ),
                              );
                            });
                            _scrollToBottom();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            msg.pendingLogEntry!.logType == 'reminder' ||
                                msg.pendingLogEntry!.logType == 'task'
                            ? Colors.orange
                            : LoggitColors.tealDark,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (msg.isReminderList && msg.reminderList != null) ...[
              SizedBox(height: 12),
              ...msg.reminderList!.map(
                (reminder) =>
                    _buildReminderListItem(reminder, isDark, msg.isDeleteMode),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderListItem(
    Reminder reminder,
    bool isDark,
    bool isDeleteMode,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? LoggitColors.darkBorder : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? LoggitColors.darkBorder : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatReminderTime(reminder.reminderTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? LoggitColors.darkSubtext
                        : LoggitColors.lighterGraySubtext,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _handleEditReminder(context, reminder),
                icon: Icon(Icons.edit, size: 16, color: LoggitColors.tealDark),
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () => _handleDeleteReminder(reminder),
                icon: Icon(Icons.delete, size: 16, color: Colors.red[600]),
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDeleteReminder(Reminder reminder) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text:
              'Are you sure you want to delete the reminder "${reminder.title}" for <b>${_formatReminderTime(reminder.reminderTime)}</b>?',
          isUser: false,
          timestamp: DateTime.now(),
          isConfirmation: true,
          onConfirmationResponse: (confirmed, [updatedLogEntry]) async {
            if (confirmed) {
              await RemindersService.deleteReminder(reminder);
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: '✅ Reminder deleted.',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            } else {
              setState(() {
                _messages.add(
                  _ChatMessage(
                    text: '❌ Deletion cancelled.',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            }
            _scrollToBottom();
          },
          pendingLogEntry: reminder,
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildChatText(String text, bool isUser, bool isDark) {
    // Look for <b>...</b> markers and render bold
    final regex = RegExp(r'<b>(.*?)</b>');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }
    final spans = <TextSpan>[];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(
          TextSpan(
            text: text.substring(last, match.start),
            style: TextStyle(
              color: isUser
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(last),
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  void _handleEditLogEntry(BuildContext context, LogEntry? entry) async {
    if (entry == null) return;
    if (entry.logType == 'task') {
      // Use the actual task edit modal
      final edited = await showTaskModal(context, task: entry as Task);
      if (edited != null) {
        setState(() {
          _messages.removeWhere(
            (m) =>
                m.isConfirmation && m.pendingLogEntry?.logType == entry.logType,
          );
          _messages.add(
            _ChatMessage(
              text: _getConfirmationMessage(edited),
              isUser: false,
              timestamp: DateTime.now(),
              isConfirmation: true,
              onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                  _handleLogConfirmation(confirmed, updatedLogEntry ?? edited),
              pendingLogEntry: edited,
              canConfirm: true,
              showEdit: true,
            ),
          );
        });
        _scrollToBottom();
      }
    } else {
      // Fallback for other types (e.g., reminder)
      // This block is intentionally left empty. Only the correct modals should be used.
    }
  }

  String _formatTaskTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
  }

  // --- NEW: Focused Conversation Helper Methods ---

  /// Check if there's a pending confirmation message
  bool _hasPendingConfirmation() {
    return _messages.any(
      (message) => message.isConfirmation && message.pendingLogEntry != null,
    );
  }

  /// Get a focused reminder message when user tries to create something new while pending
  String _getFocusedReminderMessage() {
    if (_pendingLog == null) return "I'm ready to help you!";

    StringBuffer message = StringBuffer();

    // Add confirmation message
    message.writeln(
      "I'm still waiting for you to confirm your ${_getLogTypeName()}. Please confirm this first:",
    );
    message.writeln("");

    // Add the current confirmation details
    message.write(_getConfirmationMessage(_pendingLog!));

    // Add helpful guidance
    message.writeln("");
    message.writeln(
      "Once you confirm or cancel this, I'll be happy to help with anything else!",
    );

    return message.toString();
  }

  /// Get a user-friendly name for the log type
  String _getLogTypeName() {
    switch (_pendingLog?.logType) {
      case 'task':
        return 'task';
      case 'reminder':
        return 'reminder';
      case 'note':
        return 'note';
      case 'expense':
        return 'expense';
      case 'gym':
        return 'workout log';
      default:
        return 'item';
    }
  }

  /// Check if a message is likely adding a description to the pending item
  bool _isLikelyDescriptionAddition(
    String message,
    String intent,
    Map<String, dynamic> fields,
  ) {
    // If AI returns a new task/reminder but the message is short and descriptive
    if ((intent == 'create_task' || intent == 'create_reminder') &&
        message.length < 50 &&
        !message.toLowerCase().contains('tomorrow') &&
        !message.toLowerCase().contains('today') &&
        !message.toLowerCase().contains('monday') &&
        !message.toLowerCase().contains('tuesday') &&
        !message.toLowerCase().contains('wednesday') &&
        !message.toLowerCase().contains('thursday') &&
        !message.toLowerCase().contains('friday') &&
        !message.toLowerCase().contains('saturday') &&
        !message.toLowerCase().contains('sunday') &&
        !message.toLowerCase().contains('am') &&
        !message.toLowerCase().contains('pm') &&
        !message.toLowerCase().contains(':') &&
        !message.toLowerCase().contains('at ') &&
        !message.toLowerCase().contains('create') &&
        !message.toLowerCase().contains('remind') &&
        !message.toLowerCase().contains('task')) {
      return true;
    }
    return false;
  }

  /// Add description to the pending item and update the confirmation
  void _addDescriptionToPendingItem(String description) {
    if (_pendingLog == null) return;

    setState(() {
      // Remove loading message
      if (_messages.isNotEmpty && _messages.last.text == "🤖 Processing...") {
        _messages.removeLast();
      }

      // Update the pending log with the description
      if (_pendingLog is Task) {
        final task = _pendingLog as Task;
        final updatedTask = task.copyWith(description: description);
        _pendingLog = updatedTask;
      } else if (_pendingLog is Reminder) {
        final reminder = _pendingLog as Reminder;
        final updatedReminder = reminder.copyWith(description: description);
        _pendingLog = updatedReminder;
      }

      // Update the confirmation message
      _messages.removeWhere(
        (m) => m.isConfirmation && m.pendingLogEntry != null,
      );
      _messages.add(
        _ChatMessage(
          text: _getConfirmationMessage(_pendingLog!),
          isUser: false,
          timestamp: DateTime.now(),
          isConfirmation: true,
          onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
              _handleLogConfirmation(confirmed, updatedLogEntry),
          pendingLogEntry: _pendingLog,
          canConfirm: true,
          showEdit: true,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Get task time required message with captured information
  String _getTaskTimeRequiredMessage(Task task) {
    StringBuffer message = StringBuffer();
    message.writeln("⏰ Time required for task");
    message.writeln("Set time: \"at 2pm\" or \"tomorrow 9am\"");
    message.writeln("");

    // Show captured information
    message.writeln("📋 ${task.title}");
    if (task.dueDate != null) {
      final date = task.dueDate!;
      final now = DateTime.now();
      if (date.year != now.year ||
          date.month != now.month ||
          date.day != now.day) {
        final dateString =
            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        message.writeln("📅 $dateString");
      } else {
        message.writeln("📅 Today");
      }
    }
    if (task.description != null && task.description!.isNotEmpty) {
      String truncatedDescription = task.description!;
      if (truncatedDescription.length > 25) {
        truncatedDescription = "${truncatedDescription.substring(0, 22)}...";
      }
      message.writeln("📝 $truncatedDescription");
    }
    if (task.category != null && task.category!.isNotEmpty) {
      message.writeln("🏷️ ${task.category}");
    }

    // Add priority information
    String priorityText = "";
    switch (task.priority) {
      case TaskPriority.high:
        priorityText = "High";
        break;
      case TaskPriority.medium:
        priorityText = "Medium";
        break;
      case TaskPriority.low:
        priorityText = "Low";
        break;
    }
    message.writeln("⭐ Priority: $priorityText");

    // Add reminder information
    if (task.reminder != ReminderType.none) {
      String reminderText = "";
      switch (task.reminder) {
        case ReminderType.fifteenMinutes:
          reminderText = "15 minutes before";
          break;
        case ReminderType.oneHour:
          reminderText = "1 hour before";
          break;
        case ReminderType.oneDay:
          reminderText = "1 day before";
          break;
        case ReminderType.fiveMinutes:
          reminderText = "5 minutes before";
          break;
        case ReminderType.twentyMinutes:
          reminderText = "20 minutes before";
          break;
        case ReminderType.thirtyMinutes:
          reminderText = "30 minutes before";
          break;
        case ReminderType.twoHours:
          reminderText = "2 hours before";
          break;
        default:
          reminderText = "—";
      }
      message.writeln("⏰ Reminder: $reminderText");
    } else {
      message.writeln("⏰ Reminder: —");
    }

    return message.toString();
  }

  /// Get reminder time required message with captured information
  String _getReminderTimeRequiredMessage(Reminder reminder) {
    StringBuffer message = StringBuffer();
    message.writeln("⏰ Time required for reminder");
    message.writeln("Set time: \"at 2pm\" or \"tomorrow 9am\"");
    message.writeln("");

    // Show captured information
    message.writeln("📋 ${reminder.title}");
    final date = reminder.reminderTime;
    final now = DateTime.now();
    if (date.year != now.year ||
        date.month != now.month ||
        date.day != now.day) {
      final dateString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      message.writeln("📅 $dateString");
    } else {
      message.writeln("📅 Today");
    }
    if (reminder.description != null && reminder.description!.isNotEmpty) {
      String truncatedDescription = reminder.description!;
      if (truncatedDescription.length > 25) {
        truncatedDescription = "${truncatedDescription.substring(0, 22)}...";
      }
      message.writeln("📝 $truncatedDescription");
    }
    if (reminder.advanceTiming != null && reminder.advanceTiming!.isNotEmpty) {
      message.writeln("⏰ Advance: ${reminder.advanceTiming}");
    }

    return message.toString();
  }

  /// Get past time warning message with captured information
  String _getPastTimeWarningMessage(Reminder reminder) {
    StringBuffer message = StringBuffer();
    message.writeln("⏰ Time has already passed");
    message.writeln("Set future time: \"at 2pm\" or \"tomorrow 9am\"");
    message.writeln("");

    // Show captured information
    message.writeln("📋 ${reminder.title}");
    final date = reminder.reminderTime;
    final now = DateTime.now();
    if (date.year != now.year ||
        date.month != now.month ||
        date.day != now.day) {
      final dateString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      message.writeln("📅 $dateString");
    } else {
      message.writeln("📅 Today");
    }
    if (reminder.description != null && reminder.description!.isNotEmpty) {
      String truncatedDescription = reminder.description!;
      if (truncatedDescription.length > 25) {
        truncatedDescription = "${truncatedDescription.substring(0, 22)}...";
      }
      message.writeln("📝 $truncatedDescription");
    }
    if (reminder.advanceTiming != null && reminder.advanceTiming!.isNotEmpty) {
      message.writeln("⏰ Advance: ${reminder.advanceTiming}");
    }

    return message.toString();
  }

  /// Get a helpful error message based on the error and user's message
  String _getHelpfulErrorMessage(String error, String userMessage) {
    String lowerMessage = userMessage.toLowerCase();

    // Check for rate limit errors
    if (error.contains('rate limit') || error.contains('429')) {
      return "⏰ I'm a bit busy right now. Please try again in a few seconds.";
    }

    // Check for weather-related queries
    if (lowerMessage.contains('weather') ||
        lowerMessage.contains('temperature') ||
        lowerMessage.contains('forecast') ||
        lowerMessage.contains('rain') ||
        lowerMessage.contains('sunny') ||
        lowerMessage.contains('cold') ||
        lowerMessage.contains('hot')) {
      return "🌤️ I don't have access to weather information. I'm designed to help with tasks, reminders, notes, expenses, and workout tracking. For weather updates, try checking a weather app or website!";
    }

    // Check for time/date queries
    if (lowerMessage.contains('what time') ||
        lowerMessage.contains('current time') ||
        lowerMessage.contains('what day') ||
        lowerMessage.contains('what date') ||
        lowerMessage.contains('today is') ||
        lowerMessage.contains('day of the week')) {
      return "🕐 I can help you schedule tasks and reminders, but I can't tell you the current time or date. Check your device's clock or calendar app!";
    }

    // Check for calculator/math queries
    if (lowerMessage.contains('calculate') ||
        lowerMessage.contains('math') ||
        lowerMessage.contains('add') ||
        lowerMessage.contains('subtract') ||
        lowerMessage.contains('multiply') ||
        lowerMessage.contains('divide') ||
        lowerMessage.contains('+') ||
        lowerMessage.contains('-') ||
        lowerMessage.contains('*') ||
        lowerMessage.contains('/')) {
      return "🧮 I can help you log expenses, but I'm not a calculator. Try using your device's calculator app for math calculations!";
    }

    // Check for web search queries
    if (lowerMessage.contains('search') ||
        lowerMessage.contains('google') ||
        lowerMessage.contains('find') ||
        lowerMessage.contains('look up') ||
        lowerMessage.contains('what is') ||
        lowerMessage.contains('who is')) {
      return "🔍 I can't search the web or provide general information. I'm focused on helping you manage tasks, reminders, notes, expenses, and workouts. Try a search engine for general queries!";
    }

    // Check for entertainment queries
    if (lowerMessage.contains('joke') ||
        lowerMessage.contains('funny') ||
        lowerMessage.contains('entertain') ||
        lowerMessage.contains('play') ||
        lowerMessage.contains('game') ||
        lowerMessage.contains('music')) {
      return "🎭 I'm designed to help you stay organized and productive. I can't provide entertainment, jokes, or games. Try a dedicated entertainment app!";
    }

    // Check for personal questions
    if (lowerMessage.contains('how are you') ||
        lowerMessage.contains('your name') ||
        lowerMessage.contains('who are you') ||
        lowerMessage.contains('about you')) {
      return "👋 I'm Loggit, your AI assistant for managing tasks, reminders, notes, expenses, and workouts. I'm here to help you stay organized and productive!";
    }

    // Default helpful message
    return "🤔 I understand you're asking about something, but I'm specifically designed to help with:\n\n"
            "📋 Tasks and reminders\n" "📝 Notes and organization\n" +
        "💰 Expense tracking\n" +
        "💪 Workout logging\n\n" +
        "Try asking me to help with one of these instead!";
  }
}

// Profile bottom sheet widgets
class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14, // smaller
            fontWeight: FontWeight.bold,
            color: LoggitColors.darkGrayText,
          ),
        ),
        SizedBox(height: 8), // less vertical space
        child,
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10), // smaller padding
      decoration: BoxDecoration(
        color: isDark ? LoggitColors.darkCard : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8), // smaller radius
        border: Border.all(
          color: isDark ? LoggitColors.darkBorder : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? LoggitColors.darkAccent : LoggitColors.tealDark,
            size: 18, // smaller icon
          ),
          SizedBox(width: 8), // less space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, // smaller font
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : LoggitColors.darkGrayText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11, // smaller font
                    color: isDark
                        ? Colors.white
                        : LoggitColors.lighterGraySubtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProfileToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: LoggitColors.tealDark, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: LoggitColors.darkGrayText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: LoggitColors.lighterGraySubtext,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LoggitColors.tealDark,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10), // smaller padding
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8), // smaller radius
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: LoggitColors.tealDark, size: 18), // smaller icon
            SizedBox(width: 8), // less space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12, // smaller font
                      fontWeight: FontWeight.w600,
                      color: LoggitColors.darkGrayText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11, // smaller font
                      color: LoggitColors.lighterGraySubtext,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: LoggitColors.lighterGraySubtext,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isConfirmation;
  final Function(bool, [LogEntry?])? onConfirmationResponse;
  final LogEntry? pendingLogEntry;
  final bool isReminderList;
  final List<Reminder>? reminderList;
  final bool isDeleteMode;
  final String? originalSearchTerm;
  final bool canConfirm;
  final bool showEdit;
  final Widget? customWidget;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isConfirmation = false,
    this.onConfirmationResponse,
    this.pendingLogEntry,
    this.canConfirm = true,
    this.showEdit = false,
    this.customWidget,
  });
}

// Add the bottom nav widget
class _ChatBottomNav extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final bool isDark;
  const _ChatBottomNav({
    required this.onMenuTap,
    required this.onProfileTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 350;
        final iconSize = isSmall ? 20.0 : 28.0;
        final fontSize = isSmall ? 10.0 : 14.0;
        final iconColor = isDark ? Colors.white : LoggitColors.darkGrayText;
        return Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? LoggitColors.darkCard : LoggitColors.pureWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.chat_bubble,
                  label: 'Chat',
                  selected: true,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconColor: iconColor,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: onProfileTap,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconColor: iconColor,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.menu,
                  label: '',
                  onTap: onMenuTap,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconColor: iconColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final Color? iconColor;
  final bool isDark;
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.iconSize = 28,
    this.fontSize = 14,
    this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color:
                iconColor ??
                (selected ? LoggitColors.tealDark : LoggitColors.darkGrayText),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  _LogOption({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class _LogOptionTileGrid extends StatelessWidget {
  final _LogOption option;
  final double iconSize;
  final double fontSize;
  final double avatarRadius;
  final bool isDark;
  const _LogOptionTileGrid({
    required this.option,
    required this.iconSize,
    required this.fontSize,
    required this.avatarRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).pop();
        if (option.onTap != null) option.onTap!();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: option.color,
            radius: avatarRadius,
            child: Icon(option.icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : LoggitColors.darkGrayText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogOptionGrid extends StatelessWidget {
  final List<_LogOption> logOptions;
  final bool isDark;
  const _LogOptionGrid({required this.logOptions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: logOptions.map((opt) {
        return _LogOptionTileGrid(
          option: opt,
          iconSize: Responsive.responsiveIcon(context, 38, min: 26, max: 44),
          fontSize: Responsive.responsiveFont(context, 15, min: 12, max: 20),
          avatarRadius: Responsive.responsiveIcon(
            context,
            28,
            min: 18,
            max: 32,
          ),
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _ReminderBubble extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderBubble({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatReminderTime(reminder.reminderTime);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Reminder icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LoggitColors.remindersBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.alarm,
              color: LoggitColors.remindersText,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          // Reminder content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: LoggitColors.darkGrayText,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: LoggitColors.indigoLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit, size: 16, color: LoggitColors.indigo),
                ),
              ),
              SizedBox(width: 8),
              // Delete button
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete, size: 16, color: Color(0xFFD32F2F)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReminderTime(DateTime reminderTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final reminderDate = DateTime(
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
    );

    String dateStr;
    if (reminderDate == today) {
      dateStr = 'Today';
    } else if (reminderDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      dateStr =
          '${days[reminderTime.weekday - 1]}, ${reminderTime.day} ${months[reminderTime.month - 1]}';
    }

    final hour = reminderTime.hour;
    final minute = reminderTime.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';

    return '$dateStr at $timeStr';
  }
}

class _TaskBubble extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskBubble({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatTaskDate(task.dueDate);
    final formattedTime = task.timeOfDay != null
        ? _formatTaskTime(task.timeOfDay!)
        : null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Task icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LoggitColors.pendingTasksBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.task,
              color: LoggitColors.pendingTasksText,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formattedDate +
                      (formattedTime != null ? ' at $formattedTime' : ''),
                  style: TextStyle(
                    fontSize: 14,
                    color: LoggitColors.darkGrayText,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: LoggitColors.indigoLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit, size: 16, color: LoggitColors.indigo),
                ),
              ),
              SizedBox(width: 8),
              // Delete button
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete, size: 16, color: Color(0xFFD32F2F)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTaskDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${days[dueDate.weekday - 1]}, ${dueDate.day} ${months[dueDate.month - 1]}';
    }
  }

  String _formatTaskTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
  }
}

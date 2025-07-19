import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/favorite_feature.dart';
import '../../models/log_entry.dart';
import '../../services/ai_service.dart';
import '../../services/favorites_service.dart';
import '../../services/reminders_service.dart';
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
import '../reminders/reminder_edit_modal.dart';
import '../reminders/reminder_model.dart';
import '../tasks/task_model.dart';
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

        if (result is Map<String, dynamic> &&
            result.containsKey('intent') &&
            result.containsKey('fields')) {
          final intent = result['intent'];
          final fields = result['fields'] as Map<String, dynamic>;

          // --- NEW: AI Conversation continuation ---
          // If we have a pending log entry, try to merge AI response with it
          if (_pendingLog != null) {
            print(
              'DEBUG: AI Conversation continuation - merging with pending log',
            );

            // If we have a pending task and AI returns reminder intent, treat it as task continuation
            if (_pendingLog is Task &&
                (intent == 'create_task' || intent == 'set_reminder')) {
              final pending = _pendingLog as Task;
              final title =
                  (fields['title'] != null &&
                      fields['title'].toString().isNotEmpty)
                  ? fields['title']
                  : pending.title;
              final description = fields['description'] ?? '';

              // Parse AI's date and time
              DateTime? dueDate = pending.dueDate;
              TimeOfDay? timeOfDay = pending.timeOfDay;

              // Handle both dueDate and reminderTime fields (AI might use either)
              String? dateField = fields['dueDate'] ?? fields['reminderTime'];
              String? timeField = fields['timeOfDay'] ?? fields['time'];

              if (dateField != null && dateField is String) {
                final now = DateTime.now();
                final dateStr = dateField.toLowerCase();

                if (dateStr == 'tomorrow') {
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

              if (timeField != null && timeField is String) {
                final timeMatch = RegExp(
                  r'^(\d{1,2})(?::(\d{2}))?',
                ).firstMatch(timeField);
                if (timeMatch != null) {
                  int hour = int.parse(timeMatch.group(1)!);
                  int minute = timeMatch.group(2) != null
                      ? int.parse(timeMatch.group(2)!)
                      : 0;
                  timeOfDay = TimeOfDay(hour: hour, minute: minute);
                }
              }

              TaskPriority priorityEnum = TaskPriority.medium;
              if (fields['priority'] is String &&
                  fields['priority'].isNotEmpty) {
                final p = fields['priority'].toString().toLowerCase();
                if (p == 'low')
                  priorityEnum = TaskPriority.low;
                else if (p == 'high')
                  priorityEnum = TaskPriority.high;
                else if (p == 'medium')
                  priorityEnum = TaskPriority.medium;
              }

              final updatedTask = Task(
                title: title,
                description: description,
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

          // Original AI logic for new tasks/reminders
          if (intent == 'create_task') {
            final title = fields['title'] ?? '';
            final description = fields['description'] ?? '';
            TaskPriority priorityEnum = TaskPriority.medium;
            if (fields['priority'] is String && fields['priority'].isNotEmpty) {
              final p = fields['priority'].toString().toLowerCase();
              if (p == 'low')
                priorityEnum = TaskPriority.low;
              else if (p == 'high')
                priorityEnum = TaskPriority.high;
              else if (p == 'medium')
                priorityEnum = TaskPriority.medium;
            }
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
                  final daysUntilTarget = (targetWeekday - now.weekday + 7) % 7;
                  // Set only the date part, not the time
                  dueDate = DateTime(
                    now.year,
                    now.month,
                    now.day + daysUntilTarget,
                  );
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
                dueDate = DateTime.tryParse(fields['dueDate']);
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
            // Create the Task object
            final newTask = Task(
              title: title,
              description: description,
              priority: priorityEnum,
              dueDate: dueDate,
              timeOfDay: timeOfDay,
              timestamp: DateTime.now(),
            );
            setState(() {
              _pendingLog = newTask;
              // Remove loading message if it exists
              if (_messages.isNotEmpty &&
                  _messages.last.text == "🤖 Processing...") {
                _messages.removeLast();
              }
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
              _isLoading = false; // Stop loading
            });
            _scrollToBottom();
            return;
          } else if (intent == 'create_reminder') {
            final title = fields['title'] ?? '';
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
            // Handle reminderDate only (no time specified)
            else if (fields['reminderDate'] != null &&
                fields['reminderDate'] is String) {
              final reminderDateStr = fields['reminderDate'] as String;
              DateTime? reminderDate = DateTime.tryParse(reminderDateStr);
              if (reminderDate != null) {
                // Set to midnight (00:00) to indicate no specific time set
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
            final reminder = Reminder(
              title: title,
              reminderTime: reminderTime,
              timestamp: DateTime.now(),
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
          } else if (intent == 'view_reminders') {
            final timeframe = fields['timeframe'] ?? 'all';

            // Handle reminder query asynchronously
            _handleReminderQuery(timeframe);
            return;
          } else if (intent == 'note') {
            final title = fields['title'] ?? '';
            final content = fields['content'] ?? '';
            final note = Note(
              title: title,
              content: content,
              timestamp: DateTime.now(),
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
          if (result is Map<String, dynamic> &&
              result.containsKey('intent') &&
              result.containsKey('fields')) {
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
                if (p == 'low')
                  priorityEnum = TaskPriority.low;
                else if (p == 'high')
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
              final title = fields['title'] ?? '';
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
              final reminder = Reminder(
                title: title,
                reminderTime: reminderTime,
                timestamp: DateTime.now(),
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
      setState(() {
        _messages.add(
          _ChatMessage(
            text: "❌ AI Error: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
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
    return Note(title: title, content: title, timestamp: DateTime.now());
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
        // Tasks require: title, dueDate, and timeOfDay
        final hasTitle = task.title.isNotEmpty;
        final hasDueDate = task.dueDate != null;
        final hasTimeOfDay = task.timeOfDay != null;

        print('DEBUG: _hasRequiredFields - task validation:');
        print('DEBUG: _hasRequiredFields - title: "$hasTitle" (${task.title})');
        print(
          'DEBUG: _hasRequiredFields - dueDate: $hasDueDate (${task.dueDate})',
        );
        print(
          'DEBUG: _hasRequiredFields - timeOfDay: $hasTimeOfDay (${task.timeOfDay})',
        );

        return hasTitle && hasDueDate && hasTimeOfDay;
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
        return "Log expense: £${expense.amount.toStringAsFixed(2)} for ${expense.category}?";
      case 'task':
        final task = logEntry as Task;
        String dateTimeInfo = '';

        if (task.dueDate != null) {
          final date = task.dueDate!;
          final now = DateTime.now();

          // Check if we have a specific time set (either in dueDate or timeOfDay)
          bool hasSpecificTime =
              (task.dueDate!.hour != 0 || task.dueDate!.minute != 0) ||
              (task.timeOfDay != null);

          if (hasSpecificTime) {
            // Show full date and time - use timeOfDay if available, otherwise use dueDate
            DateTime displayDateTime;
            if (task.timeOfDay != null) {
              // Use the date from dueDate but time from timeOfDay
              displayDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              );
            } else {
              // Use the dueDate as is
              displayDateTime = date;
            }
            final timeString = _formatReminderTime(displayDateTime);
            dateTimeInfo = " due <b>$timeString</b>";
          } else {
            // Show date only (no time set)
            if (date.year != now.year ||
                date.month != now.month ||
                date.day != now.day) {
              final dateString =
                  "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              dateTimeInfo = " due $dateString (no time set yet)";
            } else {
              dateTimeInfo = " (no time set yet)";
            }
          }
        }

        return "Create task: ${task.title}$dateTimeInfo?";
      case 'reminder':
        final reminder = logEntry as Reminder;
        // If time is 00:00, treat as 'no time set' and only show date (if present)
        if (reminder.reminderTime.hour == 0 &&
            reminder.reminderTime.minute == 0) {
          final date = reminder.reminderTime;
          final now = DateTime.now();
          // Only show date if it's not today
          if (date.year != now.year ||
              date.month != now.month ||
              date.day != now.day) {
            final dateString =
                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            return "Set reminder: ${reminder.title} for $dateString (no time set yet)";
          } else {
            return "Set reminder: ${reminder.title} (no time set yet)";
          }
        }
        final timeString = _formatReminderTime(reminder.reminderTime);
        return "Set reminder: ${reminder.title} for <b>$timeString</b>?";
      case 'note':
        final note = logEntry as Note;
        return "Save note: ${note.content}?";
      case 'gym':
        final gymLog = logEntry as GymLog;
        final exercise = gymLog.exercises.first;
        final weightText = exercise.weight != null
            ? " ${exercise.weight}kg"
            : "";
        return "Log workout: ${exercise.name} ${exercise.sets}x${exercise.reps}$weightText?";
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
      List<Reminder> filteredReminders = [];

      // Filter reminders based on timeframe
      if (timeframe == 'this week') {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));

        filteredReminders = allReminders.where((reminder) {
          return reminder.reminderTime.isAfter(
                startOfWeek.subtract(Duration(days: 1)),
              ) &&
              reminder.reminderTime.isBefore(endOfWeek.add(Duration(days: 1)));
        }).toList();
      } else if (timeframe == 'next week') {
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

          filteredReminders = allReminders.where((reminder) {
            return reminder.reminderTime.isAfter(
                  startDate.subtract(Duration(seconds: 1)),
                ) &&
                reminder.reminderTime.isBefore(endDate.add(Duration(days: 1)));
          }).toList();
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
      } else if (timeframe == 'this month') {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        filteredReminders = allReminders.where((reminder) {
          return reminder.reminderTime.isAfter(
                startOfMonth.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(endOfMonth.add(Duration(days: 1)));
        }).toList();
      } else if (timeframe == 'next month') {
        final now = DateTime.now();
        final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
        final endOfNextMonth = DateTime(now.year, now.month + 2, 0);

        filteredReminders = allReminders.where((reminder) {
          return reminder.reminderTime.isAfter(
                startOfNextMonth.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(
                endOfNextMonth.add(Duration(days: 1)),
              );
        }).toList();
      } else if (timeframe == 'today') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(Duration(days: 1));

        filteredReminders = allReminders.where((reminder) {
          return reminder.reminderTime.isAfter(
                today.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(tomorrow);
        }).toList();
      } else if (timeframe == 'tomorrow') {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final dayAfterTomorrow = tomorrow.add(Duration(days: 1));

        filteredReminders = allReminders.where((reminder) {
          return reminder.reminderTime.isAfter(
                tomorrow.subtract(Duration(seconds: 1)),
              ) &&
              reminder.reminderTime.isBefore(dayAfterTomorrow);
        }).toList();
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
                  "📅 Reminders for ${timeframe == 'all' ? 'all time' : timeframe}:",
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
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));

        print('DEBUG: this week filtering - now: $now');
        print('DEBUG: this week filtering - startOfWeek: $startOfWeek');
        print('DEBUG: this week filtering - endOfWeek: $endOfWeek');

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          final isInRange =
              task.dueDate!.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              task.dueDate!.isBefore(endOfWeek.add(Duration(days: 1)));
          print(
            'DEBUG: task ${task.title} (${task.dueDate}) - isInRange: $isInRange',
          );
          return isInRange;
        }).toList();

        print('DEBUG: this week filteredTasks count: ${filteredTasks.length}');
      } else if (timeframe == 'next week') {
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

          filteredTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            return task.dueDate!.isAfter(
                  startDate.subtract(Duration(seconds: 1)),
                ) &&
                task.dueDate!.isBefore(endDate.add(Duration(days: 1)));
          }).toList();
        }
      } else if (timeframe == 'this month') {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(
                startOfMonth.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfMonth.add(Duration(days: 1)));
        }).toList();
      } else if (timeframe == 'next month') {
        final now = DateTime.now();
        final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
        final endOfNextMonth = DateTime(now.year, now.month + 2, 0);

        filteredTasks = allTasks.where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(
                startOfNextMonth.subtract(Duration(seconds: 1)),
              ) &&
              task.dueDate!.isBefore(endOfNextMonth.add(Duration(days: 1)));
        }).toList();
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
                  "📋 No tasks found for ${timeframe == 'all' ? 'any time' : timeframe}.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          // Add header message
          _messages.add(
            _ChatMessage(
              text:
                  "📋 Tasks for ${timeframe == 'all' ? 'all time' : timeframe}:",
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
                text:
                    "⏰ Please set a time for your reminder. Tap [Edit] to choose a time, or type something like 'at 18:00' or 'tomorrow at 9am'.",
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
                text:
                    "⏰ That time has already passed. Please pick a future time. Tap [Edit] to choose a new time, or type something like 'at 18:00' or 'tomorrow at 9am'.",
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
        return "Task created: ${task.title}";
      case 'reminder':
        final reminder = logEntry as Reminder;
        final dateTimeString = _formatReminderTime(reminder.reminderTime);
        return "Reminder set: ${reminder.title} on <b>$dateTimeString</b>";
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
    if (logEntry == null) return "Entry cancelled";
    switch (logEntry.logType) {
      case 'expense':
        return "Expense cancelled";
      case 'task':
        return "Task cancelled";
      case 'reminder':
        return "Reminder cancelled";
      case 'note':
        return "Note cancelled";
      case 'gym':
        return "Workout cancelled";
      default:
        return "Entry cancelled";
    }
  }

  String _getNoRemindersMessage(String filter, int? day) {
    switch (filter) {
      case 'today':
        return "You don't have any reminders for today.";
      case 'week':
        return "You don't have any reminders for this week.";
      case 'day':
        return "You don't have any reminders for the $day${_getDaySuffix(day)}.";
      default:
        return "You don't have any reminders.";
    }
  }

  String _getRemindersListMessage(String filter, int? day) {
    switch (filter) {
      case 'today':
        return "Here are your reminders for today:";
      case 'week':
        return "Here are your reminders for this week:";
      case 'day':
        return "Here are your reminders for the $day${_getDaySuffix(day)}:";
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
            label: 'Gym Log',
            color: isDark ? LoggitColors.darkAccent : Colors.indigo,
            onTap: () {
              /* TODO */
            },
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
            onTap: () {
              /* TODO */
            },
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
    this.isReminderList = false,
    this.reminderList,
    this.isDeleteMode = false,
    this.originalSearchTerm,
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
    final timeStr = '${displayHour}:${minute.toString().padLeft(2, '0')} $ampm';

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
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $ampm';
  }
}

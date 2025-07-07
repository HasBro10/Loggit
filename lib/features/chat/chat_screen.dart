import 'package:flutter/material.dart';
import '../../features/expenses/expense_model.dart';
import '../../features/tasks/task_model.dart';
import '../../features/reminders/reminder_model.dart';
import '../../features/notes/note_model.dart';
import '../../features/gym/gym_log_model.dart';
import '../../models/log_entry.dart';
import '../../services/log_parser_service.dart';
import 'chat_message.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final void Function(Expense) onExpenseLogged;
  final void Function(Task)? onTaskLogged;
  final void Function(Reminder)? onReminderLogged;
  final void Function(Note)? onNoteLogged;
  final void Function(GymLog)? onGymLogLogged;

  const ChatScreen({
    super.key,
    required this.onExpenseLogged,
    this.onTaskLogged,
    this.onReminderLogged,
    this.onNoteLogged,
    this.onGymLogLogged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  LogEntry? _pendingLog;

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

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startTyping();
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
        );

        // Use the new LogParserService to parse all log types
        final logEntry = LogParserService.parseMessage(message);

        if (logEntry != null) {
          _pendingLog = logEntry;
          final confirmationMessage = _getConfirmationMessage(logEntry);

          _messages.add(
            ChatMessage(
              text: confirmationMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isConfirmation: true,
              onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
                  _handleLogConfirmation(confirmed, updatedLogEntry),
              pendingLogEntry: logEntry,
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              text:
                  "I didn't understand that. Try:\n• Coffee £3.50\n• Task: Call client\n• Remind me to buy milk\n• Note: Client prefers calls\n• Squats 3 sets x 10 reps",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  String _getConfirmationMessage(LogEntry logEntry) {
    switch (logEntry.logType) {
      case 'expense':
        final expense = logEntry as Expense;
        return "Log expense: £${expense.amount.toStringAsFixed(2)} for ${expense.category}?";

      case 'task':
        final task = logEntry as Task;
        return "Create task: ${task.title}?";

      case 'reminder':
        final reminder = logEntry as Reminder;
        final timeString = _formatTime(reminder.reminderTime);
        return "Set reminder: ${reminder.title} at $timeString?";

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

  void _handleLogConfirmation(bool confirmed, [LogEntry? updatedLogEntry]) {
    final logEntry = updatedLogEntry ?? _pendingLog;
    if (confirmed && logEntry != null) {
      // Call the appropriate callback based on log type
      switch (logEntry.logType) {
        case 'expense':
          widget.onExpenseLogged(logEntry as Expense);
          break;
        case 'task':
          widget.onTaskLogged?.call(logEntry as Task);
          break;
        case 'reminder':
          widget.onReminderLogged?.call(logEntry as Reminder);
          break;
        case 'note':
          widget.onNoteLogged?.call(logEntry as Note);
          break;
        case 'gym':
          widget.onGymLogLogged?.call(logEntry as GymLog);
          break;
      }
      setState(() {
        _messages.add(
          ChatMessage(
            text: "✅ " + _getSuccessMessage(logEntry),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } else {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "❌ " + _getCancelledMessage(_pendingLog),
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
        return "Reminder set: ${reminder.title}";
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _messages.isNotEmpty) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _typingTimer?.cancel();
    _pauseTimer?.cancel();
    _messageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 18, 60, 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF202C33)
                  : const Color(0xFFF1F0F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                if (theme.brightness != Brightness.dark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, I'm Loggit.",
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask me to… ',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF64748b),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    // Fixed width container for consistent dimensions
                    SizedBox(
                      width: 140, // Fixed width to prevent resizing
                      height: 24, // Fixed height for consistent layout
                      child: Stack(
                        children: [
                          // Background text for consistent spacing
                          Text(
                            _actions[_actionIndex],
                            style: TextStyle(
                              color: Colors.transparent,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          // Solid text without fade effects
                          Text(
                            _currentTyped,
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 8,
              left: 2,
              right: 2,
              bottom: 2,
            ),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _messages[index];
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF232D36) // WhatsApp input dark
                : const Color(0xFFF6F9FB), // WhatsApp input light
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF2A3942)
                  : const Color(0xFFE3E3E3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark
                      ? const Color(0xFF005C4B)
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(16),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

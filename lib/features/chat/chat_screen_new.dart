import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import 'dart:async';
import '../../features/expenses/expense_model.dart';
import '../../features/tasks/task_model.dart';
import '../../features/reminders/reminder_model.dart';
import '../../features/notes/note_model.dart';
import '../../features/gym/gym_log_model.dart';
import '../../models/log_entry.dart';
import '../../services/log_parser_service.dart';
import '../../shared/design/widgets/feature_card_button.dart';
import '../../shared/utils/responsive.dart';
import '../reminders/reminders_screen.dart';

class ChatScreenNew extends StatefulWidget {
  final void Function(Expense)? onExpenseLogged;
  final void Function(Task)? onTaskLogged;
  final void Function(Reminder)? onReminderLogged;
  final void Function(Note)? onNoteLogged;
  final void Function(GymLog)? onGymLogLogged;
  final void Function()? onShowTasks;
  final VoidCallback? onThemeToggle;
  final ThemeMode currentThemeMode;

  const ChatScreenNew({
    super.key,
    this.onExpenseLogged,
    this.onTaskLogged,
    this.onReminderLogged,
    this.onNoteLogged,
    this.onGymLogLogged,
    this.onShowTasks,
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _messages.isNotEmpty && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(
          _ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
        );
        final logEntry = LogParserService.parseMessage(message);
        if (logEntry != null) {
          _pendingLog = logEntry;
          final confirmationMessage = _getConfirmationMessage(logEntry);
          _messages.add(
            _ChatMessage(
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
            _ChatMessage(
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
      switch (logEntry.logType) {
        case 'expense':
          widget.onExpenseLogged?.call(logEntry as Expense);
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
          _ChatMessage(
            text: "✅ ${_getSuccessMessage(logEntry)}",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } else {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: "❌ ${_getCancelledMessage(_pendingLog)}",
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
                    max: 32,
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
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
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
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: isDark ? Colors.white : LoggitColors.tealDark,
                        size: Responsive.responsiveIcon(
                          context,
                          28,
                          min: 20,
                          max: 44,
                        ),
                      ),
                      onPressed: _sendMessage,
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
                Positioned(
                  right: 24,
                  bottom: 8,
                  child: PhysicalModel(
                    color: isDark ? LoggitColors.darkCard : Colors.white,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(32),
                    shadowColor: Colors.black.withOpacity(0.18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () => _showLogOptionsSheet(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? LoggitColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: isDark
                              ? LoggitColors.darkText
                              : LoggitColors.darkGrayText,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RemindersScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
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
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
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
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isConfirmation = false,
    this.onConfirmationResponse,
    this.pendingLogEntry,
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

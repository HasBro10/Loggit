import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'features/dashboard/dashboard_screen.dart';
import 'features/expenses/expense_model.dart';
import 'features/tasks/task_model.dart';
import 'features/reminders/reminder_model.dart';
import 'features/notes/note_model.dart';
import 'features/gym/gym_log_model.dart';
import 'models/favorite_feature.dart';
import 'services/favorites_service.dart';
import 'features/chat/chat_screen_new.dart';
import 'features/tasks/tasks_screen_new.dart';
import 'shared/design/color_guide.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/notes/notes_screen.dart';
import 'services/reminders_service.dart';
import 'features/gym/gym_screen.dart';

void main() {
  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => LoggitApp()),
  );
}

class LoggitApp extends StatefulWidget {
  const LoggitApp({super.key});

  @override
  State<LoggitApp> createState() => _LoggitAppState();
}

class _LoggitAppState extends State<LoggitApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loggit',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2563eb), // blue-600
          onPrimary: Colors.white,
          secondary: const Color(0xFF64748b), // slate-500
          onSecondary: Colors.white,
          tertiary: const Color(0xFF22c55e), // green-500
          onTertiary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          error: const Color(0xFFef4444), // red-500
          onError: Colors.white,
        ),
        cardColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.04),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFf1f5f9), // slate-100
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: const Color(0xFF64748b).withOpacity(0.7)),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LoggitColors.darkBg,
        colorScheme: ColorScheme.dark(
          primary: LoggitColors.darkAccent,
          onPrimary: LoggitColors.darkText,
          secondary: LoggitColors.darkCard,
          onSecondary: LoggitColors.darkText,
          surface: LoggitColors.darkCard,
          onSurface: LoggitColors.darkText,
          error: Color(0xFFf87171),
          onError: LoggitColors.darkText,
        ),
        cardColor: LoggitColors.darkCard,
        shadowColor: Colors.black.withOpacity(0.2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: LoggitColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: LoggitColors.darkSubtext),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: LoggitHome(
        onThemeToggle: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class LoggitHome extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  const LoggitHome({
    super.key,
    required this.onThemeToggle,
    required this.currentThemeMode,
  });

  @override
  State<LoggitHome> createState() => _LoggitHomeState();
}

class _LoggitHomeState extends State<LoggitHome> {
  final List<Expense> _expenses = [];
  final List<Task> _tasks = [];
  final List<Reminder> _reminders = [];
  final List<Note> _notes = [];
  final List<GymLog> _gymLogs = [];
  bool _isLoading = true;
  List<FavoriteFeature> _favorites = FavoriteFeature.defaultFavorites;
  bool _favoritesLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadFavorites();
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load expenses
      final expensesJson = prefs.getStringList('expenses') ?? [];
      _expenses.clear();
      for (final expenseString in expensesJson) {
        try {
          final expenseMap = json.decode(expenseString);
          _expenses.add(Expense.fromJson(expenseMap));
        } catch (e) {
          print('Error loading expense: $e');
        }
      }

      // Load tasks
      final tasksJson = prefs.getStringList('tasks') ?? [];
      _tasks.clear();
      for (final taskString in tasksJson) {
        try {
          final taskMap = json.decode(taskString);
          _tasks.add(Task.fromJson(taskMap));
        } catch (e) {
          print('Error loading task: $e');
        }
      }

      // Load reminders
      final remindersJson = prefs.getStringList('reminders') ?? [];
      _reminders.clear();
      for (final reminderString in remindersJson) {
        try {
          final reminderMap = json.decode(reminderString);
          _reminders.add(Reminder.fromJson(reminderMap));
        } catch (e) {
          print('Error loading reminder: $e');
        }
      }

      // Load notes
      final notesJson = prefs.getStringList('notes') ?? [];
      _notes.clear();
      for (final noteString in notesJson) {
        try {
          final noteMap = json.decode(noteString);
          _notes.add(Note.fromJson(noteMap));
        } catch (e) {
          print('Error loading note: $e');
        }
      }

      // Load gym logs
      final gymLogsJson = prefs.getStringList('gymLogs') ?? [];
      _gymLogs.clear();
      for (final gymLogString in gymLogsJson) {
        try {
          final gymLogMap = json.decode(gymLogString);
          _gymLogs.add(GymLog.fromJson(gymLogMap));
        } catch (e) {
          print('Error loading gym log: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesService.loadFavorites();
    setState(() {
      _favorites = favs;
      _favoritesLoading = false;
    });
  }

  Future<void> _toggleFavorite(FeatureType type, bool add) async {
    setState(() {
      _favoritesLoading = true;
    });
    if (add) {
      await FavoritesService.addToFavorites(type);
    } else {
      await FavoritesService.removeFromFavorites(type);
    }
    await _loadFavorites();
  }

  Future<void> _saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = _expenses
          .map((expense) => json.encode(expense.toJson()))
          .toList();
      await prefs.setStringList('expenses', expensesJson);
    } catch (e) {
      print('Error saving expenses: $e');
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks
          .map((task) => json.encode(task.toJson()))
          .toList();
      await prefs.setStringList('tasks', tasksJson);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _reminders
          .map((reminder) => json.encode(reminder.toJson()))
          .toList();
      await prefs.setStringList('reminders', remindersJson);
    } catch (e) {
      print('Error saving reminders: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = _notes
          .map((note) => json.encode(note.toJson()))
          .toList();
      await prefs.setStringList('notes', notesJson);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<void> _saveGymLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gymLogsJson = _gymLogs
          .map((gymLog) => json.encode(gymLog.toJson()))
          .toList();
      await prefs.setStringList('gymLogs', gymLogsJson);
    } catch (e) {
      print('Error saving gym logs: $e');
    }
  }

  void _addExpense(Expense expense) async {
    setState(() {
      _expenses.add(expense);
    });
    await _saveExpenses();
  }

  void _addTask(Task task) async {
    print('[DEBUG] _addTask called with task: ${task.toJson()}');
    print(
      '[DEBUG] Task has repeatDuration: ${task.repeatDuration}, repeatDurationType: ${task.repeatDurationType}',
    );

    // Always add just ONE task (like manual path)
    // The display logic will handle showing the next occurrence
    setState(() {
      _tasks.add(task);
    });
    print('[DEBUG] _tasks length after adding: ${_tasks.length}');
    await _saveTasks();
    print('[DEBUG] Task saved to persistent storage');
  }

  void _addReminder(Reminder reminder) async {
    print('Adding reminder: ${reminder.title} at ${reminder.reminderTime}');
    setState(() {
      _reminders.add(reminder);
    });
    print('Total reminders after adding: ${_reminders.length}');
    await RemindersService.addReminder(reminder);
    print('Reminder saved to persistent storage');
  }

  void _addNote(Note note) async {
    setState(() {
      _notes.add(note);
    });
    await _saveNotes();
  }

  void _addGymLog(GymLog gymLog) async {
    setState(() {
      _gymLogs.add(gymLog);
    });
    await _saveGymLogs();
  }

  String _getThemeModeText() {
    switch (widget.currentThemeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final feature = _favorites.isNotEmpty ? _favorites[_currentTabIndex] : null;
    if (feature == null) {
      return const Center(child: Text('No features available'));
    }
    switch (feature.type) {
      case FeatureType.chat:
        return ChatScreenNew(
          onExpenseLogged: _addExpense,
          onTaskLogged: _addTask,
          onReminderLogged: _addReminder,
          getTasks: () => _tasks,
          onNoteLogged: _addNote,
          onGymLogLogged: _addGymLog,
          onShowTasks: () {
            final tasksIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.tasks,
            );
            if (tasksIndex != -1) {
              setState(() {
                _currentTabIndex = tasksIndex;
              });
            }
          },
          onShowReminders: () {
            final remindersIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.reminders,
            );
            if (remindersIndex != -1) {
              setState(() {
                _currentTabIndex = remindersIndex;
              });
            }
          },
          onShowNotes: () {
            final notesIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.notes,
            );
            if (notesIndex != -1) {
              setState(() {
                _currentTabIndex = notesIndex;
              });
            }
          },
          onShowGym: () {
            final gymIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.gymLogs,
            );
            if (gymIndex != -1) {
              setState(() {
                _currentTabIndex = gymIndex;
              });
            } else {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GymScreen()));
            }
            Navigator.of(context).maybePop();
          },
          onThemeToggle: widget.onThemeToggle,
          currentThemeMode: widget.currentThemeMode,
        );
      case FeatureType.expenses:
        return DashboardScreen(expenses: _expenses);
      case FeatureType.tasks:
        return TasksScreenNew(
          tasks: _tasks,
          onBack: () {
            final chatIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.chat,
            );
            if (chatIndex != -1) {
              setState(() {
                _currentTabIndex = chatIndex;
              });
            }
          },
          onUpdateOrDeleteTask: (Task task, {bool isDelete = false}) async {
            print(
              '[DEBUG] onUpdateOrDeleteTask called. isDelete: $isDelete, task: ${task.toJson()}',
            );
            print(
              '[DEBUG] _tasks before: ${_tasks.map((t) => t.toJson()).toList()}',
            );

            if (isDelete) {
              setState(() {
                _tasks.removeWhere((t) => t.id == task.id);
              });
            } else {
              // Always save just ONE task (like AI path now)
              // The display logic will handle showing the next occurrence
              setState(() {
                final index = _tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  _tasks[index] = task;
                } else {
                  _tasks.add(task);
                }
              });
            }

            print(
              '[DEBUG] _tasks after: ${_tasks.map((t) => t.toJson()).toList()}',
            );
            await _saveTasks();
          },
        );
      case FeatureType.reminders:
        return RemindersScreen(
          onBack: () {
            final chatIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.chat,
            );
            if (chatIndex != -1) {
              setState(() {
                _currentTabIndex = chatIndex;
              });
            }
          },
        );
      case FeatureType.notes:
        return NotesScreen(
          onThemeToggle: widget.onThemeToggle,
          currentThemeMode: widget.currentThemeMode,
          onBackToChat: () {
            final chatIndex = _favorites.indexWhere(
              (f) => f.type == FeatureType.chat,
            );
            if (chatIndex != -1) {
              setState(() {
                _currentTabIndex = chatIndex;
              });
            }
          },
        );
      case FeatureType.gymLogs:
        return const GymScreen();
    }
  }

  Widget _buildGymLogsTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Workouts', Icons.fitness_center, _gymLogs.length),
        if (_gymLogs.isEmpty)
          _buildEmptyState(
            'No workouts yet',
            'Try saying "Squats 3 sets x 10 reps"',
          )
        else
          ..._gymLogs.map((gymLog) => _buildGymLogCard(gymLog)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title, style: theme.textTheme.bodyMedium),
                Text(
                  'Remind at: ${_formatDateTime(reminder.reminderTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymLogCard(GymLog gymLog) {
    final theme = Theme.of(context);
    final exercise = gymLog.exercises.first;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${exercise.sets} sets × ${exercise.reps} reps${exercise.weight != null ? ' @ ${exercise.weight}kg' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} on ${_formatDate(dateTime)}';
  }
}

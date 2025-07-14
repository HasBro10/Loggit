import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/design/widgets/status_card.dart';
import '../../shared/design/widgets/header.dart';
import '../../shared/design/widgets/feature_card_button.dart';
import 'task_model.dart';
import '../../shared/utils/responsive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum TaskSortOption { dueDate, priority, category }

class TasksScreenNew extends StatefulWidget {
  final VoidCallback onBack;
  const TasksScreenNew({super.key, required this.onBack});

  @override
  State<TasksScreenNew> createState() => _TasksScreenNewState();
}

class _TasksScreenNewState extends State<TasksScreenNew> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> closeSwipeOptionsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<Key?> openSwipeCardKey = ValueNotifier<Key?>(null);
  final ValueNotifier<String?> _openDeleteTaskTitle = ValueNotifier<String?>(
    null,
  );

  List<Task> tasks = [];

  String searchQuery = '';
  String statusFilter = 'All';
  String? categoryFilter;
  String? priorityFilter;
  String? recurrenceFilter;
  DateTime? dateFromFilter;
  DateTime? dateToFilter;
  bool showOverdueOnly = false;
  TaskSortOption sortOption = TaskSortOption.dueDate;
  int selectedFilter = 0; // 0 = All, 1 = Pending, 2 = Completed
  int selectedDayIndex = 0; // 0 = Today (default to today)
  late List<String> days;
  late List<int> dates;
  int selectedTabIndex = 0; // 0 = Week, 1 = Month, 2 = All (default to Week)
  int selectedTimeFilter =
      0; // 0 = All Time, 1 = This Week, 2 = This Month, 3 = Next 3 Months, 4 = Overdue

  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // Drag tracking variables for swipe gestures
  final bool _isDragging = false;
  final double _dragStartX = 0;
  final double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _generateDynamicDates();

    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        closeSwipeOptionsNotifier.value++;
      }
    });
  }

  void _generateDynamicDates() {
    final today = DateTime.now();
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    days = [];
    dates = [];

    // Generate 14 days starting from today
    for (int i = 0; i < 14; i++) {
      final date = today.add(Duration(days: i));
      days.add(weekDays[date.weekday % 7]);
      dates.add(date.day);
    }

    // Set selectedDayIndex to 0 to show today's tasks by default
    selectedDayIndex = 0;

    // Generate dummy tasks for testing
    _generateDummyTasks();
  }

  void _generateDummyTasks() {
    tasks = [
      Task(
        title: 'Buy groceries',
        description: 'Milk, eggs, bread, and fruit',
        dueDate: DateTime.now(),
        timestamp: DateTime.now(),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        isCompleted: false,
        category: 'Personal',
        reminder: ReminderType.none,
        recurrenceType: RecurrenceType.none,
      ),
      Task(
        title: 'Team meeting',
        description: 'Weekly sync with the project team',
        dueDate: DateTime.now().add(Duration(days: 1)),
        timestamp: DateTime.now().add(Duration(days: 1)),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        isCompleted: false,
        category: 'Work',
        reminder: ReminderType.none,
        recurrenceType: RecurrenceType.none,
      ),
      Task(
        title: 'Gym session',
        description: 'Leg day workout at the gym',
        dueDate: DateTime.now().add(Duration(days: 3)),
        timestamp: DateTime.now().add(Duration(days: 3)),
        priority: TaskPriority.low,
        status: TaskStatus.notStarted,
        isCompleted: false,
        category: 'Personal',
        reminder: ReminderType.none,
        recurrenceType: RecurrenceType.none,
      ),
      Task(
        title: 'Client call',
        description: 'Call with client to discuss project requirements',
        dueDate: DateTime.now().add(Duration(days: 4)),
        timestamp: DateTime.now().add(Duration(days: 4)),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        isCompleted: false,
        category: 'Business',
        reminder: ReminderType.none,
        recurrenceType: RecurrenceType.none,
      ),
    ];
  }

  bool _isTaskForSelectedDate(Task task, int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= dates.length) return false;

    final today = DateTime.now();
    final selectedDate = today.add(Duration(days: selectedIndex));

    return task.dueDate != null &&
        task.dueDate!.year == selectedDate.year &&
        task.dueDate!.month == selectedDate.month &&
        task.dueDate!.day == selectedDate.day;
  }

  bool _isTaskOverdue(Task task) {
    if (task.dueDate == null || task.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    return dueDate.isBefore(today);
  }

  bool _isTaskDueSoon(Task task) {
    if (task.dueDate == null || task.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    final daysUntilDue = dueDate.difference(today).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 3;
  }

  String _getUserFriendlyDateLabel(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();
    final targetDate = today.add(Duration(days: index));

    // Show consistent day names for all days
    return weekDays[targetDate.weekday % 7];
  }

  String _getSelectedDateContext() {
    if (selectedTabIndex == 1) {
      // Month tab - use the selected date from month view
      final selectedDate = _getSelectedDateForMonthView();
      if (selectedDate != null) {
        final today = DateTime.now();
        final isToday =
            selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day == today.day;
        if (isToday) {
          return 'Today';
        } else {
          return '${_monthString(selectedDate.month)} ${selectedDate.day}';
        }
      }
      return 'Today';
    } else if (selectedDayIndex == 0) {
      return 'Today';
    } else if (selectedDayIndex == 1) {
      return 'Tomorrow';
    } else {
      return '${days[selectedDayIndex]} ${dates[selectedDayIndex]}';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Filter and sort logic
    List<Task> filteredTasks = tasks.where((task) {
      final matchesSearch =
          searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (task.description?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);

      // Status filter
      final matchesStatus = selectedTabIndex == 2
          ? (statusFilter == 'All' ||
                (statusFilter == 'Pending' && !task.isCompleted) ||
                (statusFilter == 'Completed' && task.isCompleted) ||
                (statusFilter == 'Overdue' &&
                    task.dueDate != null &&
                    _isTaskOverdue(task)))
          : (selectedFilter == 0 || // All
                (selectedFilter == 1 && !task.isCompleted) || // Pending
                (selectedFilter == 2 && task.isCompleted)); // Completed

      // Category filter
      final matchesCategory =
          categoryFilter == null || task.category == categoryFilter;

      // Priority filter
      final matchesPriority =
          priorityFilter == null || priorityString(task) == priorityFilter;

      // Recurrence filter
      final matchesRecurrence =
          recurrenceFilter == null ||
          (recurrenceFilter == 'Recurring' &&
              task.recurrenceType != RecurrenceType.none) ||
          (recurrenceFilter == 'One-time' &&
              task.recurrenceType == RecurrenceType.none);

      // Date range filter
      final matchesDateRange =
          (dateFromFilter == null ||
              (task.dueDate != null &&
                  task.dueDate!.isAfter(dateFromFilter!))) &&
          (dateToFilter == null ||
              (task.dueDate != null &&
                  task.dueDate!.isBefore(
                    dateToFilter!.add(Duration(days: 1)),
                  )));

      // Date filter based on selected day
      final matchesSelectedDate =
          selectedDayIndex < 0 ||
          (task.dueDate != null &&
              _isTaskForSelectedDate(task, selectedDayIndex));

      // Overdue filter
      final matchesOverdue =
          !showOverdueOnly || (task.dueDate != null && _isTaskOverdue(task));

      // Due soon filter (due within 3 days)
      final matchesDueSoon =
          statusFilter != 'Due Soon' ||
          (statusFilter == 'Due Soon' && _isTaskDueSoon(task));

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesPriority &&
          matchesRecurrence &&
          matchesDateRange &&
          matchesSelectedDate &&
          matchesOverdue &&
          matchesDueSoon;
    }).toList();

    // Sort
    filteredTasks.sort((a, b) {
      switch (sortOption) {
        case TaskSortOption.dueDate:
          // Get the effective scheduled time for each task
          DateTime getEffectiveTime(Task task) {
            if (task.dueDate == null) return DateTime(2100);

            // If task has a specific timeOfDay, combine it with the dueDate
            if (task.timeOfDay != null) {
              return DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              );
            }

            // Otherwise use the dueDate as is
            return task.dueDate!;
          }

          return getEffectiveTime(a).compareTo(getEffectiveTime(b));
        case TaskSortOption.priority:
          return priorityString(
            b,
          ).compareTo(priorityString(a)); // High > Medium > Low
        case TaskSortOption.category:
          return (a.category ?? '').compareTo(b.category ?? '');
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _openDeleteTaskTitle.value = null,
      child: Scaffold(
        backgroundColor: isDark ? LoggitColors.darkBg : LoggitColors.pureWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Fixed header
              Container(
                padding: const EdgeInsets.all(LoggitSpacing.screenPadding),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark
                            ? Colors.white
                            : LoggitColors.darkGrayText,
                      ),
                      onPressed: () {
                        // Close any open delete button first
                        _openDeleteTaskTitle.value = null;
                        widget.onBack();
                      },
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tasks',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: isDark
                            ? Colors.white
                            : LoggitColors.darkGrayText,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(LoggitSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab navigation
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton('Week', 0, isDark),
                              ),
                              Expanded(
                                child: _buildTabButton('Calendar', 1, isDark),
                              ),
                              Expanded(
                                child: _buildTabButton('All', 2, isDark),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: LoggitSpacing.lg),
                        // Date selector bar with background
                        if (selectedTabIndex == 0) // Week View
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9), // Light background
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height:
                                  76, // Increased height to accommodate border
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: days.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                physics: BouncingScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, i) {
                                  final selected = i == selectedDayIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      // Close any open delete button first
                                      _openDeleteTaskTitle.value = null;
                                      setState(() {
                                        selectedDayIndex = i;
                                        // When a specific date is selected, we're no longer in "All" mode
                                        // Keep the filter as "All" (0) but the visual state will be correct
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 180),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical:
                                            8, // Increased vertical margin
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? LoggitColors.teal.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: (i == 0 || selected)
                                            ? Border.all(
                                                color: LoggitColors.teal,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _getUserFriendlyDateLabel(i),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: selected
                                                  ? Colors.black
                                                  : i == 0
                                                  ? LoggitColors.teal
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            dates[i].toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: selected
                                                  ? Colors.black
                                                  : i == 0
                                                  ? LoggitColors.teal
                                                  : Colors.grey[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else if (selectedTabIndex == 1) // Month View
                          _buildMonthView(isDark)
                        else // All View
                          Column(
                            children: [
                              _buildAllTabSearchBar(isDark),
                              _buildAllTabContextBar(
                                isDark,
                                _getFilteredTasksForAllView().length,
                              ),
                              SizedBox(height: 12),
                              // Simple filter chips below the header
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    _buildSimpleFilterChip(
                                      'All',
                                      'All',
                                      isDark,
                                    ),
                                    SizedBox(width: 8),
                                    _buildSimpleFilterChip(
                                      'Pending',
                                      'Pending',
                                      isDark,
                                    ),
                                    SizedBox(width: 8),
                                    _buildSimpleFilterChip(
                                      'Completed',
                                      'Completed',
                                      isDark,
                                    ),
                                    SizedBox(width: 8),
                                    _buildSimpleFilterChip(
                                      'Overdue',
                                      'Overdue',
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildAllTasksView(isDark),
                            ],
                          ),
                        SizedBox(height: LoggitSpacing.lg),
                        // Date context header (only for Week and Month views)
                        if (selectedTabIndex != 2)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      selectedDayIndex >= 0
                                          ? Icons.calendar_today
                                          : Icons.list_alt,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    RichText(
                                      text: TextSpan(
                                        text:
                                            (selectedTabIndex == 1 &&
                                                    _getSelectedDateForMonthView() !=
                                                        null) ||
                                                selectedDayIndex >= 0
                                            ? _getSelectedDateContext()
                                            : 'All Tasks',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Showing: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      TextSpan(
                                        text: selectedTabIndex == 1
                                            ? '${_getFilteredTasksForMonthView().length}'
                                            : '${filteredTasks.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (selectedTabIndex != 2)
                          SizedBox(height: LoggitSpacing.md),
                        // Tasks section (for Week and Month views)
                        if (selectedTabIndex == 0) ...[
                          if (filteredTasks.isNotEmpty)
                            ...filteredTasks.map(
                              (task) => _buildTaskCard(
                                task,
                                isDark,
                                onTap: () =>
                                    _showTaskModal(context, task: task),
                              ),
                            )
                          else
                            _buildEmptyState(isDark),
                        ] else if (selectedTabIndex == 1) ...[
                          if (_getFilteredTasksForMonthView().isNotEmpty)
                            ..._getFilteredTasksForMonthView().map(
                              (task) => _buildTaskCard(
                                task,
                                isDark,
                                onTap: () =>
                                    _showTaskModal(context, task: task),
                              ),
                            )
                          else
                            _buildEmptyState(isDark),
                        ],
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: LoggitColors.teal,
          onPressed: () {
            // Close any open delete button first
            _openDeleteTaskTitle.value = null;
            _showTaskModal(context);
          },
          child: Icon(Icons.add, color: Colors.white, size: 24),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  List<int> _getAvailableHours(DateTime selectedDate) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (isToday) {
      // For today, only show current hour and future hours
      final currentHour = now.hour;
      return List.generate(24 - currentHour, (i) => currentHour + i);
    } else {
      // For future dates, show all hours
      return List.generate(24, (i) => i);
    }
  }

  int _getInitialHourIndex(DateTime selectedDate, TimeOfDay currentTime) {
    final availableHours = _getAvailableHours(selectedDate);
    final targetHour = currentTime.hour;

    // Find the index of the target hour in available hours
    final index = availableHours.indexOf(targetHour);
    if (index != -1) {
      return index;
    }

    // If target hour is not available (e.g., past time on today), return 0
    return 0;
  }

  List<int> _getAvailableMinutes(DateTime selectedDate, int selectedHour) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (isToday && selectedHour == now.hour) {
      // For current hour today, only show current minute and future minutes
      final currentMinute = now.minute;
      return List.generate(60 - currentMinute, (i) => currentMinute + i);
    } else {
      // For other times, show all minutes
      return List.generate(60, (i) => i);
    }
  }

  int _getInitialMinuteIndex(DateTime selectedDate, TimeOfDay currentTime) {
    final availableMinutes = _getAvailableMinutes(
      selectedDate,
      currentTime.hour,
    );
    final targetMinute = currentTime.minute;

    // Find the index of the target minute in available minutes
    final index = availableMinutes.indexOf(targetMinute);
    if (index != -1) {
      return index;
    }

    // If target minute is not available, return 0
    return 0;
  }

  void _showTaskModal(BuildContext context, {Task? task}) async {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime? dueDate = task?.dueDate;
    TimeOfDay? timeOfDay = task?.timeOfDay;
    String? category = task?.category;
    bool isCompleted = task?.isCompleted ?? false;
    TaskPriority priority = task?.priority ?? TaskPriority.medium;
    TaskStatus status = task?.status ?? TaskStatus.notStarted;
    ReminderType reminder = task?.reminder ?? ReminderType.none;

    // In the modal's state, add these variables:
    bool showTitleError = false;
    bool showCategoryError = false;
    bool showDateTimeError = false;

    // In the modal's state, add a variable for recurrence type:
    RecurrenceType recurrenceType = task?.recurrenceType ?? RecurrenceType.none;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            String? error;
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: SafeArea(
                child: Column(
                  children: [
                    // Fixed handle and header at the top
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
                            isEditing ? 'Edit Task' : 'Add Task',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content below
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            LoggitSpacing.screenPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 20),
                              Text(
                                'Title',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? LoggitColors.darkCard
                                      : Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: showTitleError
                                        ? BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: showTitleError
                                        ? BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          )
                                        : BorderSide(
                                            color: LoggitColors.teal,
                                            width: 2,
                                          ),
                                  ),
                                  hintText: 'Enter title',
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              if (showTitleError)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 18),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              TextField(
                                controller: descController,
                                minLines: 1,
                                maxLines: 5, // allow up to 5 lines
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? LoggitColors.darkCard
                                      : Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter description',
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: category,
                                items: ['Work', 'Personal', 'Business']
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : LoggitColors.darkGrayText,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setModalState(() => category = val),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? LoggitColors.darkCard
                                      : Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: showCategoryError
                                        ? BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: showCategoryError
                                        ? BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          )
                                        : BorderSide(
                                            color: LoggitColors.teal,
                                            width: 2,
                                          ),
                                  ),
                                  hintText: 'Select category',
                                  // Remove errorText here
                                ),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : LoggitColors.darkGrayText,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                              if (showCategoryError)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 18),
                              // Date & Time buttons - separate pill buttons
                              Row(
                                children: [
                                  // Date button
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: showDateTimeError
                                              ? Colors.red
                                              : Colors.grey[300]!,
                                          width: showDateTimeError ? 2 : 1,
                                        ),
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await _showDatePicker(
                                            context,
                                            initialDate:
                                                dueDate ?? DateTime.now(),
                                            onDateChanged: (date) {
                                              setModalState(() {
                                                dueDate = date;
                                                showDateTimeError = false;
                                              });
                                            },
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 18,
                                              color: LoggitColors.teal,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              dueDate == null
                                                  ? 'Pick Date'
                                                  : '${weekdayString(dueDate!.weekday)}, ${dueDate!.day} ${_monthString(dueDate!.month)}',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : LoggitColors.darkGrayText,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  // Time button
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: showDateTimeError
                                              ? Colors.red
                                              : Colors.grey[300]!,
                                          width: showDateTimeError ? 2 : 1,
                                        ),
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await _showTimePicker(
                                            context,
                                            initialTime:
                                                timeOfDay ?? TimeOfDay.now(),
                                            onTimeChanged: (time) {
                                              setModalState(() {
                                                timeOfDay = time;
                                                showDateTimeError = false;
                                              });
                                            },
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 18,
                                              color: LoggitColors.teal,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              timeOfDay == null
                                                  ? 'Pick Time'
                                                  : timeOfDay!.format(context),
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : LoggitColors.darkGrayText,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (showDateTimeError)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 18),
                              // Remove the Completed checkbox row:
                              // Row(
                              //   children: [
                              //     Checkbox(
                              //       value: isCompleted,
                              //       onChanged: (val) => setModalState(
                              //         () => isCompleted = val ?? false,
                              //       ),
                              //       activeColor: LoggitColors.teal,
                              //     ),
                              //     Text(
                              //       'Completed',
                              //       style: TextStyle(fontSize: 15),
                              //     ),
                              //   ],
                              // ),
                              SizedBox(height: 18),

                              // Priority
                              Text(
                                'Priority',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PriorityChip(
                                      label: 'Low',
                                      color: Colors.green,
                                      isSelected: priority == TaskPriority.low,
                                      onTap: () => setModalState(
                                        () => priority = TaskPriority.low,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _PriorityChip(
                                      label: 'Medium',
                                      color: Colors.orange,
                                      isSelected:
                                          priority == TaskPriority.medium,
                                      onTap: () => setModalState(
                                        () => priority = TaskPriority.medium,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _PriorityChip(
                                      label: 'High',
                                      color: Colors.red,
                                      isSelected: priority == TaskPriority.high,
                                      onTap: () => setModalState(
                                        () => priority = TaskPriority.high,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18),

                              // Status
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              DropdownButtonFormField<TaskStatus>(
                                value: status,
                                items: TaskStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          _getStatusText(s),
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : LoggitColors.darkGrayText,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                selectedItemBuilder: (context) => TaskStatus
                                    .values
                                    .map(
                                      (s) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _getStatusText(s),
                                          style: TextStyle(
                                            color:
                                                (s == TaskStatus.inProgress ||
                                                    s == TaskStatus.completed)
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white
                                                      : LoggitColors
                                                            .darkGrayText),
                                            fontWeight:
                                                (s == TaskStatus.inProgress ||
                                                    s == TaskStatus.completed)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setModalState(
                                  () => status = val ?? TaskStatus.notStarted,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: status == TaskStatus.inProgress
                                      ? Colors.orange
                                      : status == TaskStatus.completed
                                      ? LoggitColors.teal
                                      : (isDark
                                            ? LoggitColors.darkCard
                                            : Color(0xFFF1F5F9)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: status == null
                                      ? 'Select status'
                                      : null,
                                ),
                                style: TextStyle(
                                  color:
                                      (status == TaskStatus.inProgress ||
                                          status == TaskStatus.completed)
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText),
                                  fontWeight:
                                      (status == TaskStatus.inProgress ||
                                          status == TaskStatus.completed)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color:
                                      (status == TaskStatus.inProgress ||
                                          status == TaskStatus.completed)
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText),
                                ),
                              ),
                              SizedBox(height: 18),

                              // Reminder
                              Text(
                                'Set Reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              DropdownButtonFormField<ReminderType>(
                                value: reminder,
                                items: ReminderType.values
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          _getReminderText(r),
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : LoggitColors.darkGrayText,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setModalState(
                                  () => reminder = val ?? ReminderType.none,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? LoggitColors.darkCard
                                      : Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Select reminder',
                                ),
                              ),
                              SizedBox(height: 18),

                              // Recurring
                              Text(
                                'Repeat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              DropdownButtonFormField<RecurrenceType>(
                                value: recurrenceType,
                                items: [
                                  DropdownMenuItem(
                                    value: RecurrenceType.none,
                                    child: Text(
                                      'None',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: RecurrenceType.daily,
                                    child: Text(
                                      'Daily',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: RecurrenceType.weekly,
                                    child: Text(
                                      'Weekly',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: RecurrenceType.monthly,
                                    child: Text(
                                      'Monthly',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setModalState(
                                  () => recurrenceType =
                                      val ?? RecurrenceType.none,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? LoggitColors.darkCard
                                      : Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Select repeat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: LoggitSpacing.screenPadding,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: Responsive.responsiveFont(
                                context,
                                48,
                                min: 44,
                                max: 60,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  side: BorderSide(
                                    color: Colors.black26,
                                    width: 1,
                                  ),
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.responsiveFont(
                                      context,
                                      16,
                                      min: 14,
                                      max: 20,
                                    ),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: Responsive.responsiveFont(
                                context,
                                48,
                                min: 44,
                                max: 60,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LoggitColors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.responsiveFont(
                                      context,
                                      16,
                                      min: 14,
                                      max: 20,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    showTitleError = titleController.text
                                        .trim()
                                        .isEmpty;
                                    showCategoryError =
                                        category == null ||
                                        category?.trim().isEmpty == true;
                                    showDateTimeError =
                                        dueDate == null || timeOfDay == null;
                                  });
                                  if (showTitleError ||
                                      showCategoryError ||
                                      showDateTimeError) {
                                    return;
                                  }
                                  // Validate mandatory fields
                                  if (titleController.text.trim().isEmpty) {
                                    setModalState(() {
                                      error = 'Title is required.';
                                    });
                                    return;
                                  }
                                  if (category == null ||
                                      category?.trim().isEmpty == true) {
                                    setModalState(() {
                                      error = 'Category is required.';
                                    });
                                    return;
                                  }
                                  if (dueDate == null || timeOfDay == null) {
                                    setModalState(() {
                                      error = 'Date & Time is required.';
                                    });
                                    return;
                                  }
                                  setModalState(() {
                                    error = null;
                                  });
                                  final newTask = Task(
                                    title: titleController.text,
                                    description: descController.text,
                                    dueDate: dueDate,
                                    isCompleted: status == TaskStatus.completed,
                                    timestamp: DateTime.now(),
                                    category: category,
                                    recurrenceType: recurrenceType,
                                    timeOfDay: timeOfDay,
                                    priority: priority,
                                    status: status,
                                    reminder: reminder,
                                  );
                                  setState(() {
                                    if (isEditing) {
                                      final idx = tasks.indexOf(task);
                                      if (idx != -1) tasks[idx] = newTask;
                                    } else {
                                      tasks.add(newTask);
                                    }
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Text(isEditing ? 'Save' : 'Add'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Local state for the modal
        String localStatusFilter = statusFilter;
        String? localCategoryFilter = categoryFilter;
        String? localPriorityFilter = priorityFilter;
        String? localRecurrenceFilter = recurrenceFilter;
        bool localShowOverdueOnly = showOverdueOnly;

        return FractionallySizedBox(
          widthFactor: 1.0,
          child: SafeArea(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.95,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return Column(
                        children: [
                          // Fixed handle and header at the top
                          SizedBox(
                            height:
                                48, // slightly taller to fit handle and title
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 36,
                                  height: 4,
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? LoggitColors.darkBorder
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Text(
                                  'Filter Tasks',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Scrollable filter content below
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 20),

                                    // Category Filters
                                    Text(
                                      'Category',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: Responsive.responsiveFont(
                                          context,
                                          13,
                                          min: 11,
                                          max: 15,
                                        ),
                                        color: isDark
                                            ? Colors.white70
                                            : LoggitColors.darkGrayText
                                                  .withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    _FilterCheckbox(
                                      label: 'All Categories',
                                      value: localCategoryFilter == null,
                                      onChanged: (val) {
                                        setModalState(
                                          () => localCategoryFilter = null,
                                        );
                                      },
                                      isDark: isDark,
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        13,
                                        min: 11,
                                        max: 14,
                                      ),
                                    ),
                                    _FilterCheckbox(
                                      label: 'Work',
                                      value: localCategoryFilter == 'Work',
                                      onChanged: (val) {
                                        setModalState(
                                          () => localCategoryFilter = 'Work',
                                        );
                                      },
                                      isDark: isDark,
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        13,
                                        min: 11,
                                        max: 14,
                                      ),
                                    ),
                                    _FilterCheckbox(
                                      label: 'Personal',
                                      value: localCategoryFilter == 'Personal',
                                      onChanged: (val) {
                                        setModalState(
                                          () =>
                                              localCategoryFilter = 'Personal',
                                        );
                                      },
                                      isDark: isDark,
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        13,
                                        min: 11,
                                        max: 14,
                                      ),
                                    ),
                                    _FilterCheckbox(
                                      label: 'Business',
                                      value: localCategoryFilter == 'Business',
                                      onChanged: (val) {
                                        setModalState(
                                          () =>
                                              localCategoryFilter = 'Business',
                                        );
                                      },
                                      isDark: isDark,
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        13,
                                        min: 11,
                                        max: 14,
                                      ),
                                    ),

                                    SizedBox(height: 8),
                                    Divider(
                                      color: isDark
                                          ? LoggitColors.darkBorder
                                          : LoggitColors.divider,
                                    ),
                                    SizedBox(height: 8),

                                    // Priority & Recurrence in a row
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Priority',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      Responsive.responsiveFont(
                                                        context,
                                                        13,
                                                        min: 11,
                                                        max: 15,
                                                      ),
                                                  color: isDark
                                                      ? Colors.white70
                                                      : LoggitColors
                                                            .darkGrayText
                                                            .withOpacity(0.7),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              _FilterCheckbox(
                                                label: 'All',
                                                value:
                                                    localPriorityFilter == null,
                                                onChanged: (val) {
                                                  setModalState(
                                                    () => localPriorityFilter =
                                                        null,
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                              _FilterCheckbox(
                                                label: 'High',
                                                value:
                                                    localPriorityFilter ==
                                                    'High Priority',
                                                onChanged: (val) {
                                                  setModalState(
                                                    () => localPriorityFilter =
                                                        'High Priority',
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                              _FilterCheckbox(
                                                label: 'Medium',
                                                value:
                                                    localPriorityFilter ==
                                                    'Medium Priority',
                                                onChanged: (val) {
                                                  setModalState(
                                                    () => localPriorityFilter =
                                                        'Medium Priority',
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                              _FilterCheckbox(
                                                label: 'Low',
                                                value:
                                                    localPriorityFilter ==
                                                    'Low Priority',
                                                onChanged: (val) {
                                                  setModalState(
                                                    () => localPriorityFilter =
                                                        'Low Priority',
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Recurrence',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      Responsive.responsiveFont(
                                                        context,
                                                        13,
                                                        min: 11,
                                                        max: 15,
                                                      ),
                                                  color: isDark
                                                      ? Colors.white70
                                                      : LoggitColors
                                                            .darkGrayText
                                                            .withOpacity(0.7),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              _FilterCheckbox(
                                                label: 'All',
                                                value:
                                                    localRecurrenceFilter ==
                                                    null,
                                                onChanged: (val) {
                                                  setModalState(
                                                    () =>
                                                        localRecurrenceFilter =
                                                            null,
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                              _FilterCheckbox(
                                                label: 'One-time',
                                                value:
                                                    localRecurrenceFilter ==
                                                    'One-time',
                                                onChanged: (val) {
                                                  setModalState(
                                                    () =>
                                                        localRecurrenceFilter =
                                                            'One-time',
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                              _FilterCheckbox(
                                                label: 'Recurring',
                                                value:
                                                    localRecurrenceFilter ==
                                                    'Recurring',
                                                onChanged: (val) {
                                                  setModalState(
                                                    () =>
                                                        localRecurrenceFilter =
                                                            'Recurring',
                                                  );
                                                },
                                                isDark: isDark,
                                                fontSize:
                                                    Responsive.responsiveFont(
                                                      context,
                                                      12,
                                                      min: 10,
                                                      max: 13,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Fixed buttons at the bottom
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? LoggitColors.darkCard
                                  : Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: isDark
                                      ? LoggitColors.darkBorder
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: Responsive.responsiveFont(
                                          context,
                                          13,
                                          min: 11,
                                          max: 15,
                                        ),
                                      ),
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.transparent,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? LoggitColors.darkAccent
                                          : LoggitColors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: Responsive.responsiveFont(
                                          context,
                                          14,
                                          min: 12,
                                          max: 16,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Apply the local state to the main state
                                      setState(() {
                                        statusFilter = localStatusFilter;
                                        categoryFilter = localCategoryFilter;
                                        priorityFilter = localPriorityFilter;
                                        recurrenceFilter =
                                            localRecurrenceFilter;
                                        showOverdueOnly = localShowOverdueOnly;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateTimePicker(
    BuildContext context, {
    required DateTime? initialDate,
    required TimeOfDay? initialTime,
    required ValueChanged<DateTime> onDateTimeChanged,
  }) async {
    final now = DateTime.now();

    // Handle initial date - if it's in the past, use today
    DateTime tempDate;
    if (initialDate != null &&
        initialDate.isBefore(DateTime(now.year, now.month, now.day))) {
      tempDate = DateTime(now.year, now.month, now.day);
    } else {
      tempDate = initialDate ?? DateTime(now.year, now.month, now.day);
    }

    // Handle initial time - if it's in the past for today, use current time
    TimeOfDay tempTime;
    if (tempDate.year == now.year &&
        tempDate.month == now.month &&
        tempDate.day == now.day) {
      // If it's today, ensure time is not in the past
      if (initialTime != null) {
        final initialDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          initialTime.hour,
          initialTime.minute,
        );
        if (initialDateTime.isBefore(now)) {
          tempTime = TimeOfDay(hour: now.hour, minute: now.minute);
        } else {
          tempTime = initialTime;
        }
      } else {
        tempTime = TimeOfDay(hour: now.hour, minute: now.minute);
      }
    } else {
      tempTime =
          initialTime ??
          TimeOfDay(hour: 9, minute: 0); // Default to 9:00 AM for future dates
    }

    // Calculate the initial date index based on the tempDate
    final initialDateIndex = tempDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    // Ensure the index is within bounds (0-4)
    final safeInitialDateIndex = initialDateIndex.clamp(0, 29);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? LoggitColors.darkCard : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                    ),
                  ),
                  SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setPickerState) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final pickerHeight = (constraints.maxHeight - 120)
                              .clamp(100.0, 140.0);
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  isDark
                                      ? LoggitColors.darkCard
                                      : Colors.grey[50]!,
                                  isDark
                                      ? LoggitColors.darkCard.withOpacity(0.8)
                                      : Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: LoggitColors.teal.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Date picker wheel
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: LoggitColors.teal,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        height: pickerHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: isDark
                                              ? LoggitColors.darkCard
                                              : Colors.white,
                                          border: Border.all(
                                            color: LoggitColors.teal
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: CupertinoPicker(
                                          scrollController:
                                              FixedExtentScrollController(
                                                initialItem:
                                                    safeInitialDateIndex,
                                              ),
                                          itemExtent: 40,
                                          onSelectedItemChanged: (index) {
                                            // Calculate the actual date based on the selected index (starting from today)
                                            final baseDate = DateTime.now();
                                            final selectedDate = baseDate.add(
                                              Duration(days: index),
                                            );
                                            tempDate = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              selectedDate.day,
                                            );

                                            // Update tempTime to ensure it's valid for the new date
                                            final now = DateTime.now();
                                            if (tempDate.year == now.year &&
                                                tempDate.month == now.month &&
                                                tempDate.day == now.day) {
                                              // If it's today, ensure time is not in the past
                                              final currentTime = TimeOfDay(
                                                hour: now.hour,
                                                minute: now.minute,
                                              );
                                              if (tempTime.hour < now.hour ||
                                                  (tempTime.hour == now.hour &&
                                                      tempTime.minute <
                                                          now.minute)) {
                                                tempTime = currentTime;
                                              }
                                            }

                                            setPickerState(
                                              () {},
                                            ); // Rebuild the time pickers
                                          },
                                          children: List.generate(30, (i) {
                                            final date = DateTime.now().add(
                                              Duration(days: i),
                                            );
                                            final isSelected =
                                                i == safeInitialDateIndex;
                                            return Center(
                                              child: Text(
                                                '${weekdayString(date.weekday)}, ${date.day} ${_monthString(date.month)}',
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : LoggitColors
                                                            .darkGrayText,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Time picker wheels
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: LoggitColors.teal,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        height: pickerHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: isDark
                                              ? LoggitColors.darkCard
                                              : Colors.white,
                                          border: Border.all(
                                            color: LoggitColors.teal
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController:
                                                    FixedExtentScrollController(
                                                      initialItem:
                                                          _getInitialHourIndex(
                                                            tempDate,
                                                            tempTime,
                                                          ),
                                                    ),
                                                itemExtent: 40,
                                                onSelectedItemChanged: (index) {
                                                  final availableHours =
                                                      _getAvailableHours(
                                                        tempDate,
                                                      );
                                                  if (index <
                                                      availableHours.length) {
                                                    tempTime = TimeOfDay(
                                                      hour:
                                                          availableHours[index],
                                                      minute: tempTime.minute,
                                                    );
                                                  }
                                                },
                                                children: _getAvailableHours(tempDate)
                                                    .map(
                                                      (hour) => Center(
                                                        child: Text(
                                                          hour
                                                              .toString()
                                                              .padLeft(2, '0'),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: isDark
                                                                ? Colors.white
                                                                : LoggitColors
                                                                      .darkGrayText,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                            Text(
                                              ':',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: LoggitColors.teal,
                                              ),
                                            ),
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController:
                                                    FixedExtentScrollController(
                                                      initialItem:
                                                          _getInitialMinuteIndex(
                                                            tempDate,
                                                            tempTime,
                                                          ),
                                                    ),
                                                itemExtent: 40,
                                                onSelectedItemChanged: (index) {
                                                  final availableMinutes =
                                                      _getAvailableMinutes(
                                                        tempDate,
                                                        tempTime.hour,
                                                      );
                                                  if (index <
                                                      availableMinutes.length) {
                                                    tempTime = TimeOfDay(
                                                      hour: tempTime.hour,
                                                      minute:
                                                          availableMinutes[index],
                                                    );
                                                  }
                                                },
                                                children:
                                                    _getAvailableMinutes(
                                                          tempDate,
                                                          tempTime.hour,
                                                        )
                                                        .map(
                                                          (minute) => Center(
                                                            child: Text(
                                                              minute
                                                                  .toString()
                                                                  .padLeft(
                                                                    2,
                                                                    '0',
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                color: isDark
                                                                    ? Colors
                                                                          .white
                                                                    : LoggitColors
                                                                          .darkGrayText,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  // Enhanced buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: LoggitColors.teal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: LoggitColors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                LoggitColors.teal,
                                LoggitColors.teal.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: LoggitColors.teal.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              final selectedDateTime = DateTime(
                                tempDate.year,
                                tempDate.month,
                                tempDate.day,
                                tempTime.hour,
                                tempTime.minute,
                              );
                              onDateTimeChanged(selectedDateTime);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) async {
    TimeOfDay tempTime = initialTime;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 350, minWidth: 280),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? LoggitColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : LoggitColors.darkGrayText,
                  ),
                ),
                SizedBox(height: 20),
                StatefulBuilder(
                  builder: (context, setPickerState) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark ? LoggitColors.darkCard : Colors.grey[50]!,
                            isDark
                                ? LoggitColors.darkCard.withOpacity(0.8)
                                : Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: LoggitColors.teal.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: tempTime.hour,
                                ),
                                itemExtent: 30,
                                onSelectedItemChanged: (index) {
                                  setPickerState(() {
                                    tempTime = TimeOfDay(
                                      hour: index,
                                      minute: tempTime.minute,
                                    );
                                  });
                                },
                                children: List.generate(
                                  24,
                                  (i) => Center(
                                    child: Text(
                                      i.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ':',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: LoggitColors.teal,
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: tempTime.minute,
                                ),
                                itemExtent: 30,
                                onSelectedItemChanged: (index) {
                                  setPickerState(() {
                                    tempTime = TimeOfDay(
                                      hour: tempTime.hour,
                                      minute: index,
                                    );
                                  });
                                },
                                children: List.generate(
                                  60,
                                  (i) => Center(
                                    child: Text(
                                      i.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : LoggitColors.darkGrayText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                // Enhanced buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: LoggitColors.teal.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              LoggitColors.teal,
                              LoggitColors.teal.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: LoggitColors.teal.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            onTimeChanged(tempTime);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String emptyTitle, emptySubtitle, emptyIcon = '';

    if (tasks.isEmpty) {
      // No tasks at all
      emptyTitle = 'No tasks yet';
      emptySubtitle = 'Tap the + button to create your first task';
      emptyIcon = '📋';
    } else if (selectedDayIndex >= 0) {
      // No tasks for selected date
      emptyTitle = 'No tasks for ${_getSelectedDateContext()}';
      emptySubtitle = 'Tap the + button to add a task for this day';
      emptyIcon = '📋';
    } else if (searchQuery.isNotEmpty) {
      // No search results
      emptyTitle = 'No matching tasks';
      emptySubtitle = 'Try adjusting your search terms';
      emptyIcon = '📋';
    } else if (selectedFilter == 1) {
      // No pending tasks
      emptyTitle = 'No pending tasks';
      emptySubtitle = 'All tasks are completed!';
      emptyIcon = '📋';
    } else if (selectedFilter == 2) {
      // No completed tasks
      emptyTitle = 'No completed tasks';
      emptySubtitle = 'Complete some tasks to see them here';
      emptyIcon = '📋';
    } else if (selectedDayIndex < 0) {
      // No tasks in "All Tasks" mode
      emptyTitle = 'No tasks found';
      emptySubtitle = 'Try selecting a specific date or add new tasks';
      emptyIcon = '📋';
    } else {
      // No tasks (fallback)
      emptyTitle = 'No tasks found';
      emptySubtitle = 'Try adjusting your filters or add new tasks';
      emptyIcon = '📋';
    }

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              emptyIcon,
              style: TextStyle(fontSize: 64),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : LoggitColors.darkGrayText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, bool isDark) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        // Close any open delete button first
        _openDeleteTaskTitle.value = null;
        setState(() {
          selectedTabIndex = index;
          // Reset to current date when switching tabs
          if (index == 0) {
            // Week tab - select today
            selectedDayIndex = 0;
          } else if (index == 1) {
            // Month tab - always reset to today and current month
            selectedDayIndex = 0;
            _displayedMonth = DateTime(
              DateTime.now().year,
              DateTime.now().month,
            );
            _selectedDateForMonthView = DateTime.now();
          } else if (index == 2) {
            // All tab - select today and reset filter to "All"
            selectedDayIndex = 0;
            statusFilter = 'All';
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? LoggitColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthView(bool isDark) {
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month header
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
                  onPressed: () {
                    // Close any open delete button first
                    _openDeleteTaskTitle.value = null;
                    setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month - 1,
                      );
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    int tempMonth = _displayedMonth.month;
                    int tempYear = _displayedMonth.year;
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Container(
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 20,
                                bottom:
                                    20 +
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? LoggitColors.darkCard
                                    : Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Handle bar
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Select Month & Year',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.white
                                          : LoggitColors.darkGrayText,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Picker container with gradient background
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          isDark
                                              ? LoggitColors.darkCard
                                              : Colors.grey[50]!,
                                          isDark
                                              ? LoggitColors.darkCard
                                                    .withOpacity(0.8)
                                              : Colors.white,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: LoggitColors.teal.withOpacity(
                                          0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Month',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: LoggitColors.teal,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: isDark
                                                      ? LoggitColors.darkCard
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: LoggitColors.teal
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: CupertinoPicker(
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                        initialItem:
                                                            tempMonth - 1,
                                                      ),
                                                  itemExtent: 36,
                                                  onSelectedItemChanged:
                                                      (index) {
                                                        setModalState(() {
                                                          tempMonth = index + 1;
                                                        });
                                                      },
                                                  children: List.generate(
                                                    12,
                                                    (i) => Center(
                                                      child: Text(
                                                        _getMonthName(i + 1),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? Colors.white
                                                              : LoggitColors
                                                                    .darkGrayText,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Year',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: LoggitColors.teal,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: isDark
                                                      ? LoggitColors.darkCard
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: LoggitColors.teal
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: CupertinoPicker(
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                        initialItem:
                                                            tempYear -
                                                            (DateTime.now()
                                                                    .year -
                                                                10),
                                                      ),
                                                  itemExtent: 36,
                                                  onSelectedItemChanged:
                                                      (index) {
                                                        setModalState(() {
                                                          tempYear =
                                                              DateTime.now()
                                                                  .year -
                                                              10 +
                                                              index;
                                                        });
                                                      },
                                                  children: List.generate(
                                                    21,
                                                    (i) => Center(
                                                      child: Text(
                                                        (DateTime.now().year -
                                                                10 +
                                                                i)
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? Colors.white
                                                              : LoggitColors
                                                                    .darkGrayText,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Enhanced buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: LoggitColors.teal
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: LoggitColors.teal,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                LoggitColors.teal,
                                                LoggitColors.teal.withOpacity(
                                                  0.8,
                                                ),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: LoggitColors.teal
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _displayedMonth = DateTime(
                                                  tempYear,
                                                  tempMonth,
                                                );
                                              });
                                              Navigator.of(context).pop();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Apply',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  onPressed: () {
                    // Close any open delete button first
                    _openDeleteTaskTitle.value = null;
                    setState(() {
                      _displayedMonth = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          // Weekday headers
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: 8),
          // Calendar grid with swipe gestures
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final velocityThreshold = 300.0;
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > velocityThreshold) {
                // Swipe right - previous month
                setState(() {
                  _displayedMonth = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month - 1,
                  );
                });
              } else if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -velocityThreshold) {
                // Swipe left - next month
                setState(() {
                  _displayedMonth = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month + 1,
                  );
                });
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(6, (weekIndex) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final dayNumber =
                          weekIndex * 7 + dayIndex - firstWeekday + 1;
                      final isValidDay =
                          dayNumber > 0 && dayNumber <= daysInMonth;
                      final today = DateTime.now();
                      final isToday =
                          dayNumber == today.day &&
                          _displayedMonth.month == today.month &&
                          _displayedMonth.year == today.year;
                      final selectedDate = _getSelectedDateForMonthView();
                      final isSelected =
                          selectedDate != null &&
                          dayNumber == selectedDate.day &&
                          _displayedMonth.month == selectedDate.month &&
                          _displayedMonth.year == selectedDate.year;
                      final hasTasks = tasks.any(
                        (task) =>
                            task.dueDate != null &&
                            task.dueDate!.year == _displayedMonth.year &&
                            task.dueDate!.month == _displayedMonth.month &&
                            task.dueDate!.day == dayNumber,
                      );

                      return Expanded(
                        child: GestureDetector(
                          onTap: isValidDay
                              ? () {
                                  // Close any open delete button first
                                  _openDeleteTaskTitle.value = null;
                                  setState(() {
                                    // Set the selected date for month view
                                    _setSelectedDateForMonthView(
                                      DateTime(
                                        _displayedMonth.year,
                                        _displayedMonth.month,
                                        dayNumber,
                                      ),
                                    );
                                  });
                                }
                              : null,
                          child: Container(
                            height: 36,
                            margin: EdgeInsets.symmetric(vertical: 0.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LoggitColors.teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isToday
                                  ? Border.all(
                                      color: LoggitColors.teal,
                                      width: 2,
                                    )
                                  : isSelected
                                  ? Border.all(
                                      color: LoggitColors.teal,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isValidDay ? dayNumber.toString() : '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : isValidDay
                                        ? (isDark ? Colors.white : Colors.black)
                                        : Colors.transparent,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  height: 6,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasTasks
                                        ? LoggitColors.teal
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 16),
          // No task cards or messages here!
        ],
      ),
    );
  }

  // Add these helper methods for month view date selection
  DateTime? _selectedDateForMonthView;

  DateTime? _getSelectedDateForMonthView() {
    return _selectedDateForMonthView;
  }

  void _setSelectedDateForMonthView(DateTime date) {
    _selectedDateForMonthView = date;
    // Also update the selectedDayIndex for compatibility with existing logic
    final today = DateTime.now();
    final daysDifference = date.difference(today).inDays;
    // Only set selectedDayIndex if it's within the 7-day range
    if (daysDifference >= 0 && daysDifference < 7) {
      selectedDayIndex = daysDifference;
    } else {
      selectedDayIndex = -1; // Use -1 to indicate "all tasks" mode
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  bool _hasTasksOnDate(DateTime date) {
    return tasks.any(
      (task) =>
          task.dueDate != null &&
          task.dueDate!.year == date.year &&
          task.dueDate!.month == date.month &&
          task.dueDate!.day == date.day,
    );
  }

  Widget _buildAllTasksView(bool isDark) {
    final filteredTasks = _getFilteredTasksForAllView();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredTasks.isNotEmpty)
          ...filteredTasks.map(
            (task) => _buildTaskCard(
              task,
              isDark,
              onTap: () => _showTaskModal(context, task: task),
            ),
          )
        else
          _buildEmptyState(isDark),
      ],
    );
  }

  Widget _buildTimeFilterChip(String label, int index, bool isDark) {
    final isSelected = selectedTimeFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LoggitColors.teal.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: LoggitColors.teal, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark, {VoidCallback? onTap}) {
    return Stack(
      children: [
        OverlayDeleteTaskCard(
          task: task,
          isDark: isDark,
          onDelete: () {
            setState(() {
              tasks.remove(task);
            });
          },
          onTap: onTap,
          openDeleteTaskTitle: _openDeleteTaskTitle,
          child: GestureDetector(
            onTap: onTap,
            child: StatefulBuilder(
              builder: (context, setCardState) {
                bool isPressed = false;
                return GestureDetector(
                  onTap: onTap,
                  onTapDown: (_) => setCardState(() => isPressed = true),
                  onTapUp: (_) => setCardState(() => isPressed = false),
                  onTapCancel: () => setCardState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 120),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? LoggitColors.darkBg
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor(
                          task.priority,
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: isPressed
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 1,
                                offset: Offset(0, 0.5),
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vertically center the priority indicator
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: Responsive.responsiveFont(
                                    context,
                                    18,
                                    min: 15,
                                    max: 24,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : LoggitColors.darkGrayText,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (task.description != null &&
                                  task.description!.isNotEmpty) ...[
                                SizedBox(height: 6),
                                Text(
                                  task.description!,
                                  style: TextStyle(
                                    fontSize: Responsive.responsiveFont(
                                      context,
                                      15,
                                      min: 13,
                                      max: 20,
                                    ),
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  if (task.category != null) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          task.category!,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        task.category!,
                                        style: TextStyle(
                                          fontSize: Responsive.responsiveFont(
                                            context,
                                            13,
                                            min: 12,
                                            max: 18,
                                          ),
                                          color: _getCategoryColor(
                                            task.category!,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                  if (task.dueDate != null) ...[
                                    Icon(
                                      Icons.calendar_today,
                                      size: Responsive.responsiveFont(
                                        context,
                                        16,
                                        min: 14,
                                        max: 22,
                                      ),
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      _formatDateDayMonthYear(task.dueDate!),
                                      style: TextStyle(
                                        fontSize: Responsive.responsiveFont(
                                          context,
                                          13,
                                          min: 12,
                                          max: 18,
                                        ),
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (task.timeOfDay != null) ...[
                                      SizedBox(width: 8),
                                      Text(
                                        task.timeOfDay!.format(context),
                                        style: TextStyle(
                                          fontSize: Responsive.responsiveFont(
                                            context,
                                            13,
                                            min: 12,
                                            max: 18,
                                          ),
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Circle checkbox in top right corner - outside the overlay
        Positioned(
          top: 24,
          right: 20,
          child: ValueListenableBuilder<String?>(
            valueListenable: _openDeleteTaskTitle,
            builder: (context, openDeleteTaskTitle, child) {
              // Hide checkbox when delete button is open for this task
              final isVisible = openDeleteTaskTitle != task.title;

              return AnimatedOpacity(
                duration: Duration(milliseconds: 200),
                opacity: isVisible ? 1.0 : 0.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    print('Checkbox tapped for task: ${task.title}');
                    final shouldToggle = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              task.isCompleted
                                  ? Icons.undo
                                  : Icons.check_circle,
                              color: task.isCompleted
                                  ? Colors.orange
                                  : Colors.green,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.isCompleted
                                    ? 'Mark as Pending?'
                                    : 'Complete Task?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          task.isCompleted
                              ? 'Are you sure you want to mark this task as pending?'
                              : 'Are you sure you want to mark this task as completed?',
                          style: TextStyle(fontSize: 16),
                        ),
                        actionsPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: Responsive.isMobile(context) ? 100 : 120,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context)
                                          ? 16
                                          : 20,
                                      vertical: Responsive.isMobile(context)
                                          ? 10
                                          : 12,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        16,
                                        min: 14,
                                        max: 18,
                                      ),
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.isMobile(context) ? 12 : 16,
                              ),
                              SizedBox(
                                width: Responsive.isMobile(context) ? 100 : 120,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: task.isCompleted
                                        ? Colors.orange
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context)
                                          ? 16
                                          : 20,
                                      vertical: Responsive.isMobile(context)
                                          ? 10
                                          : 12,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    'Yes',
                                    style: TextStyle(
                                      fontSize: Responsive.responsiveFont(
                                        context,
                                        16,
                                        min: 14,
                                        max: 18,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    if (shouldToggle == true) {
                      setState(() {
                        final idx = tasks.indexOf(task);
                        if (idx != -1) {
                          tasks[idx] = task.copyWith(
                            isCompleted: !task.isCompleted,
                            status: !task.isCompleted
                                ? TaskStatus.completed
                                : TaskStatus.notStarted,
                          );
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Colors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: Responsive.responsiveFont(
                              context,
                              13,
                              min: 11,
                              max: 15,
                            ),
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Task> _getFilteredTasksForAllView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredTasks = tasks.where((task) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (task.description?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);

      // Status filter
      final matchesStatus =
          statusFilter == 'All' ||
          (statusFilter == 'Pending' && !task.isCompleted) ||
          (statusFilter == 'Completed' && task.isCompleted) ||
          (statusFilter == 'Overdue' &&
              task.dueDate != null &&
              _isTaskOverdue(task));

      // Category filter
      final matchesCategory =
          categoryFilter == null || task.category == categoryFilter;

      // Priority filter
      final matchesPriority =
          priorityFilter == null || priorityString(task) == priorityFilter;

      // Recurrence filter
      final matchesRecurrence =
          recurrenceFilter == null ||
          (recurrenceFilter == 'Recurring' &&
              task.recurrenceType != RecurrenceType.none) ||
          (recurrenceFilter == 'One-time' &&
              task.recurrenceType == RecurrenceType.none);

      // Date range filter
      final matchesDateRange =
          (dateFromFilter == null ||
              (task.dueDate != null &&
                  task.dueDate!.isAfter(dateFromFilter!))) &&
          (dateToFilter == null ||
              (task.dueDate != null &&
                  task.dueDate!.isBefore(
                    dateToFilter!.add(Duration(days: 1)),
                  )));

      // Overdue filter
      final matchesOverdue =
          !showOverdueOnly || (task.dueDate != null && _isTaskOverdue(task));

      // Due soon filter (due within 3 days)
      final matchesDueSoon =
          statusFilter != 'Due Soon' ||
          (statusFilter == 'Due Soon' && _isTaskDueSoon(task));

      // Time filter
      bool matchesTimeFilter = true;
      if (task.dueDate == null) {
        matchesTimeFilter = selectedTimeFilter == 0; // All Time
      } else {
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        switch (selectedTimeFilter) {
          case 0: // All Time
            matchesTimeFilter = true;
            break;
          case 1: // This Week
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(Duration(days: 6));
            matchesTimeFilter =
                dueDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
                dueDate.isBefore(weekEnd.add(Duration(days: 1)));
            break;
          case 2: // This Month
            matchesTimeFilter =
                dueDate.year == now.year && dueDate.month == now.month;
            break;
          case 3: // Next 3 Months
            final threeMonthsFromNow = DateTime(now.year, now.month + 3);
            matchesTimeFilter =
                dueDate.isAfter(today.subtract(Duration(days: 1))) &&
                dueDate.isBefore(threeMonthsFromNow);
            break;
          case 4: // Overdue
            matchesTimeFilter = dueDate.isBefore(today) && !task.isCompleted;
            break;
          default:
            matchesTimeFilter = true;
        }
      }

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesPriority &&
          matchesRecurrence &&
          matchesDateRange &&
          matchesOverdue &&
          matchesDueSoon &&
          matchesTimeFilter;
    }).toList();

    // Sort the filtered tasks
    filteredTasks.sort((a, b) {
      switch (sortOption) {
        case TaskSortOption.dueDate:
          // Get the effective scheduled time for each task
          DateTime getEffectiveTime(Task task) {
            if (task.dueDate == null) return DateTime(2100);

            // If task has a specific timeOfDay, combine it with the dueDate
            if (task.timeOfDay != null) {
              return DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              );
            }

            // Otherwise use the dueDate as is
            return task.dueDate!;
          }

          return getEffectiveTime(a).compareTo(getEffectiveTime(b));
        case TaskSortOption.priority:
          return priorityString(
            b,
          ).compareTo(priorityString(a)); // High > Medium > Low
        case TaskSortOption.category:
          return (a.category ?? '').compareTo(b.category ?? '');
      }
    });

    return filteredTasks;
  }

  List<Task> _getFilteredTasksForMonthView() {
    final selectedDate = _getSelectedDateForMonthView();
    if (selectedDate == null) {
      return []; // No date selected, show no tasks
    }

    final filteredTasks = tasks.where((task) {
      if (task.dueDate == null) return false;

      return task.dueDate!.year == selectedDate.year &&
          task.dueDate!.month == selectedDate.month &&
          task.dueDate!.day == selectedDate.day;
    }).toList();

    // Sort the filtered tasks
    filteredTasks.sort((a, b) {
      switch (sortOption) {
        case TaskSortOption.dueDate:
          // Get the effective scheduled time for each task
          DateTime getEffectiveTime(Task task) {
            if (task.dueDate == null) return DateTime(2100);

            // If task has a specific timeOfDay, combine it with the dueDate
            if (task.timeOfDay != null) {
              return DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
                task.timeOfDay!.hour,
                task.timeOfDay!.minute,
              );
            }

            // Otherwise use the dueDate as is
            return task.dueDate!;
          }

          return getEffectiveTime(a).compareTo(getEffectiveTime(b));
        case TaskSortOption.priority:
          return priorityString(
            b,
          ).compareTo(priorityString(a)); // High > Medium > Low
        case TaskSortOption.category:
          return (a.category ?? '').compareTo(b.category ?? '');
      }
    });

    return filteredTasks;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'business':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateDayMonthYear(DateTime date) {
    // Example: 12 May 2024
    final day = date.day;
    final month = _getMonthName(date.month).substring(0, 3); // Short month
    final year = date.year;
    return '$day $month $year';
  }

  String priorityString(Task task) {
    switch (task.priority) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.low:
        return 'Low Priority';
    }
  }

  String weekdayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildAllTabSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Color(0xFFF1F5F9),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : LoggitColors.darkGrayText,
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: Icon(Icons.tune, color: Colors.grey[700]),
              onPressed: _showFilterSheet,
              tooltip: 'Filter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTabContextBar(bool isDark, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                'All Tasks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Showing: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                TextSpan(
                  text: '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context, {
    required DateTime? initialDate,
    required ValueChanged<DateTime> onDateChanged,
  }) async {
    DateTime tempDate = initialDate ?? DateTime.now();
    DateTime displayedMonth = DateTime(tempDate.year, tempDate.month);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Local variables for drag tracking
            bool isDragging = false;
            double dragStartX = 0;
            double dragDistance = 0;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: 700, minWidth: 500),
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Month header with arrows
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setDialogState(() {
                                displayedMonth = DateTime(
                                  displayedMonth.year,
                                  displayedMonth.month - 1,
                                );
                              });
                            },
                          ),
                          Text(
                            '${_getMonthName(displayedMonth.month)} ${displayedMonth.year}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setDialogState(() {
                                displayedMonth = DateTime(
                                  displayedMonth.year,
                                  displayedMonth.month + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Weekday headers
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children:
                            ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                .map(
                                  (day) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Calendar grid with swipe gestures
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        // Track drag distance for swipe detection
                        if (!isDragging) {
                          isDragging = true;
                          dragStartX = details.globalPosition.dx;
                        }
                        dragDistance = details.globalPosition.dx - dragStartX;
                      },
                      onHorizontalDragEnd: (details) {
                        print(
                          'Swipe detected: distance = $dragDistance, velocity = ${details.primaryVelocity}',
                        );
                        isDragging = false;

                        // Use both distance and velocity for more reliable detection
                        final distanceThreshold = 50.0;
                        final velocityThreshold = 200.0;

                        if (dragDistance > distanceThreshold ||
                            details.primaryVelocity! > velocityThreshold) {
                          print('Swiping right - going to previous month');
                          // Swipe right - previous month
                          setDialogState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month - 1,
                            );
                          });
                        } else if (dragDistance < -distanceThreshold ||
                            details.primaryVelocity! < -velocityThreshold) {
                          print('Swiping left - going to next month');
                          // Swipe left - next month
                          setDialogState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month + 1,
                            );
                          });
                        }

                        // Reset drag tracking
                        dragDistance = 0;
                        dragStartX = 0;
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _buildCalendarGrid(
                          displayedMonth,
                          tempDate,
                          isDark,
                          (selectedDate) {
                            setDialogState(() {
                              tempDate = selectedDate;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Enhanced buttons
                    SizedBox(height: 12),
                    // Enhanced buttons
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: LoggitColors.teal.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    LoggitColors.teal,
                                    LoggitColors.teal.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: LoggitColors.teal.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  onDateChanged(tempDate);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'OK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarGrid(
    DateTime displayedMonth,
    DateTime selectedDate,
    bool isDark,
    ValueChanged<DateTime> onDateSelected,
  ) {
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final today = DateTime.now();

    return Column(
      children: List.generate(6, (weekIndex) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
            final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
            final isToday =
                dayNumber == today.day &&
                displayedMonth.month == today.month &&
                displayedMonth.year == today.year;
            final isSelected =
                dayNumber == selectedDate.day &&
                displayedMonth.month == selectedDate.month &&
                displayedMonth.year == selectedDate.year;

            return Expanded(
              child: GestureDetector(
                onTap: isValidDay
                    ? () {
                        onDateSelected(
                          DateTime(
                            displayedMonth.year,
                            displayedMonth.month,
                            dayNumber,
                          ),
                        );
                      }
                    : null,
                child: Container(
                  height: 36,
                  margin: EdgeInsets.symmetric(vertical: 0.5),
                  decoration: BoxDecoration(
                    color: isSelected ? LoggitColors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: LoggitColors.teal, width: 2)
                        : isSelected
                        ? Border.all(color: LoggitColors.teal, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isValidDay ? dayNumber.toString() : '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isValidDay
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildSimpleFilterChip(String label, String filterValue, bool isDark) {
    final isSelected = statusFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          statusFilter = filterValue;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LoggitColors.teal.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: LoggitColors.teal, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFilterPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _AnimatedFilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  State<_AnimatedFilterPill> createState() => _AnimatedFilterPillState();
}

class _AnimatedFilterPillState extends State<_AnimatedFilterPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.selected ? LoggitColors.teal : widget.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.selected
                      ? LoggitColors.teal
                      : LoggitColors.lightGray,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.selected ? Colors.white : widget.iconColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : LoggitColors.darkGrayText,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool isDark;
  final double fontSize;
  const _FilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: value ? FontWeight.bold : FontWeight.normal,
          color: isDark ? Colors.white : LoggitColors.darkGrayText,
          fontSize: fontSize,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: LoggitColors.teal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

String _monthString(int month) {
  const months = [
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
  return months[(month - 1) % 12];
}

String _getStatusText(TaskStatus status) {
  switch (status) {
    case TaskStatus.notStarted:
      return 'Not Started';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.completed:
      return 'Completed';
  }
}

String _getReminderText(ReminderType reminder) {
  switch (reminder) {
    case ReminderType.none:
      return 'No Reminder';
    case ReminderType.fifteenMinutes:
      return '15 minutes before';
    case ReminderType.oneHour:
      return '1 hour before';
    case ReminderType.oneDay:
      return '1 day before';
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class OverlayDeleteTaskCard extends StatefulWidget {
  final Widget child;
  final Task task;
  final bool isDark;
  final VoidCallback onDelete;
  final ValueNotifier<String?> openDeleteTaskTitle;
  final VoidCallback? onTap;
  const OverlayDeleteTaskCard({super.key, 
    required this.child,
    required this.task,
    required this.isDark,
    required this.onDelete,
    required this.openDeleteTaskTitle,
    this.onTap,
  });
  @override
  State<OverlayDeleteTaskCard> createState() => _OverlayDeleteTaskCardState();
}

class _OverlayDeleteTaskCardState extends State<OverlayDeleteTaskCard> {
  @override
  void initState() {
    super.initState();
    widget.openDeleteTaskTitle.addListener(_onOpenDeleteChanged);
  }

  @override
  void dispose() {
    widget.openDeleteTaskTitle.removeListener(_onOpenDeleteChanged);
    super.dispose();
  }

  void _onOpenDeleteChanged() {
    setState(() {});
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx < -2) {
      print('Drag detected for task: ${widget.task.title}');
      widget.openDeleteTaskTitle.value = widget.task.title;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {}

  @override
  Widget build(BuildContext context) {
    final showDelete = widget.openDeleteTaskTitle.value == widget.task.title;
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 8,
          bottom: 8,
          right: showDelete ? 0 : -56,
          width: 56,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: showDelete ? 1.0 : 0.0,
            child: Material(
              color: Colors.red.withOpacity(0.95),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                onTap: widget.onDelete,
                child: Center(
                  child: Icon(Icons.delete, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onTap: () {
            if (showDelete) {
              widget.openDeleteTaskTitle.value = null;
              return;
            }
            // Only open task modal if no delete button is open anywhere
            if (widget.openDeleteTaskTitle.value == null &&
                widget.onTap != null) {
              widget.onTap!();
            }
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.7,
              child: Container(height: 80, color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

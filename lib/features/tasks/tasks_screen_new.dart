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
  late int selectedDayIndex;
  late List<String> days;
  late List<int> dates;

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

    // Generate 7 days starting from today
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      days.add(weekDays[date.weekday % 7]);
      dates.add(date.day);
    }

    // Set selectedDayIndex to -1 to show all tasks by default
    selectedDayIndex = -1;

    // Generate dummy tasks for testing
    _generateDummyTasks();
  }

  void _generateDummyTasks() {
    final today = DateTime.now();

    tasks = [
      // Today's tasks
      Task(
        title: 'Morning Meeting',
        description: 'Team sync at 9am',
        dueDate: DateTime(today.year, today.month, today.day),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Work',
        priority: TaskPriority.high,
      ),
      Task(
        title: 'Buy groceries',
        description: 'Milk, eggs, bread',
        dueDate: DateTime(today.year, today.month, today.day),
        isCompleted: true,
        timestamp: DateTime.now(),
        category: 'Personal',
        priority: TaskPriority.medium,
      ),

      // Tomorrow's tasks
      Task(
        title: 'Gym workout',
        description: 'Cardio and weights',
        dueDate: DateTime(today.year, today.month, today.day + 1),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Personal',
        priority: TaskPriority.low,
      ),
      Task(
        title: 'Submit report',
        description: 'Monthly progress report',
        dueDate: DateTime(today.year, today.month, today.day + 1),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Work',
        priority: TaskPriority.medium,
      ),

      // Day after tomorrow
      Task(
        title: 'Team presentation',
        description: 'Q3 results presentation',
        dueDate: DateTime(today.year, today.month, today.day + 2),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Work',
        priority: TaskPriority.high,
      ),

      // Tasks for months ahead
      Task(
        title: 'Annual vacation',
        description: 'Book flights and hotels',
        dueDate: DateTime(today.year, today.month + 3, 15),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Personal',
        priority: TaskPriority.medium,
      ),
      Task(
        title: 'Tax filing deadline',
        description: 'Submit annual tax returns',
        dueDate: DateTime(today.year + 1, 4, 15),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Business',
        priority: TaskPriority.high,
      ),
      Task(
        title: 'Project milestone',
        description: 'Major project delivery',
        dueDate: DateTime(today.year, today.month + 2, 28),
        isCompleted: false,
        timestamp: DateTime.now(),
        category: 'Work',
        priority: TaskPriority.high,
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

    final today = DateTime.now();
    final targetDate = today.add(Duration(days: index));
    final now = DateTime.now();

    // Check if it's this week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    if (targetDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
        targetDate.isBefore(weekEnd.add(Duration(days: 1)))) {
      return days[index]; // Just show day name for this week
    }

    // For next week, show day name and date
    return '${days[index]} ${dates[index]}';
  }

  String _getSelectedDateContext() {
    if (selectedDayIndex == 0) {
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
      final matchesStatus =
          selectedFilter == 0 || // All
          (selectedFilter == 1 && !task.isCompleted) || // Pending
          (selectedFilter == 2 && task.isCompleted); // Completed

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
          return (a.dueDate ?? DateTime(2100)).compareTo(
            b.dueDate ?? DateTime(2100),
          );
        case TaskSortOption.priority:
          return priorityString(
            b,
          ).compareTo(priorityString(a)); // High > Medium > Low
        case TaskSortOption.category:
          return (a.category ?? '').compareTo(b.category ?? '');
      }
    });

    return Scaffold(
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
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                    ),
                    onPressed: widget.onBack,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
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
                      // Date selector bar with background
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
                          height: 76, // Increased height to accommodate border
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: days.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, i) {
                              final selected = i == selectedDayIndex;
                              return GestureDetector(
                                onTap: () {
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
                                    vertical: 8, // Increased vertical margin
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? LoggitColors.teal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: i == 0
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
                                        _getUserFriendlyDateLabel(i),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? Colors.white
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
                                              ? Colors.white
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
                      ),
                      SizedBox(height: LoggitSpacing.lg),
                      // Filter chips
                      Row(
                        children: List.generate(3, (i) {
                          final labels = ['All', 'Pending', 'Completed'];
                          // Show as selected only if it's the current filter AND no specific date is selected
                          final selected =
                              i == selectedFilter && selectedDayIndex < 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : Colors.black,
                                ),
                              ),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selectedFilter = i;
                                  // If "All" is selected, deselect any date to show all tasks
                                  if (i == 0) {
                                    selectedDayIndex = -1;
                                  }
                                  // If "Pending" or "Completed" is selected, keep current date selection
                                  // but the filter will still apply to the selected date's tasks
                                });
                              },
                              selectedColor: LoggitColors.teal,
                              backgroundColor: Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(
                                horizontal: 11.2,
                                vertical: 3.5,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: LoggitSpacing.lg),
                      // Search bar with filter icon inside
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? LoggitColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: LoggitColors.lighterGraySubtext,
                                  ),
                                  hintText: 'Search Tasks',
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: Icon(
                                  Icons.tune,
                                  color: LoggitColors.darkGrayText,
                                ),
                                iconSize: 24,
                                onPressed: _showFilterSheet,
                                tooltip: 'Filter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: LoggitSpacing.lg),
                      // Date context header
                      if (selectedDayIndex >= 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: LoggitColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: LoggitColors.teal.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: LoggitColors.teal,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _getSelectedDateContext(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: LoggitColors.teal,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: Colors.grey[600],
                                size: 20,
                              ),
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
                        ),
                      SizedBox(height: LoggitSpacing.md),
                      // Tasks section with count
                      Text(
                        'Tasks (${filteredTasks.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDark
                              ? Colors.white
                              : LoggitColors.darkGrayText,
                        ),
                      ),
                      SizedBox(height: LoggitSpacing.md),
                      if (filteredTasks.isNotEmpty)
                        ...filteredTasks.map(
                          (task) => _SwipeToDeleteTaskCard(
                            key: ValueKey(
                              task.title +
                                  (task.dueDate?.toIso8601String() ?? ''),
                            ),
                            task: task,
                            onDelete: () {
                              setState(() {
                                tasks.remove(task);
                              });
                            },
                            onTap: () => _showTaskModal(context, task: task),
                            onComplete: () {
                              setState(() {
                                final idx = tasks.indexOf(task);
                                if (idx != -1) {
                                  tasks[idx] = task.copyWith(
                                    isCompleted: true,
                                    status: TaskStatus.completed,
                                  );
                                }
                              });
                            },
                            isDark: isDark,
                            closeOptionsNotifier: closeSwipeOptionsNotifier,
                            openCardKeyNotifier: openSwipeCardKey,
                            cardKey: ValueKey(
                              task.title +
                                  (task.dueDate?.toIso8601String() ?? ''),
                            ),
                          ),
                        )
                      else
                        _buildEmptyState(isDark),
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
        onPressed: () => _showTaskModal(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                              // Date & Time single button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
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
                                    await _showDateTimePicker(
                                      context,
                                      initialDate: dueDate,
                                      initialTime: timeOfDay,
                                      onDateTimeChanged: (dt) {
                                        setModalState(() {
                                          dueDate = DateTime(
                                            dt.year,
                                            dt.month,
                                            dt.day,
                                          );
                                          timeOfDay = TimeOfDay(
                                            hour: dt.hour,
                                            minute: dt.minute,
                                          );
                                          showDateTimeError = false;
                                        });
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 18,
                                        color: LoggitColors.teal,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        (dueDate == null && timeOfDay == null)
                                            ? 'Pick Date & Time'
                                            : '${dueDate != null ? '${weekdayString(dueDate!.weekday)}, ${dueDate!.day} ${_monthString(dueDate!.month)} ${dueDate!.year}' : ''}  ${timeOfDay != null ? timeOfDay!.format(context) : ''}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : LoggitColors.darkGrayText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                          SizedBox(
                            width: 120,
                            height: 44,
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
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LoggitColors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                                    // Status Filters
                                    Text(
                                      'Status',
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
                                      label: 'All Tasks',
                                      value: localStatusFilter == 'All',
                                      onChanged: (val) {
                                        setModalState(
                                          () => localStatusFilter = 'All',
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
                                      label: 'Pending',
                                      value: localStatusFilter == 'Pending',
                                      onChanged: (val) {
                                        setModalState(
                                          () => localStatusFilter = 'Pending',
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
                                      label: 'Completed',
                                      value: localStatusFilter == 'Completed',
                                      onChanged: (val) {
                                        setModalState(
                                          () => localStatusFilter = 'Completed',
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
                                      label: 'Due Soon (3 days)',
                                      value: localStatusFilter == 'Due Soon',
                                      onChanged: (val) {
                                        setModalState(
                                          () => localStatusFilter = 'Due Soon',
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
                                      label: 'Overdue',
                                      value: localShowOverdueOnly,
                                      onChanged: (val) {
                                        setModalState(
                                          () => localShowOverdueOnly =
                                              val ?? false,
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
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Date & Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setPickerState) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final pickerHeight = (constraints.maxHeight - 120)
                              .clamp(120.0, 180.0);
                          return Row(
                            children: [
                              // Date picker wheel
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: pickerHeight,
                                  child: CupertinoPicker(
                                    scrollController:
                                        FixedExtentScrollController(
                                          initialItem: safeInitialDateIndex,
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
                                                tempTime.minute < now.minute)) {
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
                                                : Colors.black,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Time picker wheels
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      height: pickerHeight,
                                      child: CupertinoPicker(
                                        scrollController:
                                            FixedExtentScrollController(
                                              initialItem: _getInitialHourIndex(
                                                tempDate,
                                                tempTime,
                                              ),
                                            ),
                                        itemExtent: 40,
                                        onSelectedItemChanged: (index) {
                                          final availableHours =
                                              _getAvailableHours(tempDate);
                                          if (index < availableHours.length) {
                                            tempTime = TimeOfDay(
                                              hour: availableHours[index],
                                              minute: tempTime.minute,
                                            );
                                          }
                                        },
                                        children: _getAvailableHours(tempDate)
                                            .map(
                                              (hour) => Center(
                                                child: Text(
                                                  hour.toString().padLeft(
                                                    2,
                                                    '0',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 16,
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
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      height: pickerHeight,
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
                                          if (index < availableMinutes.length) {
                                            tempTime = TimeOfDay(
                                              hour: tempTime.hour,
                                              minute: availableMinutes[index],
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
                                                      minute.toString().padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 16,
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
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: LoggitColors.teal,
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      child: Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String title, subtitle, icon;

    if (tasks.isEmpty) {
      // No tasks at all
      title = 'No tasks yet';
      subtitle = 'Tap the + button to create your first task';
      icon = '📝';
    } else if (selectedDayIndex >= 0) {
      // No tasks for selected date
      title = 'No tasks for ${_getSelectedDateContext()}';
      subtitle = 'Tap the + button to add a task for this day';
      icon = '📅';
    } else if (searchQuery.isNotEmpty) {
      // No search results
      title = 'No matching tasks';
      subtitle = 'Try adjusting your search terms';
      icon = '🔍';
    } else if (selectedFilter == 1) {
      // No pending tasks
      title = 'No pending tasks';
      subtitle = 'All tasks are completed! 🎉';
      icon = '✅';
    } else if (selectedFilter == 2) {
      // No completed tasks
      title = 'No completed tasks';
      subtitle = 'Complete some tasks to see them here';
      icon = '📋';
    } else if (selectedDayIndex < 0) {
      // No tasks in "All Tasks" mode
      title = 'No tasks found';
      subtitle = 'Try selecting a specific date or add new tasks';
      icon = '📝';
    } else {
      // No tasks (fallback)
      title = 'No tasks found';
      subtitle = 'Try adjusting your filters or add new tasks';
      icon = '📝';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 40),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LoggitColors.darkGrayText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (tasks.isEmpty || selectedDayIndex >= 0) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showTaskModal(context),
              icon: Icon(Icons.add, size: 18),
              label: Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LoggitColors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
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

class _SwipeToDeleteTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isDark;
  final VoidCallback onComplete;
  final ValueNotifier<int> closeOptionsNotifier;
  final ValueNotifier<Key?> openCardKeyNotifier;
  final Key cardKey;
  const _SwipeToDeleteTaskCard({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onTap,
    required this.isDark,
    required this.onComplete,
    required this.closeOptionsNotifier,
    required this.openCardKeyNotifier,
    required this.cardKey,
  });
  @override
  State<_SwipeToDeleteTaskCard> createState() => _SwipeToDeleteTaskCardState();
}

class _SwipeToDeleteTaskCardState extends State<_SwipeToDeleteTaskCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  bool _showDelete = false;
  late AnimationController _controller;
  final GlobalKey _cardKey = GlobalKey();
  double? _cardHeight;

  @override
  void initState() {
    super.initState();
    widget.closeOptionsNotifier.addListener(_closeSwipeOptions);
    widget.openCardKeyNotifier.addListener(_checkOpenCardKey);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCardHeight());
  }

  void _closeSwipeOptions() {
    if (_showDelete) {
      setState(() {
        _showDelete = false;
      });
    }
  }

  void _checkOpenCardKey() {
    if (widget.openCardKeyNotifier.value != widget.cardKey && _showDelete) {
      setState(() {
        _showDelete = false;
      });
    }
  }

  void _measureCardHeight() {
    final context = _cardKey.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        setState(() {
          _cardHeight = box.size.height;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.closeOptionsNotifier.removeListener(_closeSwipeOptions);
    widget.openCardKeyNotifier.removeListener(_checkOpenCardKey);
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      if (_dragExtent < -60) {
        _showDelete = true;
        widget.openCardKeyNotifier.value = widget.cardKey;
        _controller.forward();
      } else if (_dragExtent > -20) {
        _showDelete = false;
        _controller.reverse();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -60) {
      setState(() {
        _showDelete = true;
        _controller.forward();
      });
    } else {
      setState(() {
        _showDelete = false;
        _controller.reverse();
      });
    }
    _dragExtent = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent overlay to dismiss options
        if (_showDelete)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showDelete = false;
                });
              },
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),
        // The actual card with swipe logic
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onTap: () {
            // Close swipe options first if THIS card has them open
            if (_showDelete) {
              setState(() {
                _showDelete = false;
              });
              return;
            }
            // Then handle the tap normally
            widget.onTap();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8), // Increased padding for shadow
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Task card (underneath)
                AnimatedContainer(
                  key: _cardKey,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: buildTaskCard(
                    context,
                    widget.task,
                    widget.isDark,
                    noMargin: true,
                  ),
                ),
                // Dual-action overlay (swipe left)
                AnimatedPositioned(
                  duration: Duration(milliseconds: 200),
                  right: _showDelete ? 0 : -60,
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: _showDelete ? 1 : 0,
                    child: SizedBox(
                      height: _cardHeight ?? 78,
                      width: 60,
                      child: Column(
                        children: [
                          // Complete button (top half)
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 60,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      widget.onComplete();
                                      setState(() {
                                        _showDelete = false;
                                      });
                                    },
                                    tooltip: 'Mark as Completed',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Delete button (bottom half)
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                width: 60,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Delete Task'),
                                          content: Text(
                                            'Are you sure you want to delete this task?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        widget.onDelete();
                                        setState(() {
                                          _showDelete = false;
                                        });
                                      }
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Top-level functions for task card building
Widget buildTaskCard(
  BuildContext context,
  Task task,
  bool isDark, {
  bool noMargin = false,
}) {
  Widget statusWidget;
  if (task.isCompleted) {
    statusWidget = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
      child: Center(child: Icon(Icons.check, color: Colors.white, size: 12)),
    );
  } else {
    statusWidget = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
      child: Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  String dateLabel = task.dueDate != null
      ? (task.dueDate!.day == DateTime.now().day &&
                task.dueDate!.month == DateTime.now().month &&
                task.dueDate!.year == DateTime.now().year
            ? 'Today'
            : '${weekdayString(task.dueDate!.weekday)}, ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}')
      : '';
  String timeLabel = task.timeOfDay != null
      ? '${task.timeOfDay!.hour.toString().padLeft(2, '0')}:${task.timeOfDay!.minute.toString().padLeft(2, '0')}'
      : '';
  String category = task.category ?? '';
  String priority = priorityString(task);
  IconData categoryIcon = category == 'Work'
      ? Icons.work
      : category == 'Personal'
      ? Icons.person
      : Icons.business;
  Color categoryIconColor = category == 'Work'
      ? Colors.brown[300]!
      : category == 'Personal'
      ? Colors.green
      : Colors.blue;
  Color priorityIconColor = priority.contains('High')
      ? Colors.red
      : priority.contains('Medium')
      ? Colors.orange
      : Colors.green;
  return Container(
    margin: noMargin
        ? null
        : const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? LoggitColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : LoggitColors.darkGrayText,
                ),
              ),
            ),
          ],
        ),
        if (dateLabel.isNotEmpty || timeLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              [dateLabel, timeLabel].where((s) => s.isNotEmpty).join(' '),
              style: TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
          ),
        SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(categoryIcon, size: 16, color: categoryIconColor),
            SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
            SizedBox(width: 12),
            Icon(Icons.flag, size: 16, color: priorityIconColor),
            SizedBox(width: 4),
            Text(
              priority,
              style: TextStyle(color: LoggitColors.lighterGraySubtext),
            ),
            Spacer(),
            SizedBox(
              height: 20,
              child: Align(alignment: Alignment.center, child: statusWidget),
            ),
          ],
        ),
      ],
    ),
  );
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

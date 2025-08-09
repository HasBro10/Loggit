import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/utils/responsive.dart';
import '../../services/reminders_service.dart';
import 'reminder_model.dart';
import 'reminder_edit_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemindersScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RemindersScreen({super.key, required this.onBack});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // Dynamic date bar state
  int selectedDayIndex = 0; // 0 = Today
  late List<String> days;
  late List<int> dates;

  int selectedFilter = 0; // 0 means "All" filter selected by default

  List<Reminder> reminders = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // View system state
  bool _isGridView = false;
  bool _isCompactView = false;

  final ValueNotifier<String?> openDeleteReminderTitle = ValueNotifier<String?>(
    null,
  );

  @override
  void initState() {
    super.initState();
    _generateDynamicDates();
    // Default to current date (today) when page loads
    selectedFilter = 0; // "All" filter
    selectedDayIndex = 0; // Today (current date) selected by default
    // Close any open delete overlay when page loads
    openDeleteReminderTitle.value = null;
    // Load saved view preference
    _loadViewPreference();
    // Add dummy reminders for demo if list is empty
    if (reminders.isEmpty) {
      reminders = [
        Reminder(
          title: 'Doctor Appointment',
          description: 'Visit Dr. Smith at 10am',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            14,
            10,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            14,
            10,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Buy Groceries',
          description: 'Milk, Eggs, Bread',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            16,
            17,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            16,
            17,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Team Meeting',
          description: 'Project sync at 2pm',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            17,
            14,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            17,
            14,
            0,
          ),
          isCompleted: true,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Workout',
          description: 'Gym session',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            18,
            7,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            18,
            7,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Call Mom',
          description: 'Evening call',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            19,
            20,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            19,
            20,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        // New dummy reminders
        Reminder(
          title: 'Dentist Checkup',
          description: 'Routine cleaning at 9am',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            20,
            9,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            20,
            9,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Library Return',
          description: 'Return books by 5pm',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            21,
            17,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            21,
            17,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Anniversary Dinner',
          description: 'Dinner reservation at 8pm',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            22,
            20,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            22,
            20,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
      ];
    }
    _loadReminders();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    });
  }

  void _generateDynamicDates() {
    final today = DateTime.now();
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    days = [];
    dates = [];
    // Extend to 60 days to include more future dates
    for (int i = 0; i < 60; i++) {
      final date = today.add(Duration(days: i));
      days.add(weekDays[date.weekday % 7]);
      dates.add(date.day);
    }
    selectedDayIndex = 0;
  }

  String _getUserFriendlyDateLabel(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();
    final targetDate = today.add(Duration(days: index));
    return weekDays[targetDate.weekday % 7];
  }

  Future<void> _loadReminders() async {
    setState(() => isLoading = true);
    reminders = await RemindersService.loadReminders();
    // Sort reminders by time (soonest first)
    reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    if (reminders.isEmpty) {
      reminders = [
        Reminder(
          title: 'Doctor Appointment',
          description: 'Visit Dr. Smith at 10am',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            14,
            10,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            14,
            10,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Buy Groceries',
          description: 'Milk, Eggs, Bread',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            16,
            17,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            16,
            17,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Team Meeting',
          description: 'Project sync at 2pm',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            17,
            14,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            17,
            14,
            0,
          ),
          isCompleted: true,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Workout',
          description: 'Gym session',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            18,
            7,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            18,
            7,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
        Reminder(
          title: 'Call Mom',
          description: 'Evening call',
          reminderTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            19,
            20,
            0,
          ),
          timestamp: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            19,
            20,
            0,
          ),
          isCompleted: false,
          recurrenceType: RecurrenceType.none,
        ),
      ];
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Close any open delete overlay when disposing
    openDeleteReminderTitle.value = null;
    super.dispose();
  }

  // Method to close any open delete overlay
  void _closeDeleteOverlay() {
    openDeleteReminderTitle.value = null;
  }

  // Method to load saved view preference
  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isGridView = prefs.getBool('isGridView') ?? false;
    final isCompactView = prefs.getBool('isCompactView') ?? false;

    setState(() {
      _isGridView = isGridView;
      _isCompactView = isCompactView;
    });
  }

  // Method to save view preference
  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', _isGridView);
    await prefs.setBool('isCompactView', _isCompactView);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = false; // TODO: Use theme mode
    // Responsive values for date selector
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 320;
    final double dayFontSize = isNarrow ? 12 : 14;
    final double dateFontSize = isNarrow ? 16 : 19;
    final double pillHPadding = isNarrow ? 12 : 18;
    final double pillVPadding = isNarrow ? 6 : 8;
    final double pillVMargin = isNarrow ? 6 : 10;
    // Only compute selectedDate if selectedDayIndex >= 0
    DateTime? selectedDate = selectedDayIndex >= 0
        ? DateTime.now().add(Duration(days: selectedDayIndex))
        : null;
    // Filter reminders based on selected filter and date
    List<Reminder> filteredReminders = [];

    // First, check if a specific date is selected in the calendar
    if (selectedDayIndex >= 0 && selectedDate != null) {
      // Debug: Print the selected date and reminders
      print('DEBUG: Selected date: $selectedDate');
      print('DEBUG: Total reminders: ${reminders.length}');
      for (var r in reminders) {
        print(
          'DEBUG: Reminder "${r.title}" - Date: ${r.reminderTime}, Recurring: ${r.recurrenceType}',
        );
      }

      // If a specific date is selected, show reminders for that date regardless of filter
      filteredReminders = reminders.where((r) {
        // If not recurring, match date
        if (r.recurrenceType == RecurrenceType.none) {
          final matches =
              r.reminderTime.year == selectedDate.year &&
              r.reminderTime.month == selectedDate.month &&
              r.reminderTime.day == selectedDate.day;
          print(
            'DEBUG: Non-recurring reminder "${r.title}" - Matches: $matches',
          );
          return matches;
        }
        // If recurring, check if selectedDate is in recurrence
        print(
          'DEBUG: Checking recurring reminder "${r.title}" for date $selectedDate',
        );
        if (r.endDate != null && selectedDate.isAfter(r.endDate!)) {
          print('DEBUG: After end date - skipping');
          return false;
        }
        // Compare only the date part, not the time
        final selectedDateOnly = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        final reminderDateOnly = DateTime(
          r.reminderTime.year,
          r.reminderTime.month,
          r.reminderTime.day,
        );

        if (selectedDateOnly.isBefore(reminderDateOnly)) {
          print('DEBUG: Before start date - skipping');
          return false;
        }
        switch (r.recurrenceType) {
          case RecurrenceType.daily:
            return !_isAfterEnd(r, selectedDate) &&
                !selectedDateOnly.isBefore(reminderDateOnly);
          case RecurrenceType.weekly:
            final matches =
                !_isAfterEnd(r, selectedDate) &&
                selectedDate.weekday == r.reminderTime.weekday &&
                !selectedDateOnly.isBefore(reminderDateOnly);
            print(
              'DEBUG: Weekly reminder "${r.title}" - Weekday match: ${selectedDate.weekday} == ${r.reminderTime.weekday}, Matches: $matches',
            );
            return matches;
          case RecurrenceType.monthly:
            return !_isAfterEnd(r, selectedDate) &&
                selectedDate.day == r.reminderTime.day &&
                !selectedDateOnly.isBefore(reminderDateOnly);
          case RecurrenceType.custom:
            return !_isAfterEnd(r, selectedDate) &&
                r.customDays?.contains(selectedDate.weekday) == true &&
                !selectedDateOnly.isBefore(reminderDateOnly);
          case RecurrenceType.everyNDays:
            if (r.interval == null || r.interval! < 1) return false;
            final diff = selectedDate.difference(r.reminderTime).inDays;
            return diff % r.interval! == 0 &&
                diff >= 0 &&
                !_isAfterEnd(r, selectedDate);
          case RecurrenceType.everyNWeeks:
            if (r.interval == null || r.interval! < 1) return false;
            final diff = selectedDate.difference(r.reminderTime).inDays;
            return (diff ~/ 7) % r.interval! == 0 &&
                diff >= 0 &&
                !_isAfterEnd(r, selectedDate);
          case RecurrenceType.everyNMonths:
            if (r.interval == null || r.interval! < 1) return false;
            final monthsDiff =
                (selectedDate.year - r.reminderTime.year) * 12 +
                (selectedDate.month - r.reminderTime.month);
            return monthsDiff % r.interval! == 0 &&
                selectedDate.day == r.reminderTime.day &&
                monthsDiff >= 0 &&
                !_isAfterEnd(r, selectedDate);
          case RecurrenceType.none:
            return false;
        }
      }).toList();
      print('DEBUG: Filtered reminders count: ${filteredReminders.length}');
    } else {
      // No specific date selected, use filter logic
      switch (selectedFilter) {
        case 0: // All
          // Show all reminders but only next occurrence of recurring ones
          filteredReminders = [];
          for (Reminder reminder in reminders) {
            if (reminder.recurrenceType == RecurrenceType.none) {
              // Non-recurring reminder - add as is
              filteredReminders.add(reminder);
            } else {
              // Recurring reminder - get next occurrence
              final nextOccurrence = _getNextOccurrence(reminder);
              if (nextOccurrence != null) {
                filteredReminders.add(nextOccurrence);
              }
            }
          }
          break;
        case 1: // Upcoming
          filteredReminders = reminders.where((r) => !r.isCompleted).toList();
          break;
        case 2: // Completed
          filteredReminders = reminders.where((r) => r.isCompleted).toList();
          break;
        default:
          filteredReminders = reminders;
      }
    }
    // Further filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filteredReminders = filteredReminders.where((r) {
        return r.title.toLowerCase().contains(q) ||
            (r.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? LoggitColors.darkBg : LoggitColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header
            Container(
              padding: EdgeInsets.all(
                Responsive.responsiveFont(
                  context,
                  LoggitSpacing.screenPadding.toDouble(),
                  min: 8,
                  max: 32,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                      size: Responsive.responsiveIcon(
                        context,
                        28,
                        min: 20,
                        max: 44,
                      ),
                    ),
                    onPressed: widget.onBack,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Reminders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.responsiveFont(
                        context,
                        28,
                        min: 18,
                        max: 36,
                      ),
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list
                          : _isCompactView
                          ? Icons.grid_view
                          : Icons.view_compact,
                      color: isDark ? Colors.white : LoggitColors.darkGrayText,
                      size: Responsive.responsiveIcon(
                        context,
                        24,
                        min: 20,
                        max: 32,
                      ),
                    ),
                    tooltip: _isGridView
                        ? 'List View'
                        : _isCompactView
                        ? 'Grid View'
                        : 'Compact View',
                    onPressed: () {
                      // Close any open delete overlay when tapping on view toggle button
                      if (openDeleteReminderTitle.value != null) {
                        openDeleteReminderTitle.value = null;
                      }
                      setState(() {
                        if (_isGridView) {
                          // From Grid view → Compact view
                          _isGridView = false;
                          _isCompactView = true;
                        } else if (_isCompactView) {
                          // From Compact view → List view
                          _isGridView = false;
                          _isCompactView = false;
                        } else {
                          // From List view → Grid view
                          _isGridView = true;
                          _isCompactView = false;
                        }
                        _saveViewPreference();
                      });
                    },
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Close any open delete overlay when tapping anywhere on the screen
                  if (openDeleteReminderTitle.value != null) {
                    openDeleteReminderTitle.value = null;
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(
                      Responsive.responsiveFont(
                        context,
                        LoggitSpacing.screenPadding.toDouble(),
                        min: 8,
                        max: 32,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date selector bar with background
                        Container(
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
                          child: GestureDetector(
                            onTap: () {
                              // Close any open delete overlay when tapping on date selector
                              if (openDeleteReminderTitle.value != null) {
                                openDeleteReminderTitle.value = null;
                              }
                            },
                            child: SizedBox(
                              height: 76,
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
                                      // Close any open delete overlay when tapping on date items
                                      if (openDeleteReminderTitle.value !=
                                          null) {
                                        openDeleteReminderTitle.value = null;
                                      }
                                      setState(() {
                                        selectedDayIndex = i;
                                        // Keep filter as "All" when selecting a date
                                        // selectedFilter = -1; // Removed this line
                                        // Close any open delete overlay when selecting a date
                                        _closeDeleteOverlay();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 180),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 2,
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
                                          SizedBox(height: 0),
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
                                          SizedBox(height: 1),
                                          Container(
                                            height: 6,
                                            width: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  _hasRemindersForDate(
                                                    DateTime.now()
                                                        .add(Duration(days: i))
                                                        .year,
                                                    DateTime.now()
                                                        .add(Duration(days: i))
                                                        .month,
                                                    DateTime.now()
                                                        .add(Duration(days: i))
                                                        .day,
                                                  )
                                                  ? LoggitColors.teal
                                                  : Colors.transparent,
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
                        ),
                        SizedBox(height: LoggitSpacing.lg),
                        // Filter chips
                        Row(
                          children: List.generate(3, (i) {
                            final labels = ['All', 'Upcoming', 'Completed'];
                            // "All" is selected only when no specific date is selected (selectedDayIndex == -1)
                            // When current date is default (selectedDayIndex == 0), "All" should not be highlighted
                            final selected = i == 0
                                ? selectedDayIndex == -1
                                : i == selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 10.5, // 30% smaller than 15
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) {
                                  // Close any open delete overlay when tapping on filter buttons
                                  if (openDeleteReminderTitle.value != null) {
                                    openDeleteReminderTitle.value = null;
                                  }
                                  setState(() {
                                    // Clear date selection when any filter is selected
                                    selectedDayIndex = -1;
                                    selectedFilter = i;
                                    // Close any open delete overlay when changing filters
                                    _closeDeleteOverlay();
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
                                ), // 30% smaller than 16,5
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: LoggitSpacing.lg),
                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Close any open delete overlay when tapping on search bar
                                  if (openDeleteReminderTitle.value != null) {
                                    openDeleteReminderTitle.value = null;
                                  }
                                },
                                child: TextField(
                                  controller: _searchController,
                                  onTap: () {
                                    // Close any open delete overlay when tapping on search bar
                                    if (openDeleteReminderTitle.value != null) {
                                      openDeleteReminderTitle.value = null;
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search Reminders',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey[500],
                                    ),
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
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                // Close any open delete overlay when tapping on filter button
                                if (openDeleteReminderTitle.value != null) {
                                  openDeleteReminderTitle.value = null;
                                }
                                // TODO: Open filter modal
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.tune,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    // Close any open delete overlay when tapping on filter button
                                    if (openDeleteReminderTitle.value != null) {
                                      openDeleteReminderTitle.value = null;
                                    }
                                    // TODO: Open filter modal
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: LoggitSpacing.lg),
                        // Section title with count and date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminders (${filteredReminders.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.responsiveFont(
                                  context,
                                  18,
                                  min: 12,
                                  max: 28,
                                ),
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: LoggitSpacing.md),
                        // Reminders list
                        if (_isGridView)
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            crossAxisSpacing: LoggitSpacing.sm,
                            mainAxisSpacing: LoggitSpacing.sm,
                            childAspectRatio:
                                0.85, // Increased from 0.75 to make cards shorter vertically
                            children: filteredReminders
                                .map((r) => _buildGridReminderCard(r, isDark))
                                .toList(),
                          )
                        else if (_isCompactView)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: filteredReminders.length,
                            itemBuilder: (context, index) {
                              final r = filteredReminders[index];
                              return _buildCompactReminderCard(r, isDark);
                            },
                          )
                        else
                          ...filteredReminders.map(
                            (r) => _buildReminderCard(r, isDark),
                          ),
                        // Show empty state when no reminders
                        if (filteredReminders.isEmpty) _buildEmptyState(isDark),
                        // Bottom padding for FAB
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LoggitColors.teal,
        elevation: 6,
        onPressed: () async {
          // Close any open delete overlay when tapping the plus button
          if (openDeleteReminderTitle.value != null) {
            openDeleteReminderTitle.value = null;
            // Wait a moment for the delete overlay animation to complete
            await Future.delayed(Duration(milliseconds: 300));
          }
          final result = await showReminderEditModal(context);
          if (result is Reminder) {
            await RemindersService.addReminder(result);
            await _loadReminders();
          }
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: Responsive.responsiveIcon(context, 32, min: 20, max: 44),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${_weekdayString(dt.weekday)}, ${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildCategoryChip(Reminder r) {
    // Example: Health, Personal, Work
    final category = r.category ?? 'Other';
    IconData icon;
    Color color;
    switch (category.toLowerCase()) {
      case 'health':
        icon = Icons.medical_services;
        color = LoggitColors.teal;
        break;
      case 'personal':
        icon = Icons.person;
        color = Colors.orange;
        break;
      case 'work':
        icon = Icons.work;
        color = Colors.blue;
        break;
      default:
        icon = Icons.label;
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(Reminder r) {
    // Example: High, Medium, Low
    final text = _priorityText(r);
    Color color;
    switch (text) {
      case 'High Priority':
        color = Colors.red;
        break;
      case 'Medium Priority':
        color = Colors.orange;
        break;
      case 'Low Priority':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: color, size: 15),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _priorityText(Reminder r) {
    // TODO: Replace with real priority field if added to Reminder model
    // For now, use description or default
    final desc = r.description?.toLowerCase() ?? '';
    if (desc.contains('high')) return 'High Priority';
    if (desc.contains('medium')) return 'Medium Priority';
    if (desc.contains('low')) return 'Low Priority';
    return 'Medium Priority';
  }

  // Helper: check if selectedDate is after endDate
  bool _isAfterEnd(Reminder r, DateTime? d) {
    if (d == null) return false;

    // Check explicit end date first
    if (r.endDate != null && d.isAfter(r.endDate!)) {
      return true;
    }

    // Check duration-based end date
    if (r.repeatDuration != null && r.repeatDurationType != null) {
      DateTime endDate;
      switch (r.repeatDurationType!) {
        case 'days':
          endDate = r.reminderTime.add(Duration(days: r.repeatDuration!));
          break;
        case 'weeks':
          endDate = r.reminderTime.add(Duration(days: r.repeatDuration! * 7));
          break;
        case 'months':
          endDate = DateTime(
            r.reminderTime.year,
            r.reminderTime.month + r.repeatDuration!,
            r.reminderTime.day,
          );
          break;
        default:
          return false;
      }
      return d.isAfter(endDate);
    }

    return false;
  }

  String _recurrenceText(Reminder r) {
    switch (r.recurrenceType) {
      case RecurrenceType.daily:
        return 'Repeats daily${_untilText(r)}';
      case RecurrenceType.weekly:
        return 'Repeats weekly${_untilText(r)}';
      case RecurrenceType.monthly:
        return 'Repeats monthly${_untilText(r)}';
      case RecurrenceType.custom:
        if (r.customDays == null || r.customDays!.isEmpty) {
          return 'Custom recurrence${_untilText(r)}';
        }
        const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final days = r.customDays!.map((d) => weekDays[(d - 1) % 7]).join(', ');
        return 'Custom: $days${_untilText(r)}';
      case RecurrenceType.everyNDays:
        return 'Every ${r.interval ?? 1} day(s)${_untilText(r)}';
      case RecurrenceType.everyNWeeks:
        return 'Every ${r.interval ?? 1} week(s)${_untilText(r)}';
      case RecurrenceType.everyNMonths:
        return 'Every ${r.interval ?? 1} month(s)${_untilText(r)}';
      case RecurrenceType.none:
        return '';
    }
  }

  String _untilText(Reminder r) {
    if (r.endDate != null) {
      return ' until ${r.endDate!.day}/${r.endDate!.month}/${r.endDate!.year}';
    }
    return '';
  }

  // Helper methods for bell icon functionality
  Color _getBellBackgroundColor(Reminder r) {
    if (r.isCompleted) {
      return Colors.green.withOpacity(0.13); // Done - green
    } else {
      return LoggitColors.teal.withOpacity(0.13); // Active - teal
    }
  }

  IconData _getBellIcon(Reminder r) {
    if (r.isCompleted) {
      return Icons.notifications_off; // Silent bell for completed
    } else {
      return Icons.notifications_active_rounded; // Active bell
    }
  }

  Color _getBellIconColor(Reminder r) {
    if (r.isCompleted) {
      return Colors.green; // Done - green
    } else {
      return LoggitColors.teal; // Active - teal
    }
  }

  String _getBellStatusText(Reminder r) {
    if (r.isCompleted) {
      return 'Done';
    } else {
      return 'Active';
    }
  }

  Color _getBellStatusColor(Reminder r) {
    if (r.isCompleted) {
      return Colors.green; // Done - green
    } else {
      return LoggitColors.teal; // Active - teal
    }
  }

  Widget _buildEmptyState(bool isDark) {
    String emptyTitle;
    String emptySubtitle;
    String emptyIcon;

    // Determine the appropriate message based on the current state
    if (selectedFilter == 0) {
      // "All" filter - no reminders at all
      if (selectedDayIndex == 0) {
        // Today
        emptyTitle = 'No reminders for today';
        emptySubtitle = 'Tap the + button to add a reminder for today';
        emptyIcon = '📋';
      } else if (selectedDayIndex == 1) {
        // Tomorrow
        emptyTitle = 'No reminders for tomorrow';
        emptySubtitle = 'Tap the + button to add a reminder for tomorrow';
        emptyIcon = '📋';
      } else {
        // Other selected date
        final selectedDate = DateTime.now().add(
          Duration(days: selectedDayIndex),
        );
        final dateLabel =
            '${_getDayName(selectedDate.weekday)} ${selectedDate.day}';
        emptyTitle = 'No reminders for $dateLabel';
        emptySubtitle = 'Tap the + button to add a reminder for this day';
        emptyIcon = '📋';
      }
    } else if (selectedFilter == 1) {
      // "Upcoming" filter
      emptyTitle = 'No upcoming reminders';
      emptySubtitle = 'All your reminders are completed!';
      emptyIcon = '✅';
    } else if (selectedFilter == 2) {
      // "Completed" filter
      emptyTitle = 'No completed reminders';
      emptySubtitle = 'Complete some reminders to see them here';
      emptyIcon = '📝';
    } else {
      // Fallback
      emptyTitle = 'No reminders found';
      emptySubtitle = 'Tap the + button to create your first reminder';
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

  String _getDayName(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday % 7];
  }

  // Get the next occurrence of a recurring reminder
  Reminder? _getNextOccurrence(Reminder reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate the end date based on duration limits
    final startDate = reminder.reminderTime;
    DateTime endDate;

    if (reminder.repeatDuration != null &&
        reminder.repeatDurationType != null) {
      // Use the duration limit
      switch (reminder.repeatDurationType!) {
        case 'days':
          endDate = startDate.add(Duration(days: reminder.repeatDuration! - 1));
          break;
        case 'weeks':
          endDate = startDate.add(
            Duration(days: (reminder.repeatDuration! * 7) - 1),
          );
          break;
        case 'months':
          endDate = DateTime(
            startDate.year,
            startDate.month + reminder.repeatDuration! - 1,
            startDate.day,
          );
          break;
        default:
          endDate = startDate.add(
            Duration(days: 365),
          ); // Default to 1 year if unknown
      }
    } else {
      // No duration limit - truly infinite recurring reminder
      // Set end date to a very far future date (10 years from now)
      endDate = DateTime(startDate.year + 10, startDate.month, startDate.day);
    }

    // Find the next occurrence
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (_isReminderForDate(reminder, currentDate)) {
        // Check if this occurrence is in the future or today
        final occurrenceDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (!occurrenceDate.isBefore(today)) {
          // This is the next occurrence
          return reminder.copyWith(
            reminderTime: DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              reminder.reminderTime.hour,
              reminder.reminderTime.minute,
            ),
          );
        }
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    return null; // No future occurrences found
  }

  // Check if a reminder occurs on a specific date
  bool _isReminderForDate(Reminder reminder, DateTime date) {
    if (reminder.recurrenceType == RecurrenceType.none) {
      return reminder.reminderTime.year == date.year &&
          reminder.reminderTime.month == date.month &&
          reminder.reminderTime.day == date.day;
    }

    // Check if date is after the end date
    if (_isAfterEnd(reminder, date)) {
      return false;
    }

    // Compare only the date part, not the time
    final dateOnly = DateTime(date.year, date.month, date.day);
    final reminderDateOnly = DateTime(
      reminder.reminderTime.year,
      reminder.reminderTime.month,
      reminder.reminderTime.day,
    );

    switch (reminder.recurrenceType) {
      case RecurrenceType.daily:
        return !dateOnly.isBefore(reminderDateOnly);
      case RecurrenceType.weekly:
        return date.weekday == reminder.reminderTime.weekday &&
            !dateOnly.isBefore(reminderDateOnly);
      case RecurrenceType.monthly:
        return date.day == reminder.reminderTime.day &&
            !dateOnly.isBefore(reminderDateOnly);
      case RecurrenceType.custom:
        return reminder.customDays?.contains(date.weekday) == true &&
            !dateOnly.isBefore(reminderDateOnly);
      case RecurrenceType.everyNDays:
        if (reminder.interval == null || reminder.interval! < 1) return false;
        final diff = date.difference(reminder.reminderTime).inDays;
        return diff % reminder.interval! == 0 && diff >= 0;
      case RecurrenceType.everyNWeeks:
        if (reminder.interval == null || reminder.interval! < 1) return false;
        final diff = date.difference(reminder.reminderTime).inDays;
        return (diff ~/ 7) % reminder.interval! == 0 && diff >= 0;
      case RecurrenceType.everyNMonths:
        if (reminder.interval == null || reminder.interval! < 1) return false;
        final monthsDiff =
            (date.year - reminder.reminderTime.year) * 12 +
            (date.month - reminder.reminderTime.month);
        return monthsDiff % reminder.interval! == 0 &&
            date.day == reminder.reminderTime.day &&
            monthsDiff >= 0;
      case RecurrenceType.none:
        return false;
    }
  }

  String _getRecurrenceText(Reminder reminder) {
    if (reminder.repeatDuration != null &&
        reminder.repeatDurationType != null) {
      final duration = reminder.repeatDuration!;
      final durationType = reminder.repeatDurationType!;

      if (duration == 1) {
        return '1 ${durationType.substring(0, durationType.length - 1)}'; // Remove 's' for singular
      } else {
        return '$duration $durationType';
      }
    } else {
      return 'Until further notice';
    }
  }

  // Check if there are reminders for a specific date
  bool _hasRemindersForDate(int year, int month, int day) {
    final targetDate = DateTime(year, month, day);
    print('DEBUG: Checking for reminders on $year-$month-$day');

    for (Reminder reminder in reminders) {
      if (reminder.recurrenceType == RecurrenceType.none) {
        // Non-recurring reminder - check exact date match
        if (reminder.reminderTime.year == year &&
            reminder.reminderTime.month == month &&
            reminder.reminderTime.day == day) {
          print(
            'DEBUG: Found non-recurring reminder "${reminder.title}" for $year-$month-$day',
          );
          return true;
        }
      } else {
        // Recurring reminder - check if this date is in the recurrence
        if (_isReminderForDate(reminder, targetDate)) {
          print(
            'DEBUG: Found recurring reminder "${reminder.title}" for $year-$month-$day',
          );
          return true;
        }
      }
    }
    print('DEBUG: No reminders found for $year-$month-$day');
    return false;
  }

  // Get list of future recurring dates for reminders
  List<DateTime> _getFutureRecurringDates(
    Reminder reminder, {
    int maxDates = 15,
  }) {
    if (reminder.recurrenceType == RecurrenceType.none) {
      return [];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<DateTime> futureDates = [];

    // Check the next 365 days for occurrences
    for (int i = 0; i < 365 && futureDates.length < maxDates; i++) {
      final checkDate = today.add(Duration(days: i));
      if (_isReminderForDate(reminder, checkDate)) {
        futureDates.add(checkDate);
      }
    }

    return futureDates;
  }

  // Show modal with recurring dates for reminders
  void _showRecurringDatesModal(
    BuildContext context,
    Reminder reminder,
    bool isDark,
  ) {
    final futureDates = _getFutureRecurringDates(reminder);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recurring Reminder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                reminder.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: futureDates
                          .map(
                            (date) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: LoggitColors.teal,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatDateTime(date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoggitColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for different view types
  Widget _buildReminderCard(Reminder r, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Close any open delete overlay when tapping anywhere on the card
        if (openDeleteReminderTitle.value != null) {
          openDeleteReminderTitle.value = null;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(8), // Space for shadow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: OverlayDeleteReminderCard(
          reminder: r,
          openDeleteReminderTitle: openDeleteReminderTitle,
          onDelete: (ctx) async {
            final confirm = await showDialog<bool>(
              context: ctx,
              builder: (ctx2) => AlertDialog(
                title: Text('Delete Reminder'),
                content: Text('Are you sure you want to delete this reminder?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await RemindersService.deleteReminder(r);
              await _loadReminders();
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 120),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: r.isCompleted
                    ? LoggitColors.teal.withOpacity(0.55)
                    : Colors.orange.withOpacity(0.55),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Main card content (tappable for edit, excludes checkbox area)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0,
                    right: 36,
                  ), // leave space for checkbox
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (details.delta.dx < -2) {
                        openDeleteReminderTitle.value =
                            r.title + r.reminderTime.toString();
                      }
                    },
                    onHorizontalDragEnd: (details) {},
                    onTap: () {
                      // Close any open delete overlay when tapping the card
                      if (openDeleteReminderTitle.value != null) {
                        openDeleteReminderTitle.value = null;
                        return;
                      }
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        // Close any open delete overlay when tapping the card
                        if (openDeleteReminderTitle.value != null) {
                          openDeleteReminderTitle.value = null;
                          return;
                        }
                        final result = await showReminderEditModal(
                          context,
                          initial: r,
                        );
                        if (result is Reminder) {
                          await RemindersService.updateReminder(result);
                          await _loadReminders();
                        }
                        if (result == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Delete Reminder'),
                              content: Text(
                                'Are you sure you want to delete this reminder?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await RemindersService.deleteReminder(r);
                            await _loadReminders();
                          }
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.responsiveFont(
                                      context,
                                      17,
                                      min: 12,
                                      max: 24,
                                    ),
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 15,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDateTime(r.reminderTime),
                                      style: TextStyle(
                                        fontSize: Responsive.responsiveFont(
                                          context,
                                          13,
                                          min: 10,
                                          max: 18,
                                        ),
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                // Status pill and repeat icon row
                                Row(
                                  children: [
                                    // Status pill aligned to the left
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: r.isCompleted
                                            ? Colors.green.withOpacity(0.13)
                                            : Colors.orange.withOpacity(0.13),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            r.isCompleted
                                                ? Icons.check_circle
                                                : Icons.hourglass_empty,
                                            color: r.isCompleted
                                                ? Colors.green
                                                : Colors.orange,
                                            size: 15,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            r.isCompleted
                                                ? 'Completed'
                                                : 'Upcoming',
                                            style: TextStyle(
                                              color: r.isCompleted
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
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
                        ],
                      ),
                    ),
                  ),
                ),

                // Repeat icon in bottom right for recurring reminders
                if (r.recurrenceType != RecurrenceType.none)
                  Positioned(
                    bottom: 4,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _showRecurringDatesModal(context, r, isDark),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.repeat,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Circular checkbox in top right (always tappable)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      print('Checkbox tapped for reminder: ${r.title}');
                      if (!r.isCompleted) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Mark as Complete?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to mark this reminder as complete?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LoggitColors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Complete',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) {
                          print('User cancelled marking as complete');
                          return;
                        }
                      }
                      print('Updating reminder completion status...');
                      final updated = r.copyWith(isCompleted: !r.isCompleted);
                      print(
                        'Updated reminder isCompleted: ${updated.isCompleted}',
                      );
                      await RemindersService.updateReminder(updated);
                      print('Reminder updated in storage');

                      // Update the local reminders list directly
                      final index = reminders.indexWhere(
                        (reminder) => reminder.timestamp == r.timestamp,
                      );
                      if (index != -1) {
                        reminders[index] = updated;
                        setState(() {});
                        print('Local reminders list updated, UI rebuilt');
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: r.isCompleted
                              ? LoggitColors.teal
                              : Colors.grey[400]!,
                          width: 2.2,
                        ),
                        color: r.isCompleted ? LoggitColors.teal : Colors.white,
                      ),
                      child: r.isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridReminderCard(Reminder r, bool isDark) {
    return ValueListenableBuilder<String?>(
      valueListenable: openDeleteReminderTitle,
      builder: (context, openDeleteTitle, child) {
        final isOpen = openDeleteTitle == r.title + r.reminderTime.toString();

        return GestureDetector(
          onTap: () {
            // Close any open delete overlay when tapping anywhere on the card
            if (openDeleteReminderTitle.value != null) {
              openDeleteReminderTitle.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                // Main card
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (details.delta.dx < -2) {
                        openDeleteReminderTitle.value =
                            r.title + r.reminderTime.toString();
                      }
                    },
                    onHorizontalDragEnd: (details) {},
                    onTap: () {
                      // Close any open delete overlay when tapping the card
                      if (openDeleteReminderTitle.value != null) {
                        openDeleteReminderTitle.value = null;
                        return;
                      }
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        // Close any open delete overlay when tapping the card
                        if (openDeleteReminderTitle.value != null) {
                          openDeleteReminderTitle.value = null;
                          return;
                        }
                        final result = await showReminderEditModal(
                          context,
                          initial: r,
                        );
                        if (result is Reminder) {
                          await RemindersService.updateReminder(result);
                          await _loadReminders();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: r.isCompleted
                                ? LoggitColors.teal.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 32), // Title down one line
                                // Title
                                Text(
                                  r.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                // Description
                                if (r.description != null &&
                                    r.description!.isNotEmpty)
                                  Text(
                                    r.description!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (r.description != null &&
                                    r.description!.isNotEmpty)
                                  SizedBox(height: 4),
                                Spacer(), // Restore Spacer to push date and status to bottom
                                // Date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 11,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(r.reminderTime),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 8,
                                ), // Space between date and status
                                // Status pill at bottom
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: r.isCompleted
                                        ? Colors.green.withOpacity(0.13)
                                        : Colors.orange.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        r.isCompleted
                                            ? Icons.check_circle
                                            : Icons.hourglass_empty,
                                        color: r.isCompleted
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 9,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        r.isCompleted
                                            ? 'Completed'
                                            : 'Upcoming',
                                        style: TextStyle(
                                          color: r.isCompleted
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Checkbox in top right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final updated = r.copyWith(
                                    isCompleted: !r.isCompleted,
                                  );
                                  await RemindersService.updateReminder(
                                    updated,
                                  );
                                  final index = reminders.indexWhere(
                                    (reminder) =>
                                        reminder.timestamp == r.timestamp,
                                  );
                                  if (index != -1) {
                                    reminders[index] = updated;
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: r.isCompleted
                                          ? Colors.green
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: r.isCompleted
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                                  child: r.isCompleted
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            // Repeat icon for recurring reminders
                            if (r.recurrenceType != RecurrenceType.none)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showRecurringDatesModal(
                                    context,
                                    r,
                                    isDark,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.repeat,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Delete overlay - slides in from outside like main task card
                AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 6, // Account for card padding
                  bottom: 6, // Account for card padding
                  right: isOpen ? 0 : -56,
                  width: 56,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: isOpen ? 1.0 : 0.0,
                    child: Material(
                      color: Colors.red.withOpacity(0.95),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          10,
                        ), // Match card's inner radius
                        bottomRight: Radius.circular(
                          10,
                        ), // Match card's inner radius
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        onTap: isOpen
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Delete Reminder'),
                                    content: Text(
                                      'Are you sure you want to delete this reminder?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await RemindersService.deleteReminder(r);
                                  await _loadReminders();
                                }
                                openDeleteReminderTitle.value = null;
                              }
                            : null,
                        child: SizedBox.expand(
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactReminderCard(Reminder r, bool isDark) {
    return ValueListenableBuilder<String?>(
      valueListenable: openDeleteReminderTitle,
      builder: (context, openDeleteTitle, child) {
        final isOpen = openDeleteTitle == r.title + r.reminderTime.toString();

        return GestureDetector(
          onTap: () {
            // Close any open delete overlay when tapping anywhere on the card
            if (openDeleteReminderTitle.value != null) {
              openDeleteReminderTitle.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                // Main card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: r.isCompleted
                          ? LoggitColors.teal.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (details.delta.dx < -2) {
                        openDeleteReminderTitle.value =
                            r.title + r.reminderTime.toString();
                      }
                    },
                    onHorizontalDragEnd: (details) {},
                    onTap: () {
                      // Close any open delete overlay when tapping the card
                      if (openDeleteReminderTitle.value != null) {
                        openDeleteReminderTitle.value = null;
                        return;
                      }
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        // Close any open delete overlay when tapping the card
                        if (openDeleteReminderTitle.value != null) {
                          openDeleteReminderTitle.value = null;
                          return;
                        }
                        final result = await showReminderEditModal(
                          context,
                          initial: r,
                        );
                        if (result is Reminder) {
                          await RemindersService.updateReminder(result);
                          await _loadReminders();
                        }
                      },
                      child: Row(
                        children: [
                          // Status indicator
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: r.isCompleted
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _formatDateTime(r.reminderTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Repeat icon and checkbox
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Repeat icon for recurring reminders
                              if (r.recurrenceType != RecurrenceType.none)
                                GestureDetector(
                                  onTap: () => _showRecurringDatesModal(
                                    context,
                                    r,
                                    isDark,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.repeat,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              // Checkbox
                              GestureDetector(
                                onTap: () async {
                                  final updated = r.copyWith(
                                    isCompleted: !r.isCompleted,
                                  );
                                  await RemindersService.updateReminder(
                                    updated,
                                  );
                                  final index = reminders.indexWhere(
                                    (reminder) =>
                                        reminder.timestamp == r.timestamp,
                                  );
                                  if (index != -1) {
                                    reminders[index] = updated;
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: r.isCompleted
                                          ? Colors.green
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: r.isCompleted
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                                  child: r.isCompleted
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Delete overlay - slides in from outside like main task card
                AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0, // Align with top edge of card
                  bottom: 0, // Align with bottom edge of card
                  right: isOpen ? 0 : -80,
                  width: 80,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: isOpen ? 1.0 : 0.0,
                    child: Material(
                      color: Colors.red.withOpacity(0.95),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          10,
                        ), // Match card's inner radius
                        bottomRight: Radius.circular(
                          10,
                        ), // Match card's inner radius
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        onTap: isOpen
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Delete Reminder'),
                                    content: Text(
                                      'Are you sure you want to delete this reminder?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await RemindersService.deleteReminder(r);
                                  await _loadReminders();
                                }
                                openDeleteReminderTitle.value = null;
                              }
                            : null,
                        child: SizedBox.expand(
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OverlayDeleteReminderCard extends StatefulWidget {
  final Widget child;
  final Reminder reminder;
  final Future<void> Function(BuildContext context) onDelete;
  final ValueNotifier<String?> openDeleteReminderTitle;
  final VoidCallback? onTap;
  const OverlayDeleteReminderCard({
    super.key,
    required this.child,
    required this.reminder,
    required this.onDelete,
    required this.openDeleteReminderTitle,
    this.onTap,
  });
  @override
  State<OverlayDeleteReminderCard> createState() =>
      _OverlayDeleteReminderCardState();
}

class _OverlayDeleteReminderCardState extends State<OverlayDeleteReminderCard> {
  @override
  void initState() {
    super.initState();
    widget.openDeleteReminderTitle.addListener(_onOpenDeleteChanged);
  }

  @override
  void dispose() {
    widget.openDeleteReminderTitle.removeListener(_onOpenDeleteChanged);
    super.dispose();
  }

  void _onOpenDeleteChanged() {
    setState(() {});
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx < -2) {
      widget.openDeleteReminderTitle.value =
          widget.reminder.title + widget.reminder.reminderTime.toString();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {}

  @override
  Widget build(BuildContext context) {
    final showDelete =
        widget.openDeleteReminderTitle.value ==
        widget.reminder.title + widget.reminder.reminderTime.toString();
    return Stack(
      children: [
        widget.child,
        // Delete overlay (no gesture detection to avoid conflicts)
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: showDelete ? 0 : -72,
          width: 72,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: showDelete ? 1.0 : 0.0,
            child: Material(
              color: Colors.red.withOpacity(0.95),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: InkWell(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                onTap: () async {
                  await widget.onDelete(context);
                },
                child: Center(
                  child: Icon(Icons.delete, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/utils/responsive.dart';
import '../../services/reminders_service.dart';
import 'reminder_model.dart';
import 'reminder_edit_modal.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    for (int i = 0; i < 14; i++) {
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
        ? DateTime(
            DateTime.now().year, // TODO: Replace with real year/month logic
            DateTime.now().month,
            dates[selectedDayIndex],
          )
        : null;
    // Filter reminders based on selected filter and date
    List<Reminder> filteredReminders = [];

    switch (selectedFilter) {
      case 0: // All
        // If a specific date is selected, filter by that date
        if (selectedDayIndex >= 0 && selectedDate != null) {
          filteredReminders = reminders.where((r) {
            // If not recurring, match date
            if (r.recurrenceType == RecurrenceType.none) {
              return r.reminderTime.year == selectedDate.year &&
                  r.reminderTime.month == selectedDate.month &&
                  r.reminderTime.day == selectedDate.day;
            }
            // If recurring, check if selectedDate is in recurrence
            if (r.endDate != null && selectedDate.isAfter(r.endDate!)) {
              return false;
            }
            if (selectedDate.isBefore(r.reminderTime)) return false;
            switch (r.recurrenceType) {
              case RecurrenceType.daily:
                return !_isAfterEnd(r, selectedDate) &&
                    !selectedDate.isBefore(r.reminderTime);
              case RecurrenceType.weekly:
                return !_isAfterEnd(r, selectedDate) &&
                    selectedDate.weekday == r.reminderTime.weekday &&
                    !selectedDate.isBefore(r.reminderTime);
              case RecurrenceType.monthly:
                return !_isAfterEnd(r, selectedDate) &&
                    selectedDate.day == r.reminderTime.day &&
                    !selectedDate.isBefore(r.reminderTime);
              case RecurrenceType.custom:
                return !_isAfterEnd(r, selectedDate) &&
                    r.customDays?.contains(selectedDate.weekday) == true &&
                    !selectedDate.isBefore(r.reminderTime);
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
        } else {
          // No specific date selected, show all reminders
          filteredReminders = reminders;
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
                ],
              ),
            ),
            // Scrollable content
            Expanded(
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
                        child: SizedBox(
                          height: 76,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: selected ? Colors.white : Colors.black,
                                ),
                              ),
                              selected: selected,
                              onSelected: (_) {
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
                            child: TextField(
                              controller: _searchController,
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
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.tune, color: Colors.grey[700]),
                              onPressed: () {
                                // TODO: Open filter modal
                              },
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
                      ...filteredReminders.map(
                        (r) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: OverlayDeleteReminderCard(
                            reminder: r,
                            openDeleteReminderTitle: openDeleteReminderTitle,
                            onDelete: (ctx) async {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (ctx2) => AlertDialog(
                                  title: Text('Delete Reminder'),
                                  content: Text(
                                    'Are you sure you want to delete this reminder?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx2, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx2, true),
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
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 120),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: r.isCompleted
                                      ? LoggitColors.teal.withOpacity(0.55)
                                      : Colors.orange.withOpacity(0.55),
                                  width: 2,
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
                                              r.title +
                                              r.reminderTime.toString();
                                        }
                                      },
                                      onHorizontalDragEnd: (details) {},
                                      onTap: () {
                                        // Close any open delete overlay when tapping the card
                                        if (openDeleteReminderTitle.value !=
                                            null) {
                                          openDeleteReminderTitle.value = null;
                                          return;
                                        }
                                      },
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () async {
                                          if (openDeleteReminderTitle.value !=
                                              null) {
                                            openDeleteReminderTitle.value =
                                                null;
                                            return;
                                          }
                                          final result =
                                              await showReminderEditModal(
                                                context,
                                                initial: r,
                                              );
                                          if (result is Reminder) {
                                            await RemindersService.updateReminder(
                                              result,
                                            );
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
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
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
                                            if (confirm == true) {
                                              await RemindersService.deleteReminder(
                                                r,
                                              );
                                              await _loadReminders();
                                            }
                                          }
                                        },
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Accent icon - status indicator only
                                            Column(
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getBellBackgroundColor(
                                                          r,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _getBellIcon(r),
                                                    color: _getBellIconColor(r),
                                                    size: 26,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  _getBellStatusText(r),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: _getBellStatusColor(
                                                      r,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 16),
                                            // Main content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r.title,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          Responsive.responsiveFont(
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
                                                        _formatDateTime(
                                                          r.reminderTime,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize:
                                                              Responsive.responsiveFont(
                                                                context,
                                                                13,
                                                                min: 10,
                                                                max: 18,
                                                              ),
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  SizedBox(height: 10),
                                                  // Status pill aligned to the left
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: r.isCompleted
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.13,
                                                                )
                                                          : Colors.orange
                                                                .withOpacity(
                                                                  0.13,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          r.isCompleted
                                                              ? Icons
                                                                    .check_circle
                                                              : Icons
                                                                    .hourglass_empty,
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
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13,
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
                                      ),
                                    ),
                                  ),
                                  // Circular checkbox in top right (always tappable)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior
                                          .translucent, // Ensure all taps are caught
                                      onTap: () async {
                                        print(
                                          'Checkbox tapped for reminder: ${r.title}',
                                        );
                                        if (!r.isCompleted) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        LoggitColors.teal,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: Text(
                                                    'Complete',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) {
                                            print(
                                              'User cancelled marking as complete',
                                            );
                                            return;
                                          }
                                        }
                                        print(
                                          'Updating reminder completion status...',
                                        );
                                        final updated = r.copyWith(
                                          isCompleted: !r.isCompleted,
                                        );
                                        print(
                                          'Updated reminder isCompleted: ${updated.isCompleted}',
                                        );
                                        await RemindersService.updateReminder(
                                          updated,
                                        );
                                        print('Reminder updated in storage');

                                        // Update the local reminders list directly
                                        final index = reminders.indexWhere(
                                          (reminder) =>
                                              reminder.timestamp == r.timestamp,
                                        );
                                        if (index != -1) {
                                          reminders[index] = updated;
                                          setState(() {});
                                          print(
                                            'Local reminders list updated, UI rebuilt',
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 28, // Reduced from 36
                                        height: 28, // Reduced from 36
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: r.isCompleted
                                                ? LoggitColors.teal
                                                : Colors.grey[400]!,
                                            width: 2.2,
                                          ),
                                          color: r.isCompleted
                                              ? LoggitColors.teal
                                              : Colors.white,
                                        ),
                                        child: r.isCompleted
                                            ? Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size:
                                                    16, // Slightly smaller for new size
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LoggitColors.teal,
        elevation: 6,
        onPressed: () async {
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
    return r.endDate != null && d != null && d.isAfter(r.endDate!);
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

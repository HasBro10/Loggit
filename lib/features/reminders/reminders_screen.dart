import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import '../../shared/utils/responsive.dart';
import '../../services/reminders_service.dart';
import 'reminder_model.dart';
import 'reminder_edit_modal.dart';

class RemindersScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RemindersScreen({super.key, required this.onBack});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // Set default selectedDayIndex to today
  late int selectedDayIndex;
  int selectedFilter = -1; // -1 means no filter selected
  final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  final List<int> dates = [14, 16, 17, 18, 19];

  List<Reminder> reminders = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set selectedDayIndex to today's day
    final today = DateTime.now();
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final todayAbbr = weekDays[today.weekday % 7];
    final idx = days.indexOf(todayAbbr);
    selectedDayIndex = idx >= 0 ? idx : 0;
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

  Future<void> _loadReminders() async {
    setState(() => isLoading = true);
    reminders = await RemindersService.loadReminders();
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
    super.dispose();
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
    // Filter reminders by selected date (ignore time), including recurrence
    List<Reminder> filteredReminders = reminders.where((r) {
      // If "All" filter is selected, show all reminders regardless of date
      if (selectedFilter == 0) {
        return true;
      }

      // If a specific date is selected, filter by that date
      if (selectedDayIndex >= 0 && selectedDate != null) {
        // If not recurring, match date
        if (r.recurrenceType == RecurrenceType.none) {
          return r.reminderTime.year == selectedDate.year &&
              r.reminderTime.month == selectedDate.month &&
              r.reminderTime.day == selectedDate.day;
        }
        // If recurring, check if selectedDate is in recurrence
        if (r.endDate != null && selectedDate.isAfter(r.endDate!)) return false;
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
      }

      // If no date is selected and not "All" filter, show nothing
      return false;
    }).toList();
    // Further filter by status (only if not "All" filter)
    if (selectedFilter == 1) {
      filteredReminders = filteredReminders
          .where((r) => r.isCompleted)
          .toList();
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
                    'Reminders',
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
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: days.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, i) {
                              final selected =
                                  i == selectedDayIndex &&
                                  selectedDayIndex >= 0;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDayIndex = i;
                                    selectedFilter =
                                        -1; // Deselect 'All' filter
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 180),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: pillVMargin - 2,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: pillHPadding,
                                    vertical: pillVPadding - 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Color(0xFF1CCFCF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        days[i],
                                        style: TextStyle(
                                          fontSize: dayFontSize,
                                          color: selected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        dates[i].toString(),
                                        style: TextStyle(
                                          fontSize: dateFontSize,
                                          color: selected
                                              ? Colors.white
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
                        children: List.generate(2, (i) {
                          final labels = ['All', 'Completed'];
                          final selected = i == selectedFilter;
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
                                  selectedFilter = i;
                                  // If "All" is selected, deselect any date
                                  if (i == 0) {
                                    selectedDayIndex = -1;
                                  }
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
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          if (selectedDayIndex >= 0)
                            Text(
                              '${days[selectedDayIndex]} ${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: LoggitSpacing.md),
                      // Reminders list
                      ...filteredReminders.map(
                        (r) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
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
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(r.reminderTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (r.recurrenceType != RecurrenceType.none)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _recurrenceText(r),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal[700],
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: r.isCompleted
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              r.isCompleted
                                                  ? Icons.check_circle
                                                  : Icons.hourglass_empty,
                                              color: r.isCompleted
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              r.isCompleted
                                                  ? 'Completed'
                                                  : 'Pending',
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
        child: Icon(Icons.add, color: Colors.white, size: 32),
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
}

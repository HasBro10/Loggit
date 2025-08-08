import 'package:flutter/material.dart';
import '../../shared/design/color_guide.dart';
import '../../shared/design/spacing.dart';
import 'reminder_model.dart';
import 'package:flutter/cupertino.dart';

Future<Reminder?> showReminderEditModal(
  BuildContext context, {
  Reminder? initial,
}) {
  final isEditing = initial != null;
  final titleController = TextEditingController(text: initial?.title ?? '');
  final descController = TextEditingController(
    text: initial?.description ?? '',
  );
  DateTime? date = isEditing ? initial.reminderTime : null;

  // Reminder advance time options
  final List<String> advanceTimeOptions = [
    'At the time',
    '5 minutes before',
    '15 minutes before',
    '30 minutes before',
    '1 hour before',
    '2 hours before',
    '1 day before',
  ];
  String selectedAdvanceTime = 'At the time';

  // Recurrence variables
  RecurrenceType recurrenceType = isEditing
      ? (initial.recurrenceType ?? RecurrenceType.none)
      : RecurrenceType.none;
  int? repeatDuration = isEditing ? initial.repeatDuration : null;
  String? repeatDurationType = isEditing ? initial.repeatDurationType : null;

  // Set the correct advance time when editing
  if (isEditing && initial.advanceTiming != null) {
    final advanceTiming = initial.advanceTiming!;
    print(
      'DEBUG: Setting advance time dropdown. Stored advanceTiming: "$advanceTiming"',
    );
    // Use exact matching to avoid false positives
    if (advanceTiming == '5 minutes before') {
      selectedAdvanceTime = '5 minutes before';
      print('DEBUG: Matched to "5 minutes before"');
    } else if (advanceTiming == '15 minutes before') {
      selectedAdvanceTime = '15 minutes before';
      print('DEBUG: Matched to "15 minutes before"');
    } else if (advanceTiming == '30 minutes before' ||
        advanceTiming == 'half an hour before') {
      selectedAdvanceTime = '30 minutes before';
      print('DEBUG: Matched to "30 minutes before"');
    } else if (advanceTiming == '1 hour before' ||
        advanceTiming == 'one hour before') {
      selectedAdvanceTime = '1 hour before';
      print('DEBUG: Matched to "1 hour before"');
    } else if (advanceTiming == '2 hours before') {
      selectedAdvanceTime = '2 hours before';
      print('DEBUG: Matched to "2 hours before"');
    } else if (advanceTiming == '1 day before') {
      selectedAdvanceTime = '1 day before';
      print('DEBUG: Matched to "1 day before"');
    } else {
      print('DEBUG: No match found for advanceTiming: "$advanceTiming"');
    }
  }

  // Validation state variables
  final ValueNotifier<bool> showTitleError = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showDateError = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showTimeError = ValueNotifier<bool>(false);
  final ScrollController modalScrollController = ScrollController();

  return showModalBottomSheet<Reminder>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) {
      String? error;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.6,
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
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Text(
                          isEditing ? 'Edit Reminder' : 'New Reminder',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content below
                  Expanded(
                    child: SingleChildScrollView(
                      controller: modalScrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                labelText: null,
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: showTitleError.value
                                      ? BorderSide(color: Colors.red, width: 2)
                                      : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: showTitleError.value
                                      ? BorderSide(color: Colors.red, width: 2)
                                      : BorderSide(
                                          color: LoggitColors.teal,
                                          width: 2,
                                        ),
                                ),
                                hintText: 'Enter title',
                              ),
                            ),
                            SizedBox(height: 14),
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                labelText: null,
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'Enter description',
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Date & Time',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                // Date pill button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final initialDate =
                                          date ?? DateTime.now();
                                      await _showDatePicker(
                                        context,
                                        initialDate: initialDate,
                                        onDateChanged: (selectedDate) {
                                          setModalState(() {
                                            // Preserve the time if it exists, otherwise use current time
                                            final currentTime = date != null
                                                ? TimeOfDay.fromDateTime(date!)
                                                : TimeOfDay.now();
                                            date = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              selectedDate.day,
                                              currentTime.hour,
                                              currentTime.minute,
                                            );
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: showDateError.value
                                              ? Colors.red
                                              : Colors.grey[300]!,
                                          width: showDateError.value ? 2 : 1,
                                        ),
                                      ),
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
                                          Flexible(
                                            child: Text(
                                              date == null
                                                  ? 'Pick Date'
                                                  : '${_weekdayString(date!.weekday)}, ${date!.day} ${_monthString(date!.month)} ${date!.year}',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Time pill button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final initialTime = date != null
                                          ? TimeOfDay.fromDateTime(date!)
                                          : TimeOfDay.now();
                                      await _showTimePicker(
                                        context,
                                        initialTime: initialTime,
                                        onTimeChanged: (selectedTime) {
                                          setModalState(() {
                                            // Preserve the date if it exists, otherwise use today
                                            final currentDate =
                                                date ?? DateTime.now();
                                            date = DateTime(
                                              currentDate.year,
                                              currentDate.month,
                                              currentDate.day,
                                              selectedTime.hour,
                                              selectedTime.minute,
                                            );
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: showTimeError.value
                                              ? Colors.red
                                              : Colors.grey[300]!,
                                          width: showTimeError.value ? 2 : 1,
                                        ),
                                      ),
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
                                          Flexible(
                                            child: Text(
                                              date == null
                                                  ? 'Pick Time'
                                                  : TimeOfDay.fromDateTime(
                                                      date!,
                                                    ).format(context),
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Remind me',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              height: 48, // Match TextField height
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedAdvanceTime,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  selectedItemBuilder: (context) =>
                                      advanceTimeOptions
                                          .map(
                                            (option) => Padding(
                                              padding: const EdgeInsets.only(
                                                left: 14.0,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(option),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  items: advanceTimeOptions.map((
                                    String option,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: option,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 14.0,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(option),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      selectedAdvanceTime = newValue;
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 14),
                            // Recurrence section
                            Text(
                              'Repeat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<RecurrenceType>(
                                  value: recurrenceType,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  selectedItemBuilder: (context) =>
                                      [
                                            RecurrenceType.none,
                                            RecurrenceType.daily,
                                            RecurrenceType.weekly,
                                            RecurrenceType.monthly,
                                          ]
                                          .map(
                                            (type) => Padding(
                                              padding: const EdgeInsets.only(
                                                left: 14.0,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _getRecurrenceTypeText(type),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  items:
                                      [
                                        RecurrenceType.none,
                                        RecurrenceType.daily,
                                        RecurrenceType.weekly,
                                        RecurrenceType.monthly,
                                      ].map((RecurrenceType type) {
                                        return DropdownMenuItem<RecurrenceType>(
                                          value: type,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 14.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _getRecurrenceTypeText(type),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (RecurrenceType? newValue) {
                                    if (newValue != null) {
                                      setModalState(() {
                                        recurrenceType = newValue;
                                        // Reset duration when changing recurrence type
                                        repeatDuration = null;
                                        repeatDurationType = null;
                                      });

                                      // Auto-scroll to show the duration field when it appears
                                      if (newValue != RecurrenceType.none) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (modalScrollController
                                                  .hasClients) {
                                                modalScrollController.animateTo(
                                                  modalScrollController
                                                      .position
                                                      .maxScrollExtent,
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            });
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Duration dropdown (only show if recurrence is selected)
                            if (recurrenceType != RecurrenceType.none) ...[
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.transparent),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value:
                                        repeatDuration == null ||
                                            repeatDurationType == null
                                        ? 'infinite'
                                        : '$repeatDuration $repeatDurationType',
                                    hint: Text('Select duration'),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                    items: () {
                                      final durationType =
                                          recurrenceType == RecurrenceType.daily
                                          ? 'days'
                                          : recurrenceType ==
                                                RecurrenceType.weekly
                                          ? 'weeks'
                                          : 'months';

                                      final items =
                                          <DropdownMenuItem<String>>[];

                                      // Add specific duration options (1 to 12)
                                      for (int i = 1; i <= 12; i++) {
                                        items.add(
                                          DropdownMenuItem(
                                            value: '$i $durationType',
                                            child: Text(
                                              '$i ${durationType == 'days'
                                                  ? 'day'
                                                  : durationType == 'weeks'
                                                  ? 'week'
                                                  : 'month'}${i == 1
                                                  ? ''
                                                  : durationType == 'days'
                                                  ? 's'
                                                  : durationType == 'weeks'
                                                  ? 's'
                                                  : 's'}',
                                            ),
                                          ),
                                        );
                                      }

                                      // Add "Until further notice" option
                                      items.add(
                                        DropdownMenuItem(
                                          value: 'infinite',
                                          child: Text('Until further notice'),
                                        ),
                                      );

                                      return items;
                                    }(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        if (value == 'infinite') {
                                          repeatDuration = null;
                                          repeatDurationType = null;
                                        } else if (value != null) {
                                          final parts = value.split(' ');
                                          repeatDuration = int.tryParse(
                                            parts[0],
                                          );
                                          repeatDurationType = parts[1];
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 14),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            // TODO: Recurrence, validation
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
                    child: Container(
                      color: Colors.white, // Ensure solid background
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
                                final title = titleController.text.trim();
                                bool hasError = false;

                                // Validate title
                                if (title.isEmpty) {
                                  showTitleError.value = true;
                                  hasError = true;
                                } else {
                                  showTitleError.value = false;
                                }

                                // Validate date and time
                                if (date == null) {
                                  showDateError.value = true;
                                  showTimeError.value = true;
                                  hasError = true;
                                } else {
                                  showDateError.value = false;
                                  showTimeError.value = false;
                                }

                                if (hasError) {
                                  setModalState(() {
                                    // Force rebuild to show red borders
                                  });
                                  return;
                                }

                                if (date!.isBefore(DateTime.now())) {
                                  setModalState(
                                    () => error =
                                        'Date/time must be in the future.',
                                  );
                                  return;
                                }
                                setModalState(() => error = null);

                                // Store the original time, not the calculated time
                                // The advance timing will be used to determine when to actually trigger the reminder
                                final reminder = Reminder(
                                  title: title,
                                  description:
                                      descController.text.trim().isEmpty
                                      ? null
                                      : descController.text.trim(),
                                  reminderTime: date!, // Store original time
                                  isCompleted: initial?.isCompleted ?? false,
                                  timestamp:
                                      initial?.timestamp ?? DateTime.now(),
                                  advanceTiming:
                                      selectedAdvanceTime == 'At the time'
                                      ? null
                                      : selectedAdvanceTime,
                                  recurrenceType: recurrenceType,
                                  repeatDuration: repeatDuration,
                                  repeatDurationType: repeatDurationType,
                                );
                                Navigator.pop(context, reminder);
                              },
                              child: Text('Save'),
                            ),
                          ),
                        ],
                      ),
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

String _priorityFromDescription(String? desc) {
  final d = desc?.toLowerCase() ?? '';
  if (d.contains('high')) return 'High Priority';
  if (d.contains('medium')) return 'Medium Priority';
  if (d.contains('low')) return 'Low Priority';
  return 'Medium Priority';
}

Future<void> _showDateTimePicker(
  BuildContext context, {
  required DateTime? initialDate,
  required ValueChanged<DateTime> onDateTimeChanged,
}) async {
  final now = DateTime.now();
  DateTime tempDate = initialDate ?? now;
  TimeOfDay tempTime = TimeOfDay.fromDateTime(tempDate);
  final initialDateIndex = tempDate
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final safeInitialDateIndex = initialDateIndex.clamp(0, 29);

  // If the selected date is today, set default time to now (current hour/minute)
  if (tempDate.year == now.year &&
      tempDate.month == now.month &&
      tempDate.day == now.day) {
    tempTime = TimeOfDay(hour: now.hour, minute: now.minute);
    tempDate = DateTime(
      tempDate.year,
      tempDate.month,
      tempDate.day,
      now.hour,
      now.minute,
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
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
              color: Colors.white,
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
                        final availableHours = List.generate(24, (hour) {
                          final isToday =
                              tempDate.year == now.year &&
                              tempDate.month == now.month &&
                              tempDate.day == now.day;
                          final isPastHour = isToday && hour < now.hour;
                          if (isPastHour) return null;
                          return hour;
                        }).whereType<int>().toList();
                        final initialHourIndex =
                            availableHours.contains(now.hour)
                            ? availableHours.indexOf(now.hour)
                            : 0;
                        final isToday =
                            tempDate.year == now.year &&
                            tempDate.month == now.month &&
                            tempDate.day == now.day;
                        final isCurrentHour = tempTime.hour == now.hour;
                        final availableMinutes = List.generate(60, (min) {
                          final isPastMinute =
                              isToday && isCurrentHour && min < now.minute;
                          if (isPastMinute) return null;
                          return min;
                        }).whereType<int>().toList();
                        final initialMinuteIndex =
                            availableMinutes.contains(now.minute)
                            ? availableMinutes.indexOf(now.minute)
                            : 0;
                        return Row(
                          children: [
                            // Date picker wheel
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: pickerHeight,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: safeInitialDateIndex,
                                  ),
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    final baseDate = DateTime.now();
                                    final selectedDate = baseDate.add(
                                      Duration(days: index),
                                    );
                                    tempDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      tempTime.hour,
                                      tempTime.minute,
                                    );
                                    setPickerState(() {});
                                  },
                                  children: List.generate(30, (i) {
                                    final date = DateTime.now().add(
                                      Duration(days: i),
                                    );
                                    final isSelected =
                                        i == safeInitialDateIndex;
                                    return Center(
                                      child: Text(
                                        '${_weekdayString(date.weekday)}, ${date.day} ${_monthString(date.month)}',
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 16,
                                          color: Colors.black,
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
                                            initialItem: initialHourIndex,
                                          ),
                                      itemExtent: 40,
                                      onSelectedItemChanged: (index) {
                                        tempTime = TimeOfDay(
                                          hour: availableHours[index],
                                          minute: tempTime.minute,
                                        );
                                        tempDate = DateTime(
                                          tempDate.year,
                                          tempDate.month,
                                          tempDate.day,
                                          tempTime.hour,
                                          tempTime.minute,
                                        );
                                        setPickerState(() {});
                                      },
                                      children: availableHours
                                          .map(
                                            (hour) => Center(
                                              child: Text(
                                                hour.toString().padLeft(2, '0'),
                                                style: TextStyle(fontSize: 16),
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
                                            initialItem: initialMinuteIndex,
                                          ),
                                      itemExtent: 40,
                                      onSelectedItemChanged: (index) {
                                        tempTime = TimeOfDay(
                                          hour: tempTime.hour,
                                          minute: availableMinutes[index],
                                        );
                                        tempDate = DateTime(
                                          tempDate.year,
                                          tempDate.month,
                                          tempDate.day,
                                          tempTime.hour,
                                          tempTime.minute,
                                        );
                                        setPickerState(() {});
                                      },
                                      children: availableMinutes
                                          .map(
                                            (min) => Center(
                                              child: Text(
                                                min.toString().padLeft(2, '0'),
                                                style: TextStyle(fontSize: 16),
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
                ElevatedButton(
                  onPressed: () {
                    onDateTimeChanged(tempDate);
                    Navigator.of(context).pop();
                  },
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
                  child: Text('Set Date & Time'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _weekdayString(int day) {
  switch (day) {
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    case 7:
      return 'Sun';
    default:
      return '';
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

Future<void> _showDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required ValueChanged<DateTime> onDateChanged,
}) async {
  final now = DateTime.now();
  DateTime tempDate = initialDate;
  DateTime displayedMonth = DateTime(tempDate.year, tempDate.month, 1);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                // Calendar header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setModalState(() {
                          displayedMonth = DateTime(
                            displayedMonth.year,
                            displayedMonth.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${_monthString(displayedMonth.month)} ${displayedMonth.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setModalState(() {
                          displayedMonth = DateTime(
                            displayedMonth.year,
                            displayedMonth.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Calendar grid
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: LoggitColors.teal.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Day headers
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: LoggitColors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((
                            day,
                          ) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: LoggitColors.teal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Calendar days
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: _buildCalendarWeeks(
                            displayedMonth,
                            tempDate,
                            isDark,
                            (selectedDate) {
                              setModalState(() {
                                tempDate = selectedDate;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    onDateChanged(tempDate);
                    Navigator.of(context).pop();
                  },
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
                  child: Text('Set Date'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

List<Widget> _buildCalendarWeeks(
  DateTime displayedMonth,
  DateTime selectedDate,
  bool isDark,
  ValueChanged<DateTime> onDateSelected,
) {
  final firstDayOfMonth = DateTime(
    displayedMonth.year,
    displayedMonth.month,
    1,
  );
  final lastDayOfMonth = DateTime(
    displayedMonth.year,
    displayedMonth.month + 1,
    0,
  );
  final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
  final daysInMonth = lastDayOfMonth.day;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  List<Widget> weeks = [];
  List<Widget> currentWeek = [];

  // Add empty cells for days before the first day of the month
  for (int i = 0; i < firstWeekday; i++) {
    currentWeek.add(Expanded(child: Container()));
  }

  // Add days of the month
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(displayedMonth.year, displayedMonth.month, day);
    final isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(today);

    currentWeek.add(
      Expanded(
        child: GestureDetector(
          onTap: isPast ? null : () => onDateSelected(date),
          child: Container(
            height: 40,
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? LoggitColors.teal
                  : isToday
                  ? LoggitColors.teal.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: LoggitColors.teal, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isPast
                      ? (isDark ? Colors.grey[600] : Colors.grey[400])
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (currentWeek.length == 7) {
      weeks.add(Row(children: currentWeek));
      currentWeek = [];
    }
  }

  // Add remaining days to complete the last week
  while (currentWeek.length < 7) {
    currentWeek.add(Expanded(child: Container()));
  }
  if (currentWeek.isNotEmpty) {
    weeks.add(Row(children: currentWeek));
  }

  return weeks;
}

Future<void> _showTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onTimeChanged,
}) async {
  TimeOfDay tempTime = initialTime;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                // Time picker
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? Colors.black87 : Colors.grey[50]!,
                        isDark ? Colors.black87.withOpacity(0.8) : Colors.white,
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
                              setModalState(() {
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
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
                              setModalState(() {
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    onTimeChanged(tempTime);
                    Navigator.of(context).pop();
                  },
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
                  child: Text('Set Time'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _getRecurrenceTypeText(RecurrenceType type) {
  switch (type) {
    case RecurrenceType.none:
      return 'No repeat';
    case RecurrenceType.daily:
      return 'Daily';
    case RecurrenceType.weekly:
      return 'Weekly';
    case RecurrenceType.monthly:
      return 'Monthly';
    case RecurrenceType.custom:
      return 'Custom';
    case RecurrenceType.everyNDays:
      return 'Every N days';
    case RecurrenceType.everyNWeeks:
      return 'Every N weeks';
    case RecurrenceType.everyNMonths:
      return 'Every N months';
  }
}

// Get only the simple, essential recurrence types
List<RecurrenceType> _getSimpleRecurrenceTypes() {
  return [
    RecurrenceType.none,
    RecurrenceType.daily,
    RecurrenceType.weekly,
    RecurrenceType.monthly,
  ];
}

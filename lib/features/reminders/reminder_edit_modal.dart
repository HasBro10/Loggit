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

  return showModalBottomSheet<Reminder>(
    context: context,
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
            heightFactor: 0.9,
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
                            GestureDetector(
                              onTap: () async {
                                // Always use current time for new reminders
                                final initialPickerDate =
                                    date ?? DateTime.now();
                                await _showDateTimePicker(
                                  context,
                                  initialDate: initialPickerDate,
                                  onDateTimeChanged: (dt) {
                                    setModalState(() {
                                      date = dt;
                                    });
                                  },
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
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
                                      date == null
                                          ? 'Pick Date & Time'
                                          : '${_weekdayString(date!.weekday)}, ${date!.day} ${_monthString(date!.month)} ${date!.year}  ${TimeOfDay.fromDateTime(date!).format(context)}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                              side: BorderSide(color: Colors.black26, width: 1),
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
                              if (title.isEmpty) {
                                setModalState(
                                  () => error = 'Title is required.',
                                );
                                return;
                              }
                              if (date == null) {
                                setModalState(
                                  () => error = 'Date & time is required.',
                                );
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
                              final reminder = Reminder(
                                title: title,
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                                reminderTime: date!,
                                isCompleted: initial?.isCompleted ?? false,
                                timestamp: initial?.timestamp ?? DateTime.now(),
                              );
                              Navigator.pop(context, reminder);
                            },
                            child: Text('Save'),
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

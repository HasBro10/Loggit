import 'package:flutter/material.dart';
import '../../models/log_entry.dart';
import '../tasks/task_model.dart';
import '../reminders/reminder_model.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isConfirmation;
  final Function(bool, [LogEntry?])? onConfirmationResponse;
  final LogEntry? pendingLogEntry;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isConfirmation = false,
    this.onConfirmationResponse,
    this.pendingLogEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color bubbleColor;
    Color textColor;
    BorderRadius borderRadius;
    EdgeInsets margin;

    if (isUser) {
      bubbleColor = isDark
          ? const Color(0xFF005C4B) // WhatsApp dark blue-green
          : const Color(0xFF2A8CFF); // Light mode blue
      textColor = Colors.white;
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(6),
      );
      margin = const EdgeInsets.fromLTRB(60, 6, 12, 6); // right-aligned
    } else if (isConfirmation) {
      bubbleColor = isDark
          ? const Color(0xFF202C33) // WhatsApp dark gray
          : const Color(0xFFF6F9FB); // very light gray/blue
      textColor = isDark ? Colors.white : theme.colorScheme.primary;
      borderRadius = BorderRadius.circular(16);
      margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    } else {
      bubbleColor = isDark
          ? const Color(0xFF202C33) // WhatsApp dark gray
          : const Color(0xFFF1F0F0); // WhatsApp light gray
      textColor = isDark ? Colors.white : const Color(0xFF334155); // slate-700
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(18),
      );
      margin = const EdgeInsets.fromLTRB(12, 6, 60, 6); // left-aligned
    }

    Widget bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: isConfirmation ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        if (isConfirmation && onConfirmationResponse != null) ...[
          const SizedBox(height: 12.0),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF005C4B)
                    : const Color(0xFF2A8CFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                minimumSize: const Size(100, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.10),
              ),
              onPressed: () async {
                if (pendingLogEntry != null) {
                  final updated = await showDialog<LogEntry>(
                    context: context,
                    builder: (context) =>
                        _LogConfirmationDialog(logEntry: pendingLogEntry!),
                  );
                  if (updated != null) {
                    onConfirmationResponse!(true, updated);
                  }
                }
              },
            ),
          ),
        ],
      ],
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: bubbleContent,
      ),
    );
  }
}

class _LogConfirmationDialog extends StatefulWidget {
  final LogEntry logEntry;
  const _LogConfirmationDialog({required this.logEntry});

  @override
  State<_LogConfirmationDialog> createState() => _LogConfirmationDialogState();
}

class _LogConfirmationDialogState extends State<_LogConfirmationDialog> {
  late TextEditingController _titleController;
  late DateTime? _date;
  late TimeOfDay? _time;
  RecurrenceType? _recurrenceType;
  int? _interval;
  List<int>? _customDays;

  @override
  void initState() {
    super.initState();
    if (widget.logEntry is Task) {
      final task = widget.logEntry as Task;
      _titleController = TextEditingController(text: task.title);
      _date = task.dueDate;
      _time = task.timeOfDay;
      _recurrenceType = task.recurrenceType;
      _interval = task.interval;
      _customDays = task.customDays;
    } else if (widget.logEntry is Reminder) {
      final reminder = widget.logEntry as Reminder;
      _titleController = TextEditingController(text: reminder.title);
      _date = reminder.reminderTime;
      _time = TimeOfDay(
        hour: reminder.reminderTime.hour,
        minute: reminder.reminderTime.minute,
      );
      _recurrenceType = RecurrenceType.none;
    } else {
      _titleController = TextEditingController(
        text: widget.logEntry.displayTitle,
      );
      _date = null;
      _time = null;
      _recurrenceType = RecurrenceType.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTask = widget.logEntry is Task;
    final isReminder = widget.logEntry is Reminder;
    return AlertDialog(
      title: Text(
        isTask
            ? 'Confirm Task'
            : isReminder
            ? 'Confirm Reminder'
            : 'Confirm Log',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(
                        _date != null
                            ? '${_date!.day}/${_date!.month}/${_date!.year}'
                            : 'None',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(
                        _time != null ? _time!.format(context) : 'None',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isTask) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrenceType ?? RecurrenceType.none,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: RecurrenceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_recurrenceTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (type) => setState(() => _recurrenceType = type),
              ),
              if (_recurrenceType == RecurrenceType.everyNDays ||
                  _recurrenceType == RecurrenceType.everyNWeeks ||
                  _recurrenceType == RecurrenceType.everyNMonths) ...[
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Interval'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _interval = int.tryParse(val),
                ),
              ],
              if (_recurrenceType == RecurrenceType.custom) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _customDays?.contains(day) ?? false;
                    return FilterChip(
                      label: Text(_weekdayLabel(day)),
                      selected: selected,
                      onSelected: (sel) {
                        setState(() {
                          _customDays = List<int>.from(_customDays ?? []);
                          if (sel) {
                            _customDays!.add(day);
                          } else {
                            _customDays!.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isTask) {
              final orig = widget.logEntry as Task;
              Navigator.pop(
                context,
                orig.copyWith(
                  title: _titleController.text.trim(),
                  dueDate: _date,
                  timeOfDay: _time,
                  recurrenceType: _recurrenceType,
                  interval: _interval,
                  customDays: _customDays,
                ),
              );
            } else if (isReminder) {
              final orig = widget.logEntry as Reminder;
              DateTime reminderTime = _date ?? DateTime.now();
              if (_time != null) {
                reminderTime = DateTime(
                  reminderTime.year,
                  reminderTime.month,
                  reminderTime.day,
                  _time!.hour,
                  _time!.minute,
                );
              }
              Navigator.pop(
                context,
                orig.copyWith(
                  title: _titleController.text.trim(),
                  reminderTime: reminderTime,
                ),
              );
            } else {
              Navigator.pop(context, widget.logEntry);
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _recurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.everyNDays:
        return 'Every N Days';
      case RecurrenceType.everyNWeeks:
        return 'Every N Weeks';
      case RecurrenceType.everyNMonths:
        return 'Every N Months';
      case RecurrenceType.custom:
        return 'Custom Days';
    }
  }

  String _weekdayLabel(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}

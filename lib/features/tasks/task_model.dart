import '../../models/log_entry.dart';
import 'package:flutter/material.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  custom,
  everyNDays,
  everyNWeeks,
  everyNMonths,
}

enum TaskPriority { low, medium, high }

enum TaskStatus { notStarted, inProgress, completed }

enum ReminderType { none, fifteenMinutes, oneHour, oneDay }

class Task implements LogEntry {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  @override
  final DateTime timestamp;
  @override
  final String? category;
  final RecurrenceType recurrenceType;
  final List<int>? customDays; // 1=Mon, 7=Sun
  final int? interval; // for every N days/weeks/months
  final TimeOfDay? timeOfDay;
  final TaskPriority priority;
  final TaskStatus status;
  final ReminderType reminder;

  Task({
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.timestamp,
    this.category,
    this.recurrenceType = RecurrenceType.none,
    this.customDays,
    this.interval,
    this.timeOfDay,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.notStarted,
    this.reminder = ReminderType.none,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? timestamp,
    String? category,
    RecurrenceType? recurrenceType,
    List<int>? customDays,
    int? interval,
    TimeOfDay? timeOfDay,
    TaskPriority? priority,
    TaskStatus? status,
    ReminderType? reminder,
  }) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customDays: customDays ?? this.customDays,
      interval: interval ?? this.interval,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reminder: reminder ?? this.reminder,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'recurrenceType': recurrenceType.name,
      'customDays': customDays,
      'interval': interval,
      'timeOfDay': timeOfDay != null
          ? '${timeOfDay!.hour}:${timeOfDay!.minute}'
          : null,
      'priority': priority.name,
      'status': status.name,
      'reminder': reminder.name,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    RecurrenceType recurrenceType = RecurrenceType.none;
    try {
      recurrenceType = RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrenceType'],
      );
    } catch (_) {}

    TaskPriority priority = TaskPriority.medium;
    try {
      priority = TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      );
    } catch (_) {}

    TaskStatus status = TaskStatus.notStarted;
    try {
      status = TaskStatus.values.firstWhere((e) => e.name == json['status']);
    } catch (_) {}

    ReminderType reminder = ReminderType.none;
    try {
      reminder = ReminderType.values.firstWhere(
        (e) => e.name == json['reminder'],
      );
    } catch (_) {}

    TimeOfDay? timeOfDay;
    if (json['timeOfDay'] != null) {
      final parts = (json['timeOfDay'] as String).split(':');
      if (parts.length == 2) {
        timeOfDay = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    return Task(
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
      recurrenceType: recurrenceType,
      customDays: json['customDays'] != null
          ? List<int>.from(json['customDays'])
          : null,
      interval: json['interval'],
      timeOfDay: timeOfDay,
      priority: priority,
      status: status,
      reminder: reminder,
    );
  }

  @override
  String get displayTitle => title;

  @override
  String get logType => 'task';
}

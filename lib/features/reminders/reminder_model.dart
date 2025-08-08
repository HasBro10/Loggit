import '../../models/log_entry.dart';

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

class Reminder implements LogEntry {
  final String title;
  final String? description;
  final DateTime reminderTime;
  final bool isCompleted;
  @override
  final DateTime timestamp;
  @override
  final String? category;
  // Advance timing field to store original timing like "30 minutes before"
  final String? advanceTiming;
  // Recurrence fields
  final RecurrenceType recurrenceType;
  final List<int>? customDays; // 1=Mon, 7=Sun
  final int? interval; // for every N days/weeks/months
  final DateTime? endDate;
  // Duration fields for limited repeats
  final int? repeatDuration; // Number of occurrences
  final String? repeatDurationType; // "days", "weeks", "months"
  // Snooze field
  final DateTime? snoozedUntil;

  Reminder({
    required this.title,
    this.description,
    required this.reminderTime,
    this.isCompleted = false,
    required this.timestamp,
    this.category,
    this.advanceTiming,
    this.recurrenceType = RecurrenceType.none,
    this.customDays,
    this.interval,
    this.endDate,
    this.repeatDuration,
    this.repeatDurationType,
    this.snoozedUntil,
  });

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? reminderTime,
    bool? isCompleted,
    DateTime? timestamp,
    String? category,
    String? advanceTiming,
    RecurrenceType? recurrenceType,
    List<int>? customDays,
    int? interval,
    DateTime? endDate,
    int? repeatDuration,
    String? repeatDurationType,
    DateTime? snoozedUntil,
  }) {
    return Reminder(
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      advanceTiming: advanceTiming ?? this.advanceTiming,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customDays: customDays ?? this.customDays,
      interval: interval ?? this.interval,
      endDate: endDate ?? this.endDate,
      repeatDuration: repeatDuration ?? this.repeatDuration,
      repeatDurationType: repeatDurationType ?? this.repeatDurationType,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'reminderTime': reminderTime.toIso8601String(),
      'isCompleted': isCompleted,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'advanceTiming': advanceTiming,
      'recurrenceType': recurrenceType.name,
      'customDays': customDays,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'repeatDuration': repeatDuration,
      'repeatDurationType': repeatDurationType,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    RecurrenceType recurrenceType = RecurrenceType.none;
    try {
      recurrenceType = RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrenceType'],
      );
    } catch (_) {}
    return Reminder(
      title: json['title'],
      description: json['description'],
      reminderTime: DateTime.parse(json['reminderTime']),
      isCompleted: json['isCompleted'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
      advanceTiming: json['advanceTiming'],
      recurrenceType: recurrenceType,
      customDays: json['customDays'] != null
          ? List<int>.from(json['customDays'])
          : null,
      interval: json['interval'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      repeatDuration: json['repeatDuration'],
      repeatDurationType: json['repeatDurationType'],
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'])
          : null,
    );
  }

  @override
  String get displayTitle => title;

  @override
  String get logType => 'reminder';
}

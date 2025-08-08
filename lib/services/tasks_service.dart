import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/tasks/task_model.dart';

class TasksService {
  static const String _tasksKey = 'tasks';

  // Load all tasks from storage
  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  // Save all tasks to storage
  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }

  // Filter tasks by date range
  static List<Task> filterTasksByDateRange(
    List<Task> tasks,
    DateTime start,
    DateTime end,
  ) {
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return !due.isBefore(start) && !due.isAfter(end);
    }).toList();
  }

  // Helper: get today, this week, next week, two weeks, this month, next month
  static List<Task> getTasksForPeriod(List<Task> tasks, String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (period == 'today' || period == 'daily') {
      return filterTasksByDateRange(tasks, today, today);
    } else if (period == 'this week') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(Duration(days: 6));
      return filterTasksByDateRange(tasks, start, end);
    } else if (period == 'next week') {
      final start = today
          .subtract(Duration(days: today.weekday - 1))
          .add(Duration(days: 7));
      final end = start.add(Duration(days: 6));
      return filterTasksByDateRange(tasks, start, end);
    } else if (period == 'two weeks') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(Duration(days: 13));
      return filterTasksByDateRange(tasks, start, end);
    } else if (period == 'this month') {
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 0);
      return filterTasksByDateRange(tasks, start, end);
    } else if (period == 'next month') {
      final start = DateTime(today.year, today.month + 1, 1);
      final end = DateTime(today.year, today.month + 2, 0);
      return filterTasksByDateRange(tasks, start, end);
    }
    return [];
  }

  // Generate recurring task instances based on duration
  static List<Task> generateRecurringTasks(Task baseTask) {
    if (baseTask.repeatDuration == null ||
        baseTask.repeatDurationType == null) {
      return [baseTask]; // No duration specified, return just the base task
    }

    final List<Task> tasks = [];
    final int duration = baseTask.repeatDuration!;
    final String durationType = baseTask.repeatDurationType!;
    final DateTime? startDate = baseTask.dueDate;

    if (startDate == null) {
      return [baseTask]; // No start date, return just the base task
    }

    for (int i = 0; i < duration; i++) {
      DateTime? nextDate;

      switch (baseTask.recurrenceType) {
        case RecurrenceType.daily:
          nextDate = startDate.add(Duration(days: i));
          break;
        case RecurrenceType.weekly:
          nextDate = startDate.add(Duration(days: i * 7));
          break;
        case RecurrenceType.monthly:
          nextDate = DateTime(
            startDate.year,
            startDate.month + i,
            startDate.day,
          );
          break;
        case RecurrenceType.custom:
          if (baseTask.customDays != null && baseTask.customDays!.isNotEmpty) {
            // For custom days, we need to calculate the next occurrence
            // This is a simplified version - you might want to enhance this
            nextDate = startDate.add(Duration(days: i * 7));
          } else {
            nextDate = startDate.add(Duration(days: i * 7));
          }
          break;
        default:
          nextDate = startDate;
      }

      // Create a new task instance for this occurrence
      final Task recurringTask = baseTask.copyWith(
        dueDate: nextDate,
        // Keep recurrence fields for the first instance (i=0), clear for others
        recurrenceType: i == 0 ? baseTask.recurrenceType : RecurrenceType.none,
        customDays: i == 0 ? baseTask.customDays : null,
        interval: i == 0 ? baseTask.interval : null,
        repeatEndDate: i == 0 ? baseTask.repeatEndDate : null,
        repeatDuration: i == 0 ? baseTask.repeatDuration : null,
        repeatDurationType: i == 0 ? baseTask.repeatDurationType : null,
      );

      tasks.add(recurringTask);
    }

    return tasks;
  }

  // Add a recurring task and generate all instances
  static Future<void> addRecurringTask(Task baseTask) async {
    final List<Task> allTasks = await loadTasks();
    final List<Task> recurringInstances = generateRecurringTasks(baseTask);

    // Add all generated instances
    allTasks.addAll(recurringInstances);

    // Save back to storage
    await saveTasks(allTasks);
  }
}

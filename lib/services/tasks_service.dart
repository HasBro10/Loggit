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
}

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../features/reminders/reminder_model.dart';

class RemindersService {
  static const String _remindersKey = 'user_reminders';

  // Load all reminders from storage
  static Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList(_remindersKey) ?? [];
    return remindersJson
        .map((reminderString) => Reminder.fromJson(json.decode(reminderString)))
        .toList();
  }

  // Save all reminders to storage
  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = reminders
        .map((r) => json.encode(r.toJson()))
        .toList();
    await prefs.setStringList(_remindersKey, remindersJson);
  }

  // Add a new reminder
  static Future<void> addReminder(Reminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  // Update an existing reminder (by timestamp)
  static Future<void> updateReminder(Reminder updated) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.timestamp == updated.timestamp);
    if (index != -1) {
      reminders[index] = updated;
      await saveReminders(reminders);
    }
  }

  // Delete a reminder (by timestamp)
  static Future<void> deleteReminder(Reminder toDelete) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.timestamp == toDelete.timestamp);
    await saveReminders(reminders);
  }

  // Delete multiple reminders
  static Future<void> deleteReminders(List<Reminder> toDelete) async {
    final reminders = await loadReminders();
    final timestamps = toDelete.map((r) => r.timestamp).toSet();
    reminders.removeWhere((r) => timestamps.contains(r.timestamp));
    await saveReminders(reminders);
  }
}

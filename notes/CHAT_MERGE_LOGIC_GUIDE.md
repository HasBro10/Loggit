# Chat Merge Logic Guide: Handling Partial Info and Parser Type Mismatches

## Context
When editing the log parser or chat screen logic for reminders and tasks, you may encounter scenarios where the parser returns a type (e.g., `LogType.reminder`) that does not match the user's current flow (e.g., a pending task). This is common when the user provides partial information (like a date or time) in multiple messages.

## Key Lessons
- **Always check the actual type of the pending/merged log entry (e.g., `Task` or `Reminder`), not just the parser’s type.**
- **Merging logic must be robust to parser type mismatches:**
  - If there is a pending task and the user provides a date-only input (even if the parser says it’s a reminder), merge the date into the pending task and continue the task flow.
- **Partial info flows (title, date, time) should always merge across messages, and the chat should only prompt for what’s missing.**
- **After merging, always generate confirmation messages based on the actual type of the log entry.**

## What to Do When You Face This Scenario
1. **Check for a pending log entry (e.g., a Task) before acting on the parser’s type.**
2. **If the user provides a date-only input and there is a pending Task, merge the date into the Task, even if the parser type is `reminder`.**
3. **After merging, use `is Task` or `is Reminder` to generate the correct confirmation message and UI, not the parser’s type.**
4. **Test all combinations of partial info (title, date, time) to ensure the chat merges and prompts correctly.**

## Example Fix (Dart/Pseudocode)
```dart
// After parsing user input:
if (_pendingLog is Task &&
    parsed.type == LogType.reminder &&
    parsed.dateTime != null &&
    !parsed.hasTime) {
  // Merge date into pending Task
  logEntry = Task(
    title: pending.title,
    dueDate: DateTime(parsed.dateTime!.year, parsed.dateTime!.month, parsed.dateTime!.day, pending.timeOfDay?.hour ?? 0, pending.timeOfDay?.minute ?? 0),
    timeOfDay: pending.timeOfDay,
    timestamp: DateTime.now(),
  );
  _pendingLog = null;
}
// ...
// When generating confirmation message:
if (logEntry is Task) {
  // Task confirmation logic
} else if (logEntry is Reminder) {
  // Reminder confirmation logic
}
```

## Summary
- **Be type-agnostic in merging logic.**
- **Be type-safe in confirmation logic.**
- **Always merge partial info and only prompt for what’s missing.**

_Keep this guide in mind to avoid repeated bugs and ensure a smooth chat-driven user experience._ 
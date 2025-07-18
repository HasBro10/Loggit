import 'package:flutter/material.dart';
import '../../models/log_entry.dart';
import '../tasks/task_model.dart' as tasks;
import '../reminders/reminder_model.dart' as reminders;

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isConfirmation;
  final Function(bool, [LogEntry?])? onConfirmationResponse;
  final LogEntry? pendingLogEntry;
  final bool canConfirm;
  final bool showEdit;
  final VoidCallback? onTap; // NEW
  final VoidCallback? onDelete; // NEW

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isConfirmation = false,
    this.onConfirmationResponse,
    this.pendingLogEntry,
    this.canConfirm = true,
    this.showEdit = false,
    this.onTap, // NEW
    this.onDelete, // NEW
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

    Widget bubbleContent;
    if (showEdit &&
        pendingLogEntry != null &&
        (pendingLogEntry is tasks.Task ||
            pendingLogEntry is reminders.Reminder)) {
      final isTask = pendingLogEntry is tasks.Task;
      final title = isTask
          ? (pendingLogEntry as tasks.Task).title
          : (pendingLogEntry as reminders.Reminder).title;
      final date = isTask
          ? (pendingLogEntry as tasks.Task).dueDate
          : (pendingLogEntry as reminders.Reminder).reminderTime;
      final time = isTask ? (pendingLogEntry as tasks.Task).timeOfDay : null;
      // Card-style layout for tasks/reminders (match reminders page)
      bubbleContent = Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.orange.withOpacity(0.55), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent icon
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.orange,
                    size: 26,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isTask ? 'Task' : 'Reminder',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(width: 16),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 15,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}'
                            : '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (time != null) ...[
                        SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 15,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4),
                        Text(
                          time.format(context),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12.0),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          minimumSize: const Size(80, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.10),
                        ),
                        onPressed: onTap,
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            minimumSize: const Size(80, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.10),
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Only show text if not a card
      bubbleContent = Column(
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
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Yes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF22C55E) // green
                        : const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.10),
                  ),
                  onPressed: canConfirm
                      ? () => onConfirmationResponse!(true, pendingLogEntry)
                      : null,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('No'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFEF4444) // red
                        : const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.10),
                  ),
                  onPressed: () => onConfirmationResponse!(false),
                ),
                if (showEdit) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.10),
                    ),
                    onPressed: () {
                      if (onConfirmationResponse != null) {
                        onConfirmationResponse!(false, null);
                      }
                    },
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.10),
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ],
            ),
          ],
          if (!isConfirmation && showEdit) ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.10),
                  ),
                  onPressed: onTap,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.10),
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }
}

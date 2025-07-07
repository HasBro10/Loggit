import '../../models/log_entry.dart';

class Note implements LogEntry {
  final String title;
  final String content;
  @override
  final DateTime timestamp;
  @override
  final String? category;

  Note({
    required this.title,
    required this.content,
    required this.timestamp,
    this.category,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? timestamp,
    String? category,
  }) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
    );
  }

  @override
  String get displayTitle => title;

  @override
  String get logType => 'note';
}

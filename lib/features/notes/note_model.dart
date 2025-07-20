import '../../models/log_entry.dart';
import 'package:flutter/material.dart';

enum NoteType { text, checklist, media, quick, linked }

enum NoteStatus { draft, final_, archived }

enum NotePriority { low, medium, high }

class NoteItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<NoteItem>? subItems;

  NoteItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.completedAt,
    this.subItems,
  });

  NoteItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? completedAt,
    List<NoteItem>? subItems,
  }) {
    return NoteItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      subItems: subItems ?? this.subItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'subItems': subItems?.map((item) => item.toJson()).toList(),
    };
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'],
      text: json['text'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      subItems: json['subItems'] != null
          ? (json['subItems'] as List)
                .map((item) => NoteItem.fromJson(item))
                .toList()
          : null,
    );
  }
}

class Note implements LogEntry {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final String noteCategory;
  final List<String> tags;
  final Color color;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<NoteItem>? checklistItems;
  final List<String>? mediaUrls;
  final List<String>? linkedNoteIds;
  final List<String>? relatedTaskIds;
  final List<String>? relatedReminderIds;
  final NoteStatus status;
  final NotePriority priority;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.type = NoteType.text,
    this.noteCategory = 'Personal',
    this.tags = const [],
    this.color = const Color(0xFF2563eb), // Default blue
    DateTime? createdAt,
    this.updatedAt,
    this.checklistItems,
    this.mediaUrls,
    this.linkedNoteIds,
    this.relatedTaskIds,
    this.relatedReminderIds,
    this.status = NoteStatus.final_,
    this.priority = NotePriority.medium,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  DateTime get timestamp => createdAt;

  @override
  String? get category => noteCategory;

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    String? noteCategory,
    List<String>? tags,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<NoteItem>? checklistItems,
    List<String>? mediaUrls,
    List<String>? linkedNoteIds,
    List<String>? relatedTaskIds,
    List<String>? relatedReminderIds,
    NoteStatus? status,
    NotePriority? priority,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      noteCategory: noteCategory ?? this.noteCategory,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checklistItems: checklistItems ?? this.checklistItems,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      relatedTaskIds: relatedTaskIds ?? this.relatedTaskIds,
      relatedReminderIds: relatedReminderIds ?? this.relatedReminderIds,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'category': category,
      'tags': tags,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'checklistItems': checklistItems?.map((item) => item.toJson()).toList(),
      'mediaUrls': mediaUrls,
      'linkedNoteIds': linkedNoteIds,
      'relatedTaskIds': relatedTaskIds,
      'relatedReminderIds': relatedReminderIds,
      'status': status.name,
      'priority': priority.name,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: NoteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NoteType.text,
      ),
      noteCategory: json['category'] ?? 'Personal',
      tags: List<String>.from(json['tags'] ?? []),
      color: Color(json['color'] ?? 0xFF2563eb),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      checklistItems: json['checklistItems'] != null
          ? (json['checklistItems'] as List)
                .map((item) => NoteItem.fromJson(item))
                .toList()
          : null,
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'])
          : null,
      linkedNoteIds: json['linkedNoteIds'] != null
          ? List<String>.from(json['linkedNoteIds'])
          : null,
      relatedTaskIds: json['relatedTaskIds'] != null
          ? List<String>.from(json['relatedTaskIds'])
          : null,
      relatedReminderIds: json['relatedReminderIds'] != null
          ? List<String>.from(json['relatedReminderIds'])
          : null,
      status: NoteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NoteStatus.final_,
      ),
      priority: NotePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotePriority.medium,
      ),
    );
  }

  @override
  String get displayTitle => title;

  @override
  String get logType => 'note';

  // Helper methods
  bool get isChecklist => type == NoteType.checklist;
  bool get isMedia => type == NoteType.media;
  bool get isQuick => type == NoteType.quick;
  bool get isLinked => type == NoteType.linked;

  int get completedChecklistItems {
    if (!isChecklist || checklistItems == null) return 0;
    return checklistItems!.where((item) => item.isCompleted).length;
  }

  int get totalChecklistItems {
    if (!isChecklist || checklistItems == null) return 0;
    return checklistItems!.length;
  }

  double get checklistProgress {
    if (totalChecklistItems == 0) return 0.0;
    return completedChecklistItems / totalChecklistItems;
  }

  String get formattedCreatedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (noteDate == today) {
      return 'Today';
    } else if (noteDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';

enum FeatureType { chat, expenses, tasks, reminders, notes, gymLogs }

class FavoriteFeature {
  final FeatureType type;
  final String title;
  final IconData icon;
  final int order;

  const FavoriteFeature({
    required this.type,
    required this.title,
    required this.icon,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'title': title, 'order': order};
  }

  factory FavoriteFeature.fromJson(Map<String, dynamic> json) {
    final type = FeatureType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => FeatureType.chat,
    );

    return FavoriteFeature(
      type: type,
      title: json['title'] ?? _getDefaultTitle(type),
      icon: _getDefaultIcon(type),
      order: json['order'] ?? 0,
    );
  }

  static String _getDefaultTitle(FeatureType type) {
    switch (type) {
      case FeatureType.chat:
        return 'Chat';
      case FeatureType.expenses:
        return 'Expenses';
      case FeatureType.tasks:
        return 'Tasks';
      case FeatureType.reminders:
        return 'Reminders';
      case FeatureType.notes:
        return 'Notes';
      case FeatureType.gymLogs:
        return 'Workouts';
    }
  }

  static IconData _getDefaultIcon(FeatureType type) {
    switch (type) {
      case FeatureType.chat:
        return Icons.chat_bubble_outline;
      case FeatureType.expenses:
        return Icons.bar_chart;
      case FeatureType.tasks:
        return Icons.task_alt;
      case FeatureType.reminders:
        return Icons.alarm;
      case FeatureType.notes:
        return Icons.note;
      case FeatureType.gymLogs:
        return Icons.fitness_center;
    }
  }

  static List<FavoriteFeature> get defaultFavorites => [
    const FavoriteFeature(
      type: FeatureType.chat,
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      order: 0,
    ),
    const FavoriteFeature(
      type: FeatureType.expenses,
      title: 'Expenses',
      icon: Icons.bar_chart,
      order: 1,
    ),
    const FavoriteFeature(
      type: FeatureType.tasks,
      title: 'Tasks',
      icon: Icons.task_alt,
      order: 2,
    ),
    const FavoriteFeature(
      type: FeatureType.reminders,
      title: 'Reminders',
      icon: Icons.alarm,
      order: 3,
    ),
    const FavoriteFeature(
      type: FeatureType.notes,
      title: 'Notes',
      icon: Icons.note,
      order: 4,
    ),
  ];

  static List<FavoriteFeature> get allAvailableFeatures => [
    const FavoriteFeature(
      type: FeatureType.chat,
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      order: 0,
    ),
    const FavoriteFeature(
      type: FeatureType.expenses,
      title: 'Expenses',
      icon: Icons.bar_chart,
      order: 1,
    ),
    const FavoriteFeature(
      type: FeatureType.tasks,
      title: 'Tasks',
      icon: Icons.task_alt,
      order: 2,
    ),
    const FavoriteFeature(
      type: FeatureType.reminders,
      title: 'Reminders',
      icon: Icons.alarm,
      order: 3,
    ),
    const FavoriteFeature(
      type: FeatureType.notes,
      title: 'Notes',
      icon: Icons.note,
      order: 4,
    ),
    const FavoriteFeature(
      type: FeatureType.gymLogs,
      title: 'Workouts',
      icon: Icons.fitness_center,
      order: 5,
    ),
  ];
}

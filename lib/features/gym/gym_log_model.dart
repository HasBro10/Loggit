import '../../models/log_entry.dart';

class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double? weight; // in kg
  final String? notes;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight']?.toDouble(),
      notes: json['notes'],
    );
  }
}

class GymLog implements LogEntry {
  final String workoutName;
  final List<Exercise> exercises;
  @override
  final DateTime timestamp;
  final String? notes;
  @override
  final String? category;

  GymLog({
    required this.workoutName,
    required this.exercises,
    required this.timestamp,
    this.notes,
    this.category,
  });

  GymLog copyWith({
    String? workoutName,
    List<Exercise>? exercises,
    DateTime? timestamp,
    String? notes,
    String? category,
  }) {
    return GymLog(
      workoutName: workoutName ?? this.workoutName,
      exercises: exercises ?? this.exercises,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'workoutName': workoutName,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'category': category,
    };
  }

  factory GymLog.fromJson(Map<String, dynamic> json) {
    return GymLog(
      workoutName: json['workoutName'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      category: json['category'],
    );
  }

  @override
  String get displayTitle => workoutName;

  @override
  String get logType => 'gym';
}

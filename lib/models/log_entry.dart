abstract class LogEntry {
  DateTime get timestamp;
  String? get category;

  Map<String, dynamic> toJson();

  String get displayTitle;
  String get logType;
}

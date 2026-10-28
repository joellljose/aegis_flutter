enum LogType { info, warn, danger, success }

class LogEntry {
  final String id;
  final String time;
  final int timestamp;
  final LogType type;
  final String message;

  LogEntry({
    required this.id,
    required this.time,
    required this.timestamp,
    required this.type,
    required this.message,
  });
}

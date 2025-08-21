import 'dart:convert';

class MoodleNotification {
  final int id;
  final String subject;
  final String message;
  final DateTime timeCreated;
  final bool isRead;
  final String? contextUrl;
  final String component;
  final String eventType;
  final String? courseCode;
  final String? dueDate;

  MoodleNotification({
    required this.id,
    required this.subject,
    required this.message,
    required this.timeCreated,
    required this.isRead,
    this.contextUrl,
    required this.component,
    required this.eventType,
    this.courseCode,
    this.dueDate,
  });

  factory MoodleNotification.fromMap(Map<String, dynamic> map) {
    return MoodleNotification(
      id: map['id'] ?? 0,
      subject: map['subject']?.toString() ?? 'No Subject',
      message: map['message']?.toString() ?? '',
      timeCreated: DateTime.fromMillisecondsSinceEpoch(
          ((map['time_created'] ?? 0) * 1000).toInt()),
      isRead: map['is_read'] ?? false,
      contextUrl: map['context_url']?.toString(),
      component: map['component']?.toString() ?? 'unknown',
      eventType: map['event_type']?.toString() ?? 'unknown',
      courseCode: _extractCourseCode(map['subject'], map['message']),
      dueDate: _extractDueDate(map['message']),
    );
  }

  static String? _extractCourseCode(dynamic subject, dynamic message) {
    final subjectStr = subject?.toString() ?? '';
    final messageStr = message?.toString() ?? '';
    final text = '$subjectStr $messageStr';

    final patterns = [
      RegExp(r'([A-Z]{3,4}\d{4}[A-Z]?-[A-Z]{2}-SM\d-\d{4})'),
      RegExp(r'([A-Z]{3,4}\d{4}[A-Z]?-[A-Z]{2}-\d{4})'),
      RegExp(r'([A-Z]{2,4}\d?-\w{3,4}-\d{4})'),
      RegExp(r'([A-Z]{3,4}\d{4}[A-Z]?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? _extractDueDate(dynamic message) {
    final messageStr = message?.toString() ?? '';

    final patterns = [
      RegExp(r'due on.*?(\d{1,2}\s+\w+\s+\d{4}.*?\d{1,2}:\d{2}\s*[AP]M)', caseSensitive: false),
      RegExp(r'due.*?(\d{1,2}\s+\w+\s+\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2}\s+\w+\s+\d{4}.*?\d{1,2}:\d{2}\s*[AP]M)', caseSensitive: false),
      RegExp(r'(\w+day, \d{1,2} \w+ \d{4}, \d{1,2}:\d{2} [AP]M)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(messageStr);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'message': message,
      'time_created': timeCreated.millisecondsSinceEpoch ~/ 1000,
      'is_read': isRead,
      'context_url': contextUrl,
      'component': component,
      'event_type': eventType,
      'course_code': courseCode,
      'due_date': dueDate,
    };
  }

  String toJson() => json.encode(toMap());

  factory MoodleNotification.fromJson(String source) =>
      MoodleNotification.fromMap(json.decode(source));

  MoodleNotification copyWith({
    int? id,
    String? subject,
    String? message,
    DateTime? timeCreated,
    bool? isRead,
    String? contextUrl,
    String? component,
    String? eventType,
    String? courseCode,
    String? dueDate,
  }) {
    return MoodleNotification(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      timeCreated: timeCreated ?? this.timeCreated,
      isRead: isRead ?? this.isRead,
      contextUrl: contextUrl ?? this.contextUrl,
      component: component ?? this.component,
      eventType: eventType ?? this.eventType,
      courseCode: courseCode ?? this.courseCode,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  String toString() {
    return 'MoodleNotification(id: $id, subject: $subject, isRead: $isRead, courseCode: $courseCode, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodleNotification &&
        other.id == id &&
        other.subject == subject &&
        other.message == message &&
        other.timeCreated == timeCreated &&
        other.isRead == isRead &&
        other.contextUrl == contextUrl &&
        other.component == component &&
        other.eventType == eventType &&
        other.courseCode == courseCode &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    subject.hashCode ^
    message.hashCode ^
    timeCreated.hashCode ^
    isRead.hashCode ^
    contextUrl.hashCode ^
    component.hashCode ^
    eventType.hashCode ^
    courseCode.hashCode ^
    dueDate.hashCode;
  }
}
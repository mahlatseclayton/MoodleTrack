import 'moodle_notification.dart';

class NotificationResponse {
  final bool success;
  final int studentId;
  final List<MoodleNotification> notifications;
  final int count;
  final int totalCount;
  final String? error;

  NotificationResponse({
    required this.success,
    required this.studentId,
    required this.notifications,
    required this.count,
    required this.totalCount,
    this.error,
  });

  factory NotificationResponse.fromMap(Map<String, dynamic> map) {
    return NotificationResponse(
      success: map['success'] ?? false,
      studentId: map['student_id'] ?? 0,
      notifications: (map['notifications'] as List<dynamic>?)
          ?.map((note) => MoodleNotification.fromMap(note))
          .toList() ?? [],
      count: map['count'] ?? 0,
      totalCount: map['total_count'] ?? 0,
      error: map['error'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'student_id': studentId,
      'notifications': notifications.map((note) => note.toMap()).toList(),
      'count': count,
      'total_count': totalCount,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'NotificationResponse(success: $success, studentId: $studentId, count: $count, totalCount: $totalCount, error: $error)';
  }
}
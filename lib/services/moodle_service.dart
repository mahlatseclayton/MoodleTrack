import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learning_app/services/token_service.dart';
import '../models/notification_response.dart';
import '../models/moodle_notification.dart';

class MoodleService {
  static const String _baseUrl = 'https://courses.ms.wits.ac.za/moodle';
  static const String _tokenUrl = '$_baseUrl/login/token.php';
  static const String _apiUrl = '$_baseUrl/webservice/rest/server.php';



  static Future<int?> _getUserId(String token) async {
    try {
      final uri = Uri.parse('$_apiUrl?wstoken=$token&wsfunction=core_webservice_get_site_info&moodlewsrestformat=json');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['userid'] as int?;
      }
      return null;
    } catch (e) {
      print('User ID error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> _getNotifications(String token, int userId, {int limit = 50}) async {
    try {
      final uri = Uri.parse('$_apiUrl?wstoken=$token&wsfunction=message_popup_get_popup_notifications&moodlewsrestformat=json&useridto=$userId&limit=$limit');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['notifications'] ?? [];
      }
      return [];
    } catch (e) {
      print('Notifications error: $e');
      return [];
    }
  }

  static Future<NotificationResponse> getDueDateNotifications(
       {int limit = 50}) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        return NotificationResponse(
          success: false,
          studentId: 0,
          notifications: [],
          count: 0,
          totalCount: 0,
          error: 'Invalid credentials - cannot get token',
        );
      }

      final userId = await _getUserId(token);
      if (userId == null) {
        return NotificationResponse(
          success: false,
          studentId: 0,
          notifications: [],
          count: 0,
          totalCount: 0,
          error: 'Failed to get user information',
        );
      }

      final allNotifications = await _getNotifications(token, userId, limit: limit);
      final dueDateNotifications = _filterAndConvertNotifications(allNotifications);

      return NotificationResponse(
        success: true,
        studentId: userId,
        notifications: dueDateNotifications,
        count: dueDateNotifications.length,
        totalCount: allNotifications.length,
      );
    } catch (e) {
      return NotificationResponse(
        success: false,
        studentId: 0,
        notifications: [],
        count: 0,
        totalCount: 0,
        error: 'Unexpected error: $e',
      );
    }
  }

  static List<MoodleNotification> _filterAndConvertNotifications(List<dynamic> rawNotifications) {
    final List<MoodleNotification> dueDateNotes = [];

    for (final note in rawNotifications) {
      final subject = (note['subject'] ?? '').toString().toLowerCase();
      final message = (note['fullmessage'] ?? '').toString().toLowerCase();

      if (_isSubmissionConfirmation(subject, message)) {
        continue;
      }

      if (_isDueDateNotification(subject, message)) {
        dueDateNotes.add(MoodleNotification.fromMap({
          'id': note['id'],
          'subject': note['subject'],
          'message': note['fullmessage'],
          'time_created': note['timecreated'],
          'is_read': note['read'] ?? false,
          'context_url': note['contexturl'],
          'component': note['component'],
          'event_type': note['eventtype'],
        }));
      }
    }

    return dueDateNotes;
  }

  static bool _isSubmissionConfirmation(String subject, String message) {
    final submissionKeywords = ['submitted', 'submission receipt', 'you have submitted'];
    return submissionKeywords.any((keyword) => subject.contains(keyword) || message.contains(keyword));
  }

  static bool _isDueDateNotification(String subject, String message) {
    final dueKeywords = ['due', 'overdue', 'deadline', 'quiz','upload','tutorial','project', 'test', 'exam', 'assignment', 'reminder','lab'];
    return dueKeywords.any((keyword) => subject.contains(keyword) || message.contains(keyword));
  }
}
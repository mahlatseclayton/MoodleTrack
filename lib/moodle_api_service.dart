// moodle_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'moodle_event.dart';

class MoodleApiService {
  final String token;
  final String domain;

  MoodleApiService({required this.token, required this.domain});

  Future<List<MoodleEvent>> fetchUpcomingEvents({int limit = 50}) async {
    try {
      final response = await http.post(
        Uri.parse('$domain/webservice/rest/server.php'),
        body: {
          'wstoken': token,
          'wsfunction': 'core_calendar_get_action_events_by_timesort',
          'moodlewsrestformat': 'json',
          'timesortfrom': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
          'limitnum': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['events'] != null) {
          return (data['events'] as List)
              .map((event) => MoodleEvent.fromJson(event))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching Moodle events: $e');
      rethrow; // Changed from return [] to rethrow so error can be caught by provider
    }
  }
}
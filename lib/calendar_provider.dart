// calendar_provider.dart
import 'package:flutter/material.dart';
import 'moodle_api_service.dart';
import 'moodle_event.dart'; // Remove: hide MoodleEvent

class CalendarProvider with ChangeNotifier {
  final MoodleApiService _moodleService;
  List<MoodleEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  CalendarProvider({required MoodleApiService moodleService})
      : _moodleService = moodleService;

  List<MoodleEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _moodleService.fetchUpcomingEvents();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MoodleEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return _isSameDay(event.startTime, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moodle_api_service.dart';
import 'moodle_event.dart';

class CalendarProvider with ChangeNotifier {
  final MoodleApiService _moodleService;
  List<MoodleEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false; // Prevent multiple loads

  CalendarProvider({required MoodleApiService moodleService})
      : _moodleService = moodleService;

  List<MoodleEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvents() async {
    if (_hasLoaded && _events.isNotEmpty) {

      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {


      final moodleEvents = await _moodleService.fetchUpcomingEvents();


      // --- 2. Get Firestore events only for current Firebase user ---
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {

        throw Exception("User not logged in");
      }


      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: uid) // Ensure userId field matches this
          .get();



      final firestoreEvents = snapshot.docs.map((doc) {
        final data = doc.data();



        // Handle date field
        DateTime eventDate;
        if (data['date'] is Timestamp) {
          eventDate = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is DateTime) {
          eventDate = data['date'] as DateTime;
        } else if (data['date'] is String) {
          eventDate = DateTime.parse(data['date']);
        } else {
          throw Exception("Invalid date format in Firestore: ${data['date']}");
        }

        // Parse time strings
        final startTimeStr = data['startTime'] as String? ?? '00:00';
        final endTimeStr = data['endTime'] as String? ?? '23:59';

        final startParts = startTimeStr.split(":");
        final endParts = endTimeStr.split(":");

        if (startParts.length != 2 || endParts.length != 2) {
          throw Exception("Invalid time format");
        }

        final startTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );

        final endTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        return MoodleEvent(
          id: doc.id.hashCode,
          name: data['eventName'] as String? ?? 'Untitled Event',
          description: data['description'] as String? ?? '',
          activityName: 'Planner Event',
          eventType: 'planner',
          startTime: startTime,
          sortTime: endTime,
          isOverdue: endTime.isBefore(DateTime.now()),
          component: 'planner',
          moduleName: 'planner',
        );
      }).toList();

      // --- 3. Merge both lists and sort ---
      _events = [...moodleEvents, ...firestoreEvents];
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));


      _hasLoaded = true;
    } catch (error) {
      _errorMessage = error.toString();

      _hasLoaded = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MoodleEvent> getEventsForDay(DateTime day) {
    final dayEvents = _events.where((event) {
      return _isSameDay(event.startTime, day);
    }).toList();


    return dayEvents;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void clearEvents() {
    _events.clear();
    _hasLoaded = false;
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    _hasLoaded = false;
    await loadEvents();
  }
}

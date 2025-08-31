// moodle_event.dart
import 'package:flutter/material.dart';

class MoodleEvent {
  final int id;
  final String name;
  final String description;
  final String activityName;
  final String eventType;
  final DateTime startTime;
  final DateTime sortTime;
  final bool isOverdue;
  final String component;
  final String moduleName;

  MoodleEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.activityName,
    required this.eventType,
    required this.startTime,
    required this.sortTime,
    required this.isOverdue,
    required this.component,
    required this.moduleName,
  });

  factory MoodleEvent.fromJson(Map<String, dynamic> json) {
    return MoodleEvent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      activityName: json['activityname'] ?? '',
      eventType: json['eventtype'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch((json['timestart'] ?? 0) * 1000),
      sortTime: DateTime.fromMillisecondsSinceEpoch((json['timesort'] ?? 0) * 1000),
      isOverdue: json['overdue'] ?? false,
      component: json['component'] ?? '',
      moduleName: json['modulename'] ?? '',
    );
  }

  // Public getters
  String get cleanDescription {
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Color get eventColor {
    switch (eventType) {
      case 'due':
        return Colors.red;
      case 'course':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
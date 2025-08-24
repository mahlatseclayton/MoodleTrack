import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushService {
  static Future<void> notifyOtherUsers(
      {required String postTitle,
        required String authorId,
        required String authorName}) async {
    // Get all other users' FCM tokens
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: authorId)
        .get();

    List<String> tokens = [];
    for (var doc in snapshot.docs) {
      if (doc['fcmToken'] != null) tokens.add(doc['fcmToken']);
    }

    if (tokens.isEmpty) return;

    // Send push using FCM HTTP
    final serverKey =
        'YOUR_FIREBASE_SERVER_KEY_HERE'; // from Firebase Console > Project Settings > Cloud Messaging
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final body = {
      "registration_ids": tokens,
      "notification": {
        "title": "New Post",
        "body": "$authorName posted: $postTitle",
      },
      "data": {"screen": "notifications"},
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(body),
    );

    print('FCM response: ${response.body}');
  }
}

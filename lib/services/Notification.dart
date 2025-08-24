import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once on app start or after login
  Future<void> initNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Request permissions (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Save token to Firestore for Cloud Function notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      print("FCM token saved for user ${user.uid}: $token");
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final snackBar = SnackBar(
          content: Text(message.notification!.title ?? "New message"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    // Background / tapped from tray
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.pushNamed(context, "/notifications");
    });

    // App terminated, opened via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Navigator.pushNamed(context, "/notifications");
      }
    });
  }
}

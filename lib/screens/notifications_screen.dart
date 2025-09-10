import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../AppData.dart';
import '../services/moodle_service.dart';
import '../models/notification_response.dart';
import '../models/moodle_notification.dart';
import '../services/token_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  NotificationResponse? _response;
  bool _isLoading = false;
  String _statusMessage = 'Loading notifications';
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {


    setState(() {
      _isLoading = true;
      _response = null;
      _statusMessage = 'Connecting to Moodle...';
    });

    final response = await MoodleService.getDueDateNotifications();

    setState(() {
      _isLoading = false;
      _response = response;

      if (response.success) {
        _statusMessage = 'Found ${response.count} due date notifications';
        AppData().displayNumber = response.count;
      } else {
        _statusMessage = 'Error: ${response.error}';
      }
    });
  }
  Future<void> _launchUrl(String? url) async {
    if (url == null) return;

    print('Original URL: $url'); // Debugging

    final uri = Uri.parse(url);

    // Check if this is a Moodle URL that needs authentication
    if (uri.host.contains('courses.ms.wits.ac.za')) {
      await _launchMoodleUrl(url);
    } else {
      // For external URLs, launch normally - KEEP THIS METHOD
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  Future<void> _launchMoodleUrl(String url) async {
    final token = await TokenService.getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Check if the URL already has query parameters
    final hasQuery = url.contains('?');

    // Construct the authenticated URL
    final authenticatedUrl = '$url${hasQuery ? '&' : '?'}wstoken=$token';

    print('Authenticated URL: $authenticatedUrl'); // Debugging

    final authenticatedUri = Uri.parse(authenticatedUrl);

    if (await canLaunchUrl(authenticatedUri)) {
      await launchUrl(authenticatedUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Moodle URL')),
      );
    }
  }

  Widget _buildNotificationCard(MoodleNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead ? Colors.green : Colors.blue,
          child: Icon(
            notification.isRead ? Icons.check : Icons.notifications,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.subject,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: notification.isRead ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.courseCode != null)
              Text(
                'Course: ${notification.courseCode}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            if (notification.dueDate != null)
              Text(
                'Due: ${notification.dueDate}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              '${notification.component} • ${notification.eventType}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              _formatDate(notification.timeCreated),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 20),
          onPressed: () => _launchUrl(notification.contextUrl),
        ),
        onTap: () => _launchUrl(notification.contextUrl),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _response?.success == true ? Colors.green : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [

          _buildStatusIndicator(),
          const SizedBox(height: 16),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching notifications...'),
                  ],
                ),
              ),
            )
          else if (_response?.success == true)
            Expanded(
              child: _response!.notifications.isEmpty
                  ? const Center(
                child: Text(
                  'No due date notifications found!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _response!.notifications.length,
                itemBuilder: (context, index) {
                  final notification = _response!.notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
        ],
      ),
    );
  }


}
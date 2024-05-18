import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  static const String route = '/notification'; // Define a static route

  final RemoteMessage message;

  // Constructor with named parameter 'message'
  const NotificationScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // No need to retrieve 'message' again here
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${message.notification?.title}"),
            Text("${message.notification?.body}"),
            Text("${message.data}"),
          ],
        ),
      ),
    );
  }
}
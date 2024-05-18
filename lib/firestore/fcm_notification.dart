import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/notifications.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("Handling background message:");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
}

class MyMessagingService {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> _navigatorKey;
  FirebaseAuth _auth = FirebaseAuth.instance;


  MyMessagingService(this._navigatorKey);

  Future<void> handleMessage(RemoteMessage message) async {
    if (message == null) return;

    if (message.data['type'] == 'circles') {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => NotificationScreen(message: message),
        ),
      );
    }

  }

  Future<void> initPushNotification() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await handleMessage(message);
    });
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  Future<void> setupMessaging() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    User? currentUser = _auth.currentUser;
    await firebaseFirestore.collection('users').doc(currentUser?.uid).update({
      'fcmToken': fcmToken,
    });
    print("Token: $fcmToken");
    initPushNotification();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }
}

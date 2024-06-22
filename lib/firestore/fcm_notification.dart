import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/main.dart';

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
    print('handle message clicked');
    final route = message.data['route'];
    final circleName = message.data['circleName']; // Assuming circleName is passed in the data

    if (route == '/circles') {
      navigatorKey.currentState?.pushNamed('/circles');
    } else if (route == '/circleDetails' && circleName != null) {
      navigatorKey.currentState?.pushNamed('/circleDetails/$circleName');
    }
    print(message.data);
  }

  Future<void> initPushNotification() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final RemoteMessage? initMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initMessage != null) {
      handleMessage(initMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen((handleMessage));
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

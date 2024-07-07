import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/circlesdetails.dart';
import 'package:fypppp/firebase_options.dart';
import 'package:fypppp/firestore/fcm_notification.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/preview_case.dart';
import 'package:fypppp/sos.dart';
import 'package:fypppp/startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await MyMessagingService(navigatorKey).setupMessaging();
    print("Firebase initialized successfully");
  } catch (e) {
    // Handle Firebase initialization error
    print("Error initializing Firebase: $e");
  }


  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waspada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      routes: {
        '/circles': (context) => Circles(),
        '/panicvideo': (context) => SOSPage(),
        '/panicaudio': (context) => SOSAudioPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/circleDetails/') ?? false) {
          final circleName = settings.name!.replaceFirst('/circleDetails/', '');
          return MaterialPageRoute(
            builder: (context) => CircleDetailsPage(circleName),
          );
        } else if (settings.name?.startsWith('/casePreview/') ?? false) {
          final documentId = settings.name!.replaceFirst('/casePreview/', '');
          return MaterialPageRoute(
            builder: (context) => CasePreview(documentId: documentId),
          );
        }
        return null;
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is authenticated, show the home page
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const StartUpScreen();
          } else {
            return const Home();
          }
        }
        // Otherwise, show a loading indicator
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
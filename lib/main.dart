import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/circlesdetails.dart';
import 'package:fypppp/firebase_options.dart';
import 'package:fypppp/firestore/fcm_notification.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/sos.dart';
import 'package:fypppp/startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.blue,
    ),
  ); // Change navigation bar color here
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

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        }
        return null;
      },
        home: FutureBuilder<bool>(
          future: _isLoggedIn,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Still waiting for authentication state to be determined
              return Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              );
            } else {
              // Authentication state has been determined
              if (snapshot.data == true) {
                // If logged in, navigate to the Home screen
                return Home();
              }
              // If not logged in, stay on the Splash screen
              return StartUpScreen();
            }
          },
        ),
      );
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idToken = prefs.getString('refreshToken');
    print("$idToken");
    // Check if user is logged in based on cached authentication state
    if (idToken != null) {
      // Verify the ID token using Firebase Authentication
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        print("LOGGEDIN ");
        return true; // ID token is valid, user is logged in
      } catch (e) {
        print("Error verifying ID token: $e");
        return false; // ID token is invalid or verification failed, user is not logged in
      }
    } else {
      print("no token");
      return false; // ID token is not available, user is not logged in
    }
  }

}
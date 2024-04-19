import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace 'your_logo.png' with the path to your app logo
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Your app logo
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/appicon.png', // Replace 'your_logo.png' with your image asset
                width: 200, // Adjust width as needed
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10), // Adjust padding as needed
            child: Center(
              // Text indicating developer information
              child: Text(
                'developed by darthkims',
                style: TextStyle(
                  fontSize: 16, // Adjust font size as needed
                  fontWeight: FontWeight.bold, // Adjust font weight as needed
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

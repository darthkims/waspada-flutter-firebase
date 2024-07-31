import 'package:flutter/material.dart';
import 'package:fypppp/login.dart';
import 'package:fypppp/signup.dart';

class StartUpScreen extends StatelessWidget {
  const StartUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F2),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/wallpaper_native.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/appicon_red_rounded.png',
                width: 80,
              ),
              const SizedBox(height: 10,),
              Image.asset(
                'assets/images/waspada_word_logo.png',
                width: 500,
              ),
              const SizedBox(height: 100,),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Color(0xfffa675a)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)), // Adjust the width here
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const LoginForm())
                    );
                  },
                  child: const Text("Existing User", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
              ),
              const SizedBox(height: 20,),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Color(0xfffa675a)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)), // Adjust the width here
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const SignUpForm())
                    );
                  },
                  child: const Text("New User", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2))),
            ],
          ),
        ),
      ),
    );
  }
}

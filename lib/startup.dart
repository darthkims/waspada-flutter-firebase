import 'package:flutter/material.dart';
import 'package:fypppp/login.dart';
import 'package:fypppp/signup.dart';

class StartUpScreen extends StatelessWidget {
  const StartUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF66EEEE),
      body: Container(
        margin: EdgeInsets.all(30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 500,
              ),
              SizedBox(height: 100,),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)), // Adjust the width here
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => LoginForm())
                    );
                  },
                  child: Text("Existing User", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)), // Adjust the width here
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => SignUpForm())
                    );
                  },
                  child: Text("New User", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2))),
            ],
          ),
        ),
      ),
    );
  }
}

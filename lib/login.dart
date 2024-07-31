import 'package:flutter/material.dart';
import 'package:fypppp/firestore/authentication.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final FocusNode emailFocus = FocusNode();
    final FocusNode passwordFocus = FocusNode();

    void emailSubmitted(String value) {
      FocusScope.of(context).requestFocus(passwordFocus);
    }

    final AuthenticationHelper authHelper = AuthenticationHelper();

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F2),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/waspada_word_logo.png',
                  width: 500,
                  height: 200,
                ),
                TextFormField(
                  controller: emailController,
                  focusNode: emailFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: emailSubmitted,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.black),
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        borderSide: BorderSide(color: Colors.transparent)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                TextFormField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        borderSide: BorderSide(color: Colors.transparent)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30,),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () async {

                      // Check if email is empty or not valid
                      if (emailController.text.isEmpty ){
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid email")),
                        );
                        return; // Stop further execution
                      }

                      // Check if password is empty
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a password")),
                        );
                        return; // Stop further execution
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text("Logging In..."),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      String? signInResult = await authHelper.signIn(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      if (signInResult == null) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        Future<String?> tokenFuture = authHelper.getIdToken();
                        String? token = await tokenFuture;
                        if (token != null) {
                          prefs.setString('refreshToken', token);
                          print("ID Token: $token");
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const Home()),
                              (Route<dynamic> route) => false,
                        );
                      } else {
                        Navigator.pop(context);
                        // Display sign-up error to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(signInResult)),
                        );
                      }
                    },
                    child: const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
                ),
                const SizedBox(height: 30,),
                const Divider(),
                const SizedBox(height: 30,),
                const Text("Are you new here? Join the community!", style: TextStyle(color: Color(0xff671107)),),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignUpForm())
                      );
                    },
                    child: const Text("New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

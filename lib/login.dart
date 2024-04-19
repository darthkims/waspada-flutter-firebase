import 'package:flutter/material.dart';
import 'package:fypppp/firestore/authentication.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({Key? key});

  @override
  Widget build(BuildContext context) {
    final FocusNode _emailFocus = FocusNode();
    final FocusNode _passwordFocus = FocusNode();

    void _emailSubmitted(String value) {
      FocusScope.of(context).requestFocus(_passwordFocus);
    }

    final AuthenticationHelper _authHelper = AuthenticationHelper();

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Color(0xFF66EEEE),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 500,
                  height: 200,
                ),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: _emailSubmitted,
                  decoration: InputDecoration(
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
                SizedBox(height: 20,),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  decoration: InputDecoration(
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
                SizedBox(height: 30,),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      String? signInResult = await _authHelper.signIn(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );

                      if (signInResult == null) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        Future<String?> tokenFuture = _authHelper.getIdToken();
                        String? token = await tokenFuture;
                        if (token != null) {
                          prefs.setString('refreshToken', token);
                          print("ID Token: $token");
                        }
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Home())
                        );
                      } else {
                        // Display sign-up error to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(signInResult)),
                        );
                      }
                    },
                    child: Text("Login", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
                ),
                SizedBox(height: 30,),
                Divider(color: Color(0xFF6798F8),),
                SizedBox(height: 30,),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignUpForm())
                      );
                    },
                    child: Text("New User", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white, height: 2),)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

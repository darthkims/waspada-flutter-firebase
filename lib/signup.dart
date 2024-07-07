import 'package:flutter/material.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/login.dart';
import 'package:fypppp/firestore/authentication.dart'; // Import your authentication helper class

class SignUpForm extends StatelessWidget {
  const SignUpForm({Key? key});

  @override
  Widget build(BuildContext context) {
    final FocusNode _fullNameFocus = FocusNode();
    final FocusNode _emailFocus = FocusNode();
    final FocusNode _passwordFocus = FocusNode();
    final FocusNode _confirmPasswordFocus = FocusNode();
    final FocusNode _usernameFocus = FocusNode();

    void _usernameSubmitted(String value) {
      FocusScope.of(context).requestFocus(_emailFocus);
    }

    void _emailSubmitted(String value) {
      FocusScope.of(context).requestFocus(_passwordFocus);
    }

    void _passwordSubmitted(String value) {
      FocusScope.of(context).requestFocus(_confirmPasswordFocus);
    }

    // Create an instance of AuthenticationHelper
    final AuthenticationHelper _authHelper = AuthenticationHelper();

    final TextEditingController _fullNameController = TextEditingController();
    final TextEditingController _userNameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF66EEEE),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(15),
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
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_usernameFocus);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Colors.black),
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _userNameController,
                  focusNode: _usernameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: _usernameSubmitted,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Colors.black),
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: _emailSubmitted,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.black),
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: _passwordSubmitted,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFFFFFFF),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xFF6798F8)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    // Check if full name is empty
                    if (_fullNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your full name")),
                      );
                      return; // Stop further execution
                    }

                    // Check if email is empty or not valid
                    if (_emailController.text.isEmpty ){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid email")),
                      );
                      return; // Stop further execution
                    }

                    // Check if password is empty
                    if (_passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a password")),
                      );
                      return; // Stop further execution
                    }

                    // Check if confirm password matches password
                    if (_passwordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return; // Stop further execution
                    }

                    // Call the signUp method when the button is pressed
                    String? signUpResult = await _authHelper.signUp(
                      email: _emailController.text,
                      password: _passwordController.text,
                      fullName: _fullNameController.text,
                      userName: _userNameController.text,
                    );

                    if (signUpResult == null) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginForm())
                      );
                    } else {
                      // Display sign-up error to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(signUpResult)),
                      );
                    }
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(color: Color(0xFF6798F8),),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(const Color(0xFF6798F8)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginForm()),
                    );
                  },
                  child: const Text(
                    "Existing User",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

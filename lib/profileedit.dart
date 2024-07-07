import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypppp/firestore/fetchdata.dart';

const Color theme = Colors.red;

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Fetch current user's data from Firestore
    User? currentUser = _auth.currentUser;
    if(currentUser != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if(userData.exists) {
        Map<String, dynamic> userDataMap = userData.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = currentUser.displayName ?? '';
          _unameController.text = userDataMap['username'] ?? '';
          _phoneController.text = userDataMap['phoneNumber'] ?? '';
        });
      }
    }
  }


  Future<void> _updateUserData() async {
    // Check if all fields are filled
    if (!_areAllFieldsFilled()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please fill in all fields."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Get new user data from text controllers
    String newName = _nameController.text.trim();
    String newUsername = _unameController.text.trim();
    String newPhone = _phoneController.text.trim();

    // Call the update method in FirestoreFetcher
    await _firestoreFetcher.updateUserData(newName, newUsername, newPhone);

    print("Updated info:");
    print('$newUsername');
    print('$newName');
    print('$newPhone');
    // Optionally, you can reload the user data after updating
    await _loadUserData();

    // Hide loading indicator
    setState(() {
      _isLoading = false;
    });
  }

  bool _areAllFieldsFilled() {
    return _nameController.text.isNotEmpty &&
        _unameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: theme, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: theme),
      ),
      backgroundColor: Color(0xFFF4F3F2),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _unameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(const Color(0xFF6798F8)),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: _updateUserData,
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Change the color here
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

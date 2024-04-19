import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  int currentPageIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Home()));
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Circles()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => CasesAround()));
          break;
        case 3:

          break;
      }
    });
  }

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
            title: Text("Error"),
            content: Text("Please fill in all fields."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
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
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                margin: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
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
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _unameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: _updateUserData,
                      child: Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Positioned.fill(
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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                                : const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)

          ),
        ),
        child: NavigationBar(
          height: 75,
          backgroundColor: Colors.blue,
          onDestinationSelected: _onItemTapped, // Use _onItemTapped for selection
          indicatorColor: Colors.white,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: ImageIcon(
                AssetImage('assets/images/appicon.png'), size: 30, // Replace with your image path
              ),
              icon: ImageIcon(
                AssetImage('assets/images/appicon.png',), size: 30, color: Colors.white, // Replace with your image path
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
              icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
              label: 'Circles', // Empty label for a cleaner look (optional)
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings_input_antenna_outlined, size: 30,),
              icon: Icon(Icons.settings_input_antenna, color: Colors.white, size: 30,),
              label: 'Cases Around',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
              icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
              label: 'Profile', // Empty label for a cleaner look (optional)
            ),
            ],
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

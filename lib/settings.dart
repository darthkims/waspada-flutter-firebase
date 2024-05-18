import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/firestore/authentication.dart';
import 'package:fypppp/chatpage_tbd.dart';
import 'package:fypppp/preferences.dart';
import 'package:fypppp/startup.dart';

final AuthenticationHelper _authHelper = AuthenticationHelper();


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(
            color: Colors.white), // Set the leading icon color to white
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: const Text('Account Settings'),
                onTap: () {
                  // Navigate to account settings screen
                  // Replace `AccountSettingsScreen` with your actual account settings screen widget
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const AccountSettings()));
                },
              ),
              const Divider(), // Add a divider between menu items
              ListTile(
                title: const Text('Testing SMS'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage()));
                },
              ),
              const Divider(), // Add a divider between menu items
              ListTile(
                title: const Text('Preferences'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PreferencesPage()));
                },
              ),
              const Divider(), // Add a divider between menu items
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
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: const Text("Do you want to log out?"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel")
                            ),
                            TextButton(
                                onPressed: () async {
                                  await _authHelper.signOut();
                                  Navigator.of(context).popUntil((route) =>
                                  route.isFirst); // Pop until first route
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const StartUpScreen()),
                                        (
                                        route) => false, // Remove all existing routes
                                  );
                                  print("Signed out");
                                },
                                child: const Text("Log Out")
                            ),
                          ],
                        );
                      }
                  );
                },
                child: const Text('Sign out', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // Set the leading icon color to white
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: const Text('Change Email'),
                onTap: () {
                  // Navigate to account settings screen
                  // Replace `AccountSettingsScreen` with your actual account settings screen widget
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeEmail()));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Change Password'),
                onTap: () {
                  // Navigate to account settings screen
                  // Replace `AccountSettingsScreen` with your actual account settings screen widget
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePassword()));
                },
              ),
              const Divider(),
            ],
          )

        ),
      ),
    );
  }
}

class ChangeEmail extends StatelessWidget {
  const ChangeEmail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController(); // Controller for TextFormField
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    String? currentEmail = user!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // Set the leading icon color to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Current email:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("$currentEmail",
              style: const TextStyle(fontSize: 18,),
            ),
            const SizedBox(height: 10,),
            const Divider(),
            const SizedBox(height: 10,),
            const Text(
              'Enter New Email Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailController, // Assign the controller to the TextFormField
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                labelText: 'New Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
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
                String newEmail = emailController.text.trim();
                if (newEmail.isNotEmpty) {
                  try {
                    await user.verifyBeforeUpdateEmail(newEmail);
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (BuildContext context)  {
                          return AlertDialog(
                            title: const Text("Confirmation Email Sent"),
                            content: const Text("Please click the link on your new email to change email"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                               },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        }
                    );
                  } catch (e) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Authentication Required'),
                            content: const Text('This operation requires recent authentication. Do you want to log out and login again?.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _authHelper.signOut();
                                  Navigator.of(context).popUntil((route) => route.isFirst); // Pop until first route
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const StartUpScreen()),
                                        (route) => false, // Remove all existing routes
                                  );
                                  print("Signed out");
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          );
                        }
                    );
                    print("$e");
                }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a new email.'),
                    ),
                  );
                }
              },
              child: const Text('Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController passcontroller = TextEditingController(); // Controller for TextFormField
    TextEditingController cpasscontroller = TextEditingController(); // Controller for TextFormField
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    String? currentEmail = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // Set the leading icon color to white
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Current Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10,),
              TextFormField(
                controller: cpasscontroller, // Assign the controller to the TextFormField
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'Current Password',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10,),
              const Text(
                'Enter New Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10,),
              TextFormField(
                controller: passcontroller, // Assign the controller to the TextFormField
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  labelText: 'New Password',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 5,),
              const Text('After updating password, user will be redirected to login page.', style: TextStyle(fontWeight: FontWeight.bold),),
              const SizedBox(height: 30,),
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
                    String cPass = cpasscontroller.text.trim();
                    String newPass = passcontroller.text.trim();
        
                    if (cPass.isNotEmpty && newPass.isNotEmpty) {
                      if (user != null && currentEmail != null) {
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: currentEmail,
                          password: cPass,
                        );
        
                        await user.reauthenticateWithCredential(credential);
                        user.reauthenticateWithCredential(credential);
                        user.updatePassword(newPass);
                        await _authHelper.signOut();
                        Navigator.of(context).popUntil(
                            (route) => route.isFirst); // Pop until first route
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StartUpScreen()),
                          (route) => false, // Remove all existing routes
                        );
                        print("Signed out");
        
                        print("Password Updated");
                      }
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: const Text('Please fill in current and new password'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          }
                      );
                    }
                  },
                  child: const Text('Update', style: TextStyle(color: Colors.white),)
              ),
            ],
          ),
        ),
      ),
    );
  }
}



import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:http/http.dart' as http;


class AddCircle extends StatefulWidget {
  const AddCircle({Key? key}) : super(key: key);

  @override
  State<AddCircle> createState() => _AddCircleState();
}

class _AddCircleState extends State<AddCircle> {
  TextEditingController circleNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  List<String> members = [];

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> searchUsers(String username) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // Check if any user found
      if (querySnapshot.docs.isNotEmpty) {
        // Add found user(s) to the list of members without clearing existing members
        querySnapshot.docs.forEach((doc) {
          members.add(doc['username']);
        });
        // Call setState to update the UI with the new list of members
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$username added")),
        );
        print("$username found!");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found with $username")),
        );
        print('No user found with username $username');
      }
    } catch (e) {
      // Handle errors
      print('Error searching users: $e');
    }
  }

  // Method to search for users based on username
  void addMember() {
    if (usernameController.text.isNotEmpty) {
      // Search for users based on username
      searchUsers(usernameController.text);
      // Clear the text field for the next entry
      usernameController.clear();
    }
  }

  Future<void> addCircleToFirestore(String circleName, List<String> memberNames) async {
    try {
      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Initialize a list to store the user IDs of the members
      List<String> memberIds = [];

      // Get a reference to the Firestore instance
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      // Query Firestore to find the user IDs of the members based on their names
      QuerySnapshot memberSnapshot = await _firestore.collection('users')
          .where('username', whereIn: memberNames)
          .get();

      // Iterate through the query snapshot to extract user IDs
      memberSnapshot.docs.forEach((doc) {
        memberIds.add(doc.id); // Assuming user ID is stored as the document ID
      });

      // Add the current user's ID to the list of member IDs
      memberIds.add(userId);

      // Set the circle document with the circle name as the document ID
      await _firestore.collection('circles').doc(circleName).set({
        'circleName': circleName,
        'members': memberIds,
        'admin' : userId,
      });

      // Notify each member using FCM
      memberIds.forEach((memberId) async {
        // Skip sending notification to the current user
        if (memberId != userId) {
          await sendFCMNotification(memberId, circleName);
        }
      });
      Navigator.pop(context);

      // Print a message indicating that the circle was added successfully
      print('Circle added to Firestore successfully!');
    } catch (e) {
      // Handle errors
      print('Error adding circle to Firestore: $e');
    }
  }

// Function to send FCM notification
  Future<void> sendFCMNotification(String memberId, String circleName) async {
    // 1. Get a Firebase Messaging token for the member
    String? memberToken;
    String? oauthToken;

    DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore.collection('users').doc(memberId).get();

    if (snapshot.exists) {
      // Extract the FCM token from the document data
      memberToken = snapshot.data()?['fcmToken'];
      print("This is member token: $memberToken");
    } else {
      print("User data not found in Firestore.");
    }

    DocumentSnapshot<Map<String, dynamic>> oauth = await _firestore.collection('token').doc('oauth').get();
    if (oauth.exists) {
      oauthToken = oauth.data()?['oauth'];
      // Now you can use the oauthValue
    } else {
      // Document with ID "oauth" does not exist
    }

    // 2. Check if token is available
    if (memberToken == null) {
      print("Failed to retrieve FCM token for member: $memberId");
      return;
    }

    // 3. Prepare notification payload
    final message = {
      "message": {
        "token": memberToken,
        "notification": {
          "body": "You have been added to the circle!",
          "title": "$circleName"
        }
      }
    };

    // 4. Prepare FCM request URL
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/waspadafyp1/messages:send');

    // 5. Prepare authorization header
    // final authorization = 'Bearer ya29.a0Ad52N38CQR67jDVjRcFmgCgeJD1ieBeuTCvOeqToGay3sdNVAxIEcUAhXZ83HTBA54J6uURAozvPSxRF01ke1IZHQOGUgdUZHuSHuQPhOu-duVU3LADtjZcarhQtcBSUBnY987imZU4fuDRr3VhYOGzaloxpd2OurLoFaCgYKAXsSARMSFQHGX2MiF0i9TpAAfvhIOlRxPxZALg0171';
    final authorization = 'Bearer $oauthToken';
    print("SHAKALAKA");

    // 6. Send FCM notification using HTTP POST request
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorization,
      },
      body: jsonEncode(message),
    );

    // 7. Check response status code
    if (response.statusCode == 200) {
      print("FCM notification sent successfully to member: $memberId");
    } else {
      print("Failed to send FCM notification: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Circle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: circleNameController,
              decoration: const InputDecoration(
                labelText: 'Circle Name',
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter members username',
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: addMember,
                  child: const Text(
                    'Add member',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(Colors.blue),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Members:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            // Display the list of members
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      members[index],
                      style: const TextStyle(color: Colors.black),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Remove the member from the list
                        setState(() {
                          members.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Get circle name
                String circleName = circleNameController.text;
                // Check if circle name is empty
                if (circleName.isEmpty) {
                  // Display Snackbar if circle name is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Circle name cannot be empty")),
                  );
                  return; // Exit onPressed function
                }
                // Check if members list is empty
                if (members.isEmpty) {
                  // Display Snackbar if members list is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please add at least one member")),
                  );
                  return; // Exit onPressed function
                }
                // Add circle to Firestore
                addCircleToFirestore(circleName, members);
              },
              child: const Text(
                'Create Circle',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ButtonStyle(
                backgroundColor:
                MaterialStateProperty.all(Colors.blue),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

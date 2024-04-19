import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addcircle.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circlesdetails.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:geolocator/geolocator.dart';

class Circles extends StatefulWidget {
  const Circles({super.key});

  @override
  State<Circles> createState() => _CirclesState();
}

class _CirclesState extends State<Circles> {
  int currentPageIndex = 1;
  bool isDeleting = false; // Flag to toggle delete button visibility
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

  void _toggleDeleteMode() {
    setState(() {
      isDeleting = !isDeleting;
    });
  }

  Future<String> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    } catch (e) {
      return 'Failed to get location: $e';
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Home()));
          break;
        case 1:
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => CasesAround()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(
              builder: (context) => ProfilePage())); // Assuming Profile page
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Circles',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isDeleting
                      ? SizedBox() // If isDeleting is true, display an empty SizedBox
                      : ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCircle(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 20,),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    onPressed: () {
                      _toggleDeleteMode(); // Toggle delete mode
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isDeleting ? 'Done' : 'Manage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Divider(),
              SizedBox(height: 10,),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('circles').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final circles = snapshot.data?.docs;
                  final currentUserID = FirebaseAuth.instance.currentUser!.uid; // Get current user's ID
                  final userCircles = circles?.where((circle) {
                    final circleMembersIDs = (circle.data() as Map<String, dynamic>)['members'];
                    return circleMembersIDs.contains(currentUserID); // Check if current user's ID is in members list
                  }).toList();

                  if (userCircles!.isEmpty) {
                    return Center(
                      child: Text(
                        'No circles available. Ask your friends to add or create a new one',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    );
                  };


                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userCircles.length,
                    itemBuilder: (context, index) {
                      final circleName = (userCircles[index].data() as Map<String, dynamic>)['circleName'];
                      final adminID = (userCircles[index].data() as Map<String, dynamic>)['admin']; // Retrieve admin ID
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(10),
                            child: GestureDetector(
                              onTap: () async {
                                // Handle container tap here
                                final circleMembersIDs = (circles?[index].data() as Map<String, dynamic>)['members'];

                                // Convert user IDs to usernames
                                List<String> circleUsernames = [];
                                for (String userID in circleMembersIDs) {
                                  String? username = await _firestoreFetcher.getUsernameFromSenderId(userID);
                                  circleUsernames.add(username!);
                                }

                                print("Circle: $circleName, Circle Members: $circleUsernames");
                              },
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "$circleName",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                                          ),
                                        ),
                                      ),
                                      isDeleting
                                          ? (adminID == currentUserID
                                          ? GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text("Confirm Delete"),
                                                content: Text("Are you sure you want to delete this circle?"),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _firestoreFetcher.deleteCircle(circleName); // Delete circle
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: Text("Delete"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFCB2929),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: EdgeInsets.all(5.0), // Add padding around the icon
                                          child: Column(
                                            children: [
                                              Icon(Icons.delete, color: Colors.white, size: 20,),
                                            ],
                                          ),
                                        ),
                                      )
                                          : GestureDetector(
                                        onTap: () {
                                          // Handle leaving the circle here
                                          // Example: _firestoreFetcher.leaveCircle(circleName);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFCB2929),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: EdgeInsets.all(5.0), // Add padding around the icon
                                          child: Column(
                                            children: [
                                              Icon(Icons.exit_to_app, color: Colors.white, size: 20,),
                                            ],
                                          ),
                                        ),
                                      )
                                      )
                                          : SizedBox(),
                                      // Empty SizedBox if not in delete mode
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFDEDE),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            // Handle icon tap here
                                            print('Location icon tapped');
                                          },
                                          child: Column(
                                            children: [
                                              Icon(Icons.my_location, color: Colors.black, size: 60,),
                                              Text('Check In'),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            String location = await _getLocation();
                                            String userId = FirebaseAuth.instance.currentUser!.uid;
                                              String senderId = userId;

                                              // Add the message to Firestore
                                              FirebaseFirestore.instance.collection('circles').doc(circleName).collection('messages').add({
                                                'senderId': senderId,
                                                'message': "CHECK IN REPORT: $location",
                                                'timestamp': Timestamp.now(),
                                              });

                                            print('Add Location icon tapped');
                                          },
                                          child: Column(
                                            children: [
                                              Icon(Icons.add_location_alt, color: Colors.black, size: 60,),
                                              Text('Add Location'),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            // Handle icon tap here
                                            print('Open Circle icon tapped');
                                            // Navigate to the new page
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CircleDetailsPage(circleName), // Replace CircleDetailsPage with your desired page
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              Icon(Icons.open_in_new, color: Colors.black, size: 60,),
                                              Text('Open Circle'),
                                            ],
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 30),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                  (Set<MaterialState> states) =>
              states.contains(MaterialState.selected)
                  ? const TextStyle(color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)
                  : const TextStyle(color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)
          ),
        ),
        child: NavigationBar(
          height: 75,
          backgroundColor: Colors.blue,
          onDestinationSelected: _onItemTapped,
          indicatorColor: Colors.white,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: ImageIcon(
                AssetImage('assets/images/appicon.png'), size: 30,
              ),
              icon: ImageIcon(
                AssetImage('assets/images/appicon.png',), size: 30,
                color: Colors.white,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
              icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
              label: 'Circles',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.settings_input_antenna_outlined, size: 30,),
              icon: Icon(
                Icons.settings_input_antenna, color: Colors.white, size: 30,),
              label: 'Cases Around',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
              icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}



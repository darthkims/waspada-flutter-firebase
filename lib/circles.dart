
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addcircle.dart';
import 'package:fypppp/casesaround_district.dart';
import 'package:fypppp/circlesdetails.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/sos.dart';

class Circles extends StatefulWidget {
  const Circles({super.key});

  @override
  State<Circles> createState() => _CirclesState();
}

class _CirclesState extends State<Circles> {
  int currentPageIndex = 2;
  bool isDeleting = false; // Flag to toggle delete button visibility
  final FirestoreFetcher firestoreFetcher = FirestoreFetcher();

  void onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const Home();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 1:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const SOSPage();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 2:
          break;
        case 3:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const CasesAroundDistrict();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 4:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1,
                  Animation<double> animation2) {
                return const ProfilePage();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    const Color theme = Colors.red;
    const Color sectheme = Colors.white;

    return Scaffold(
        backgroundColor: const Color(0xFFF4F3F2),
        appBar: AppBar(
          backgroundColor: theme,
          title: const Text(
            'Circles',
            style: TextStyle(color: sectheme, fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddCircle()));
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: sectheme,
                    )
                ),
                const SizedBox(width: 10,)
              ],
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('circles')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          final circles = snapshot.data?.docs;
                          final currentUserID = FirebaseAuth
                              .instance.currentUser!.uid; // Get current user's ID
                          final userCircles = circles?.where((circle) {
                            final circleMembersIDs =
                                (circle.data() as Map<String, dynamic>)['members'];
                            return circleMembersIDs.contains(
                                currentUserID);
                          }).toList();

                          if (userCircles!.isEmpty) {
                            return const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sentiment_dissatisfied_outlined,
                                  size: 100,
                                ),
                                Center(
                                  child: Text(
                                    'No circles available. Ask your friends to add or create a new one by tapping top right button!',
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10.0,
                              crossAxisSpacing: 10.0,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: userCircles.length,
                            itemBuilder: (context, index) {
                              final circleName = (userCircles[index].data() as Map<String, dynamic>)['circleName'];
                              final icon = (userCircles[index].data() as Map<String, dynamic>)['icon'];
                              final type = (userCircles[index].data() as Map<String, dynamic>)['type'];
                              final adminID = (userCircles[index].data() as Map<String, dynamic>)['admin'];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => CircleDetailsPage(circleName))
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 45,
                                        right: 20,
                                        child: Image.asset(
                                          icon != null ? "assets/circle_icons/$icon.png" : "assets/circle_icons/partner_exchange.png",
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        circleName,
                                                        style: const TextStyle(
                                                          fontSize: 25,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const SizedBox(height: 10,),
                                                                  Text(
                                                                    "$circleName",
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 30
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 10,),
                                                                  const Divider(),
                                                                  const SizedBox(height: 10,),
                                                                  ListTile(
                                                                    leading: const Icon(
                                                                      Icons.delete,
                                                                      size: 33, // Adjust the size of the icon
                                                                    ),
                                                                    title: Text(
                                                                      currentUserID == adminID ? 'Delete Circle' : 'Leave Circle',
                                                                      style: const TextStyle(fontSize: 17), // Adjust the font size
                                                                    ),
                                                                    onTap: () {
                                                                      showDialog(
                                                                        context: context,
                                                                        builder: (BuildContext context) {
                                                                          return AlertDialog(
                                                                            title: Text(
                                                                              currentUserID == adminID ? "Confirm Delete" : "Confirm Leave",
                                                                            ),
                                                                            content: Text(
                                                                              currentUserID == adminID
                                                                                  ? "Are you sure you want to delete this circle?"
                                                                                  : "Are you sure you want to leave this circle?",
                                                                            ),
                                                                            actions: <Widget>[
                                                                              TextButton(
                                                                                onPressed: () {
                                                                                  Navigator.of(context).pop(); // Close the dialog
                                                                                },
                                                                                child: const Text("Cancel"),
                                                                              ),
                                                                              TextButton(
                                                                                onPressed: () {
                                                                                  if (currentUserID == adminID) {
                                                                                    firestoreFetcher.deleteCircle(circleName); // Delete circle
                                                                                  } else {
                                                                                    firestoreFetcher.leaveCircle(circleName, currentUserID); // Implement your leave circle function
                                                                                  }
                                                                                  Navigator.of(context).pop();
                                                                                  Navigator.of(context).pop();
                                                                                },
                                                                                child: Text(currentUserID == adminID ? "Delete" : "Leave"),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            }
                                                        );
                                                      },
                                                      icon: const Icon(Icons.more_horiz_outlined),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: theme,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Text(
                                                          type != null ? type : "Null",
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Container(
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF9ACD32),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.my_location_outlined, color: Colors.white,),
                                                      onPressed: () {
                                                        firestoreFetcher.checkIn(circleName, currentUserID, context);
                                                      },
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[300],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.camera_alt, color: Colors.white,),
                                                      onPressed: () {
                                                        firestoreFetcher.quickCapture(circleName, currentUserID, context);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )

                              );
                            },
                          );
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomNavigationBar(
            currentPageIndex: currentPageIndex, onItemTapped: onItemTapped));
  }
}

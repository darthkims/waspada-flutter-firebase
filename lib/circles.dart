import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addcircle.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circlesdetails.dart';
import 'package:fypppp/firestore/sqflite_helper.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/sos.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:tuple/tuple.dart';


class Circles extends StatefulWidget {
  const Circles({super.key});

  @override
  State<Circles> createState() => _CirclesState();
}

class _CirclesState extends State<Circles> {
  int currentPageIndex = 2;
  bool isDeleting = false; // Flag to toggle delete button visibility
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

  Future<void> getUserFromFirebase(userId) async {
    // Assuming you have the user's ID, replace 'userId' with the actual ID
    await DatabaseHelper.instance.getUserFromFirebase(userId);
    await DatabaseHelper.instance.getAllUsers();
  }


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

  Future<Tuple2<double, double>> _getCoordinate() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return Tuple2(position.latitude, position.longitude);
    } catch (e) {
      // Handle error
      throw Exception('Failed to get location: $e');
    }
  }



  void onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
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
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
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
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                return const CasesAround();
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
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Circles',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isDeleting
                      ? const SizedBox() // If isDeleting is true, display an empty SizedBox
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
                          builder: (context) => const AddCircle(),
                        ),
                      );
                    },
                    child: const Column(
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

                  const SizedBox(width: 20,),
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
                          style: const TextStyle(
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
              const SizedBox(height: 10,),
              const Divider(),
              const SizedBox(height: 10,),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('circles').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                    return const Center(
                      child: Text(
                        'No circles available. Ask your friends to add or create a new one',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }


                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userCircles.length,
                    itemBuilder: (context, index) {
                      final circleName = (userCircles[index].data() as Map<String, dynamic>)['circleName'];
                      final adminID = (userCircles[index].data() as Map<String, dynamic>)['admin']; // Retrieve admin ID
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.lightBlueAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: GestureDetector(
                              onTap: () async {
                                // Handle container tap here
                                final circleMembersIDs = (circles?[index].data() as Map<String, dynamic>)['members'];

                                // Convert user IDs to usernames
                                List<String> circleUsernames = [];
                                for (String userID in circleMembersIDs) {
                                  getUserFromFirebase(userID);
                                  String? username = await _firestoreFetcher.getUsernameFromSenderId(userID);
                                  circleUsernames.add(username!);
                                }

                                print("Circle: $circleName, Circle Members: $circleUsernames");
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => CircleDetailsPage(circleName), // Replace CircleDetailsPage with your desired page
                                //   ),
                                // );
                              },
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "$circleName",
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
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
                                                title: const Text("Confirm Delete"),
                                                content: const Text("Are you sure you want to delete this circle?"),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _firestoreFetcher.deleteCircle(circleName); // Delete circle
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFCB2929),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: const EdgeInsets.all(5.0), // Add padding around the icon
                                          child: const Column(
                                            children: [
                                              Icon(Icons.delete, color: Colors.white, size: 20,),
                                            ],
                                          ),
                                        ),
                                      )
                                          : GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text("Exit circle?"),
                                                content: const Text("Are you sure you want to exit this circle?"),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _firestoreFetcher.leaveCircle(circleName, currentUserID);
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: const Text("Exit"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFCB2929),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: const EdgeInsets.all(5.0), // Add padding around the icon
                                          child: const Column(
                                            children: [
                                              Icon(Icons.exit_to_app, color: Colors.white, size: 20,),
                                            ],
                                          ),
                                        ),
                                      )
                                      )
                                          : const SizedBox(),
                                      // Empty SizedBox if not in delete mode
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDEDE),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            String location = await _getLocation();
                                            String userId = FirebaseAuth.instance.currentUser!.uid;
                                            String senderId = userId;
                                            Tuple2<double, double> coordinates = await _getCoordinate();
                                            final GeoPoint coordinate = GeoPoint(coordinates.item1, coordinates.item2);


                                            // Add the message to Firestore
                                            FirebaseFirestore.instance.collection('circles').doc(circleName).collection('messages').add({
                                              'senderId': senderId,
                                              'message': "CHECK IN REPORT: $location",
                                              'location' : coordinate,
                                              'timestamp': Timestamp.now(),
                                            });

                                            print('Add Location icon tapped');
                                            await _firestoreFetcher.sendFCMNotification(senderId, circleName, location);
                                            print('Location icon tapped');
                                          },
                                          child: const Column(
                                            children: [
                                              Icon(Icons.my_location, color: Colors.black, size: 60,),
                                              Text('Check In'),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            File? mediaFile;
                                            String fileName = '${DateTime.now()}_${circleName}_${currentUserID}.jpg';
                                            print("fileName: $fileName");
                                            final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
                                            mediaFile = File(image!.path);
                                            // Do something with the captured image
                                            if (mediaFile != null) {
                                              String location = await _getLocation();
                                              String userId = FirebaseAuth.instance.currentUser!.uid;
                                              String senderId = userId;
                                              Tuple2<double, double> coordinates = await _getCoordinate();
                                              final GeoPoint coordinate = GeoPoint(coordinates.item1, coordinates.item2);

                                              final exifData = await Exif.fromPath(mediaFile.path);
                                              await exifData.writeAttribute(
                                                  "DateTimeOriginal", DateFormat("yyyy:MM:dd HH:mm:ss").format(DateTime.now())
                                              );
                                              await exifData.writeAttribute(
                                                  "UserComment", "Reported in $circleName uploaded using Waspada."
                                              );
                                              await exifData.writeAttributes({
                                                'GPSLatitude': coordinates.item1,
                                                'GPSLatitudeRef': 'N',
                                                'GPSLongitude': coordinates.item2,
                                                'GPSLongitudeRef': 'E',
                                              });
                                              final uploadedDate = await exifData.getOriginalDate();
                                              final locationcoordinate = await exifData.getLatLong();
                                              final userComment = await exifData.getAttribute("UserComment");
                                              print("Uploaded Date for $fileName: $uploadedDate");
                                              print("Coordinates for $fileName: $locationcoordinate");
                                              print("User Comment for $fileName: $userComment");
                                              await exifData.close();

                                              String hashKey = await _firestoreFetcher.generateFileSha256(mediaFile.path);

                                              final storage = FirebaseStorage.instance;
                                              final mediaRef = storage.ref().child('circleevidence/$circleName/$fileName');
                                              print("mediaRef: $mediaRef");

                                              try {
                                                await mediaRef.putFile(mediaFile);
                                                print("Media file uploaded successfully");
                                              } catch (e) {
                                                // Handle errors
                                                print('Error uploading media file: $e');
                                              }

                                              final mediaUrl = await mediaRef.getDownloadURL();

                                              String compressedUrl = await _firestoreFetcher.downloadAndUploadCompressedImage(mediaUrl, circleName, fileName);

                                              // Add the message to Firestore
                                              FirebaseFirestore.instance.collection('circles').doc(circleName).collection('messages').add({
                                                'fileName' : fileName,
                                                'senderId': senderId,
                                                'message': "Quick Capture: ($location) (SHA256: $hashKey)",
                                                'location' : coordinate,
                                                'timestamp': Timestamp.now(),
                                                'hashkey' : hashKey,
                                                'mediaUrl' : mediaUrl,
                                              });
                                              await _firestoreFetcher.sendFCMImageNotification(senderId, circleName, location, compressedUrl);

                                            }
                                          },
                                          child: const Column(
                                            children: [
                                              Icon(Icons.camera_alt_outlined, color: Colors.black, size: 60,),
                                              Text('Quick Capture'),
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
                                          child: const Column(
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

                          const SizedBox(height: 30),
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
      bottomNavigationBar: CustomNavigationBar(currentPageIndex: currentPageIndex, onItemTapped: onItemTapped)
    );
  }
}



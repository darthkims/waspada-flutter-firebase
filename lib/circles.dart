import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addcircle.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circlesdetails.dart';
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

  Future<String> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    } catch (e) {
      return 'Failed to get location: $e';
    }
  }

  Future<Tuple2<double, double>> _getCoordinate() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return Tuple2(position.latitude, position.longitude);
    } catch (e) {
      // Handle error
      throw Exception('Failed to get location: $e');
    }
  }

  void quickCapture(String circleName, String currentUserID) async {
    File? mediaFile;
    String fileName = '${DateTime.now()}_${circleName}_${currentUserID}.jpg';
    print("fileName: $fileName");
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.camera);
    mediaFile = File(image!.path);
    // Do something with the captured image
    if (mediaFile != null) {
      String location = await _getLocation();
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String senderId = userId;
      Tuple2<double, double> coordinates = await _getCoordinate();
      final GeoPoint coordinate =
          GeoPoint(coordinates.item1, coordinates.item2);

      final exifData = await Exif.fromPath(mediaFile.path);
      await exifData.writeAttribute("DateTimeOriginal",
          DateFormat("yyyy:MM:dd HH:mm:ss").format(DateTime.now()));
      await exifData.writeAttribute(
          "UserComment", "Reported in $circleName uploaded using Waspada.");
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

      String hashKey =
          await _firestoreFetcher.generateFileSha256(mediaFile.path);

      final storage = FirebaseStorage.instance;
      final mediaRef =
          storage.ref().child('circleevidence/$circleName/$fileName');
      print("mediaRef: $mediaRef");

      try {
        await mediaRef.putFile(mediaFile);
        print("Media file uploaded successfully");
      } catch (e) {
        // Handle errors
        print('Error uploading media file: $e');
      }

      final mediaUrl = await mediaRef.getDownloadURL();

      String compressedUrl = await _firestoreFetcher
          .downloadAndUploadCompressedImage(mediaUrl, circleName, fileName);

      // Add the message to Firestore
      FirebaseFirestore.instance
          .collection('circles')
          .doc(circleName)
          .collection('messages')
          .add({
        'fileName': fileName,
        'senderId': senderId,
        'message': "Quick Capture: ($location) (SHA256: $hashKey)",
        'location': coordinate,
        'timestamp': Timestamp.now(),
        'hashkey': hashKey,
        'mediaUrl': mediaUrl,
      });
      await _firestoreFetcher.sendFCMImageNotification(senderId, circleName, location, compressedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick Capture sent to Circle $circleName!'),
        ),
      );
    }
  }

  Future<void> checkIn(String circleName, userId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending Check In to Circle $circleName!'),
      ),
    );
    String location = await _getLocation();
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

    FirebaseFirestore.instance.collection('circles').doc(circleName).collection('checkin').add({
      'senderId': senderId,
      'location' : coordinate,
      'timestamp': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check In has been sent to Circle $circleName!'),
      ),
    );
    await _firestoreFetcher.sendFCMNotification(senderId, circleName, location);
  }

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

    return Scaffold(
        backgroundColor: Color(0xFFF4F3F2),
        appBar: AppBar(
          title: const Text(
            'Circles',
            style: TextStyle(color: theme, fontWeight: FontWeight.bold),
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
                      color: Colors.black87,
                    )
                ),
                SizedBox(width: 10,)
              ],
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(10),
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
                                  Icons.sentiment_dissatisfied_sharp,
                                  size: 100,
                                ),
                                Center(
                                  child: Text(
                                    'No circles available. Ask your friends to add or create a new one by clicking top right button!',
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      circleName,
                                                      style: TextStyle(
                                                        fontSize: 25,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    IconButton(
                                                        onPressed: () {
                                                          showModalBottomSheet(
                                                              context: context,
                                                              builder: (BuildContext context) {
                                                                return Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    SizedBox(height: 10,),
                                                                    ListTile(
                                                                      leading: const Icon(
                                                                        Icons.delete,
                                                                        size: 33, // Adjust the size of the icon
                                                                      ),
                                                                      title: Text(
                                                                        currentUserID == adminID ? 'Delete Circle' : 'Leave Circle',
                                                                        style: TextStyle(fontSize: 17), // Adjust the font size
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
                                                                                    _firestoreFetcher.deleteCircle(circleName); // Delete circle
                                                                                  } else {
                                                                                    _firestoreFetcher.leaveCircle(circleName, currentUserID); // Implement your leave circle function
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
                                                        icon: Icon(Icons.more_horiz_outlined)
                                                    )
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Text(
                                                          type != null ? type : "Null",
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white),
                                                        ),
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: theme,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Container(
                                                    child: IconButton(
                                                      icon:
                                                          Icon(Icons.my_location_outlined, color: Colors.white,),
                                                      onPressed: () {
                                                        checkIn(circleName, currentUserID);
                                                      },
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  Container(
                                                    child: IconButton(
                                                      icon: Icon(Icons.camera_alt, color: Colors.white,),
                                                      onPressed: () {
                                                        quickCapture(circleName, currentUserID);
                                                      },
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[300],
                                                      shape: BoxShape.circle,
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
                                ),
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

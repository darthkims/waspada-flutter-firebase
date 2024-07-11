import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FirestoreFetcher {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  // Update user data
  Future<void> updateUserData(String newName, String newUsername, String newPhone) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {

        // Update display name
        await currentUser.updateDisplayName(newName);

        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'fullName': newName,
          'username' : newUsername,
          'phoneNumber' : newPhone
        });
      }
    } catch (e) {
      // Handle errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          print('Re-authentication is required. Please fill in your password again.');
        } else {
          // Handle other FirebaseAuthException errors
          print('Firebase Authentication Error: ${e.message}');
        }
      } else {
        // Handle other errors
        print('Error updating user data: $e');
      }
    }
  }


  Future<void> uploadReport(String caseType, String location, File mediaFile, String city, String desc) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Generate SHA256 hash for the media file
      DateTime date = DateTime.now();
      int flagsCount = 0;
      int likesReport = 0;
      List<String> parts = location.split(','); // Split the string by comma

      // Extract latitude and longitude
      String latitude = parts[0].trim(); // Remove leading/trailing whitespace
      String longitude = parts[1].trim(); // Remove leading/trailing whitespace

      // Determine the file extension from the original file name
      String originalExtension = mediaFile.path.split('.').last;

      // Upload media file to Firebase Storage
      String fileName = '${DateTime.now()}_${caseType}_${currentUser.uid}.$originalExtension';
      print("fileName: $fileName");

      if (originalExtension == "jpg"){
        final exifData = await Exif.fromPath(mediaFile.path);
        await exifData.writeAttribute(
            "DateTimeOriginal", DateFormat("yyyy:MM:dd HH:mm:ss").format(DateTime.now())
        );
        await exifData.writeAttribute(
            "UserComment", " $desc. Report $caseType uploaded using Waspada."
        );
        await exifData.writeAttributes({
          'GPSLatitude': latitude,
          'GPSLatitudeRef': 'N',
          'GPSLongitude': longitude,
          'GPSLongitudeRef': 'E',
        });
        final uploadedDate = await exifData.getOriginalDate();
        final coordinates = await exifData.getLatLong();
        final userComment = await exifData.getAttribute("UserComment");
        print("Uploaded Date for $fileName: $uploadedDate");
        print("Coordinates for $fileName: $coordinates");
        print("User Comment for $fileName: $userComment");
        await exifData.close();
      }

      String hashKey = await generateFileSha256(mediaFile.path);

      final storage = FirebaseStorage.instance;
      final mediaRef = storage.ref().child('reportevidence/$fileName');
      print("mediaRef: $mediaRef");

      try {
        await mediaRef.putFile(mediaFile);
        print("Media file uploaded successfully");
      } catch (e) {
        // Handle errors
        print('Error uploading media file: $e');
      }

      // Get download URL of the uploaded media file
      final mediaUrl = await mediaRef.getDownloadURL();

      // Save report data to Firestore
      await firestore.collection('reports').add({
        'userId': currentUser.uid,
        'caseType': caseType,
        'description' : desc,
        'flagsCount': flagsCount,
        'likesCount' : likesReport,
        'location': location,
        'city' : city,
        'mediaUrl': mediaUrl,
        'mediaFileName' : fileName,
        'hashkey': hashKey,
        'timeStamp' : date,
      });
      print("Report uploaded successfully");
    } catch (e) {
      // Handle errors
      print('Error uploading report: $e');
    }
  }


  Future<void> deleteReport(String reportId, String mediaFileName) async {
    try {
      // Delete report document from Firestore
      await firestore.collection('reports').doc(reportId).delete();
      print("Report deleted successfully");

      // Delete media file from Firebase Storage
      final storage = FirebaseStorage.instance;
      final mediaRef = storage.ref().child('reportevidence/$mediaFileName');
      await mediaRef.delete();
      print("Media file deleted successfully");
    } catch (e) {
      // Handle errors
      print('Error deleting report: $e');
    }
  }

  Future<void> deleteRecording(String reportId, String mediaFileName) async {
    User? user = _auth.currentUser;

    try {
      // Delete report document from Firestore
      await firestore.collection('users').doc(user!.uid).collection('SOSreports').doc(reportId).delete();
      print("Report deleted successfully");

      // Delete media file from Firebase Storage
      final storage = FirebaseStorage.instance;
      final mediaRef = storage.ref().child('SOSRecording/${user.uid}/$mediaFileName');
      await mediaRef.delete();
      print("Media file deleted successfully");
    } catch (e) {
      // Handle errors
      print('Error deleting report: $e');
    }
  }

  Future<void> deleteAudioRecording(String reportId, String mediaFileName) async {
    User? user = _auth.currentUser;

    try {
      // Delete report document from Firestore
      await firestore.collection('users').doc(user!.uid).collection('SOSAudioreports').doc(reportId).delete();
      print("Report deleted successfully");
      print(mediaFileName);

      // Delete media file from Firebase Storage
      final storage = FirebaseStorage.instance;
      final mediaRef = storage.ref().child('SOSAudioRecording/${user.uid}/$mediaFileName');
      await mediaRef.delete();
      print("Media file deleted successfully");
    } catch (e) {
      // Handle errors
      print('Error deleting report: $e');
    }
  }

  Future<String> generateFileSha256(String filePath) async {
    var file = File(filePath);
    if (await file.exists()) {
      var contents = await file.readAsBytes();
      var sha256Hash = sha256.convert(contents).toString();
      print('SHA256 Hash of $filePath: $sha256Hash');
      return sha256Hash; // Return the hashKey as String
    } else {
      print('File not found: $filePath');
      throw Exception('File not found');
    }
  }

  Future<void> toggleFlagReport(String documentId, String currentUserUid, BuildContext context) async {
    try {
      // Check if the user has already liked the report
      final flagReports = await FirebaseFirestore.instance
          .collection('userFlags')
          .doc(currentUserUid)
          .get();

      if (flagReports.exists) {
        final likedReportIds = flagReports.data()?['flagReports'] ?? [];
        if (likedReportIds.contains(documentId)) {
          // User has already liked this report, so decrement the likes count and remove the report from flagReports list
          await FirebaseFirestore.instance.collection('reports').doc(documentId).update({
            'flagsCount': FieldValue.increment(-1),
          });
          await FirebaseFirestore.instance.collection('userFlags').doc(currentUserUid).update({
            'flagReports': FieldValue.arrayRemove([documentId]),
          });
          print('Like decremented successfully!');
          return;
        }
      }

      // If the user hasn't liked the report yet, increment the likes count and add the report to flagReports list
      await FirebaseFirestore.instance.collection('reports').doc(documentId).update({
        'flagsCount': FieldValue.increment(1),
      });
      await FirebaseFirestore.instance.collection('userFlags').doc(currentUserUid).set({
        'flagReports': FieldValue.arrayUnion([documentId]),
      }, SetOptions(merge: true));
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Thanks for reporting!"),
              content: const Text("Action will be taken to false, hateful and fake report.",
                style: TextStyle(fontSize: 15),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );

          },
        );
      print('Like incremented successfully!');
    } catch (e) {
      print('Error toggling like: $e');
      // Handle error if necessary
    }
  }

  Future<void> toggleLikeReport(String documentId, String currentUserUid) async {
    try {
      // Check if the user has already liked the report
      final likeReports = await FirebaseFirestore.instance
          .collection('userFlags')
          .doc(currentUserUid)
          .get();

      if (likeReports.exists) {
        final likedReportIds = likeReports.data()?['likeReports'] ?? [];
        if (likedReportIds.contains(documentId)) {
          // User has already liked this report, so decrement the likes count and remove the report from likeReports list
          await FirebaseFirestore.instance.collection('reports').doc(documentId).update({
            'likesCount': FieldValue.increment(-1),
          });
          await FirebaseFirestore.instance.collection('userFlags').doc(currentUserUid).update({
            'likeReports': FieldValue.arrayRemove([documentId]),
          });
          print('Like decremented successfully!');
          return;
        }
      }

      // If the user hasn't liked the report yet, increment the likes count and add the report to likeReports list
      await FirebaseFirestore.instance.collection('reports').doc(documentId).update({
        'likesCount': FieldValue.increment(1),
      });
      await FirebaseFirestore.instance.collection('userFlags').doc(currentUserUid).set({
        'likeReports': FieldValue.arrayUnion([documentId]),
      }, SetOptions(merge: true));

      print('Like incremented successfully!');
    } catch (e) {
      print('Error toggling like: $e');
      // Handle error if necessary
    }
  }

  Future<List<String>> convertIDtoUsername(List<dynamic> userIds) async {
    List<String> usernames = [];
    for (var userId in userIds) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var username = userDoc.get('username');
      usernames.add(username);
    }
    return usernames;
  }

  Future<String?> getUsernameFromSenderId(String senderId) async {
    try {
      // Fetch user document from Firestore using senderId
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users') // Adjust collection name accordingly
          .doc(senderId)
          .get();

      // Check if the user document exists
      if (userSnapshot.exists) {
        // Get the username from the user document
        String? username = userSnapshot.get('username');
        return username;
      } else {
        // User document does not exist
        return null;
      }
    } catch (error) {
      // Handle any errors that occur during the fetch operation
      print("Error fetching username: $error");
      return null;
    }
  }

  void deleteCircle(String circleName) {
    FirebaseFirestore.instance.collection('circles').doc(circleName).delete();
  }

  void leaveCircle(String circleName, String memberId) {
    // First, get a reference to the circle document
    DocumentReference circleRef = FirebaseFirestore.instance.collection('circles').doc(circleName);

    // Then, update the circle document to remove the member
    circleRef.update({
      'members': FieldValue.arrayRemove([memberId])
    }).then((_) {
      print('Member $memberId left circle $circleName successfully.');
    }).catchError((error) {
      print('Failed to leave circle: $error');
    });
  }


  Future<void> downloadImage(String url, String mediaFileName) async {
    Uri link = Uri.parse(url);
    if (await canLaunchUrl(link)) {
      await launchUrl(link);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> sendFCMImageNotification(String senderId, String circleName, String content, String imageUrl) async {
    try {
      // Retrieve the circle document
      DocumentSnapshot<Map<String, dynamic>> circleSnapshot =
      await FirebaseFirestore.instance.collection('circles').doc(circleName).get();

      if (!circleSnapshot.exists) {
        print("Circle document with name $circleName does not exist.");
        return;
      }

      String? currentUsername;

      DocumentSnapshot<Map<String, dynamic>> currentUserSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      currentUsername = currentUserSnapshot.data()?['username'];

      // Extract the members list from the circle document data
      List<dynamic> members = circleSnapshot.data()?['members'];

      // Filter out the sender's ID from the members list
      List<String> recipientIds = List<String>.from(members).where((memberId) => memberId != senderId).toList();

      // Retrieve FCM tokens for the recipients
      for (String memberId in recipientIds) {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (userSnapshot.exists) {
          // Extract the FCM token from the user document data
          String? memberToken = userSnapshot.data()?['fcmToken'];
          if (memberToken != null) {
            // Prepare notification payload
            final message = {
              "message": {
                "token": memberToken,
                "notification": {
                  "body": "$currentUsername: Quick Capture - $content",
                  "title": circleName,
                  "image": imageUrl // Add image URL here
                },
                "data": {
                  "route": "/circleDetails",
                  "circleName": circleName,
                  "click_action": "FLUTTER_NOTIFICATION_CLICK"
                },
                "android": {
                  "notification": {
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                  }
                },
              },
            };



            // Prepare FCM request URL
            final url = Uri.parse('https://fcm.googleapis.com/v1/projects/waspadafyp1/messages:send');

            // Prepare authorization header
            final oauthToken = await retrieveOAuthToken(); // Retrieve OAuth token from Firestore or any other source
            final authorization = 'Bearer $oauthToken';

            // Send FCM notification using HTTP POST request
            final response = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authorization,
              },
              body: jsonEncode(message),
            );

            // Check response status code
            if (response.statusCode == 200) {
              print("FCM notification sent successfully to member: $memberId");
            } else {
              print("Failed to send FCM notification to member: $memberId, Status code: ${response.statusCode}");
            }
          } else {
            print("FCM token not found for member: $memberId");
          }
        } else {
          print("User data not found in Firestore for member: $memberId");
        }
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  Future<void> sendSOSFCMNotification(String userId, String location) async {
    try {
      // Retrieve all circles where the current user is a member
      QuerySnapshot<Map<String, dynamic>> userCirclesSnapshot = await FirebaseFirestore.instance
          .collection('circles')
          .where('members', arrayContains: userId)
          .get();

      // Iterate through each circle
      for (QueryDocumentSnapshot<Map<String, dynamic>> circleDoc in userCirclesSnapshot.docs) {
        String circleName = circleDoc.id;

        // Extract the members list from the circle document data
        List<dynamic> members = circleDoc.data()['members'];

        // Send notification to each member of the circle
        String? currentUsername;

        // Retrieve current user's username
        DocumentSnapshot<Map<String, dynamic>> currentUserSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
        currentUsername = currentUserSnapshot.data()?['username'];

        if (currentUsername == null) {
          print("Current user's username not found in Firestore");
          return;
        }

        print("Current Username: $currentUsername");

        // Send notification to each member of the circle
        for (String memberId in members) {
          if (memberId != userId && currentUsername != null) { // Exclude the current user
            // Retrieve user document to get FCM token
            DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(memberId).get();

            if (userSnapshot.exists) {
              String? memberToken = userSnapshot.data()?['fcmToken'];

              if (memberToken != null) {
                // Prepare notification payload
                final message = {
                  "message": {
                    "token": memberToken,
                    "notification": {
                      "body": "$currentUsername is in danger at $location. Please call authorities (Circles: $circleName)",
                      "title": 'SOS RECORDING by $currentUsername',
                    },
                    "data": {
                      "route": "/circleDetails",
                      "circleName": circleName,
                      "click_action": "FLUTTER_NOTIFICATION_CLICK"
                    },
                    "android": {
                      "notification": {
                        "click_action": "FLUTTER_NOTIFICATION_CLICK",
                      }
                    },
                  },
                };

                // Prepare FCM request URL and authorization header
                final url = Uri.parse('https://fcm.googleapis.com/v1/projects/waspadafyp1/messages:send');
                final oauthToken = await retrieveOAuthToken(); // Retrieve OAuth token
                final authorization = 'Bearer $oauthToken';

                // Send FCM notification using HTTP POST request
                final response = await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authorization,
                  },
                  body: jsonEncode(message),
                );

                // Check response status code
                if (response.statusCode == 200) {
                  print("FCM notification sent successfully to member: $memberId");
                } else {
                  print("Failed to send FCM notification to member: $memberId, Status code: ${response.statusCode}");
                }
              } else {
                print("FCM token not found for member: $memberId");
              }
            } else {
              print("User data not found in Firestore for member: $memberId");
            }
          }
        }

      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  Future<String> downloadAndUploadCompressedImage(String imageUrl, String circleName, String fileName) async {
    // Download the image
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image from $imageUrl');
    }
    final imageBytes = response.bodyBytes;

    // Convert downloaded bytes to Uint8List (fix type mismatch)
    final imageList = imageBytes.toList(); // Convert to List<int> first
    final Uint8List compressedBytes = Uint8List.fromList(imageList);

    // Compress the image iteratively until size is under 1 MB
    final compressedFinalBytes = await _compressImageToTargetSize(compressedBytes, 720 * 720);

    // Upload the compressed image to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('circleevidence/$circleName/compressed_${fileName}');
    final uploadTask = storageRef.putData(compressedFinalBytes);

    // Get the download URL after upload
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<Uint8List> _compressImageToTargetSize(Uint8List imageBytes, int targetSize) async {

      final compressedList = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 480, // Adjust as needed (optional)
        minWidth: 640, // Adjust as needed (optional)
        quality: 50,
      );
      imageBytes = compressedList; // Now assigning Uint8List to Uint8List

    return imageBytes;
  }


  Future<void> sendFCMNotification(String senderId, String circleName, String content) async {
    try {
      // Retrieve the circle document
      DocumentSnapshot<Map<String, dynamic>> circleSnapshot =
      await FirebaseFirestore.instance.collection('circles').doc(circleName).get();

      if (!circleSnapshot.exists) {
        print("Circle document with name $circleName does not exist.");
        return;
      }

      // Send notification to each member of the circle
      String? currentUsername;

      // Retrieve current user's username
      DocumentSnapshot<Map<String, dynamic>> currentUserSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      currentUsername = currentUserSnapshot.data()?['username'];

      // Extract the members list from the circle document data
      List<dynamic> members = circleSnapshot.data()?['members'];

      // Filter out the sender's ID from the members list
      List<String> recipientIds = List<String>.from(members).where((memberId) => memberId != senderId).toList();

      // Retrieve FCM tokens for the recipients
      for (String memberId in recipientIds) {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (userSnapshot.exists) {
          // Extract the FCM token from the user document data
          String? memberToken = userSnapshot.data()?['fcmToken'];
          if (memberToken != null) {
            // Prepare notification payload
            final message = {
              "message": {
                "token": memberToken,
                "notification": {
                  "body": "$currentUsername: $content",
                  "title": circleName,
                },
                "data": {
                  "route": "/circleDetails",
                  "circleName": "$circleName",
                  "click_action": "FLUTTER_NOTIFICATION_CLICK"
                },
                "android": {
                  "notification": {
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                  }
                },
              },
            };


            // Prepare FCM request URL
            final url = Uri.parse('https://fcm.googleapis.com/v1/projects/waspadafyp1/messages:send');

            // Prepare authorization header
            final oauthToken = await retrieveOAuthToken(); // Retrieve OAuth token from Firestore or any other source
            final authorization = 'Bearer $oauthToken';

            // Send FCM notification using HTTP POST request
            final response = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authorization,
              },
              body: jsonEncode(message),
            );

            // Check response status code
            if (response.statusCode == 200) {
              print("FCM notification sent successfully to member: $memberId");
            } else {
              print("Failed to send FCM notification to member: $memberId, Status code: ${response.statusCode}");
            }
          } else {
            print("FCM token not found for member: $memberId");
          }
        } else {
          print("User data not found in Firestore for member: $memberId");
        }
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];

      List<String?> addressParts = [
        place.name,
        place.thoroughfare,
        place.subLocality,
        place.locality,
        place.postalCode,
        place.administrativeArea
      ];

      // Filter out null values and join the non-null values with commas
      String address = addressParts.where((part) => part != null && part.isNotEmpty).join(', ');
      print('${place.name}, ${place.isoCountryCode},${place.country},${place.postalCode},${place.administrativeArea},${place.subAdministrativeArea},${place.locality},${place.subLocality}, ${place.thoroughfare}, ${place.subThoroughfare}');

      return address;
    } catch (e) {
      print("Error getting address: $e");
      return null;
    }
  }

  Future<void> checkIn(String circleName, userId, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending Check In to Circle $circleName!'),
      ),
    );
    String location = await getLocation();
    String senderId = userId;
    Tuple2<double, double> coordinates = await getCoordinate();
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
    await sendFCMNotification(senderId, circleName, location);
  }

  Future<String> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    } catch (e) {
      return 'Failed to get location: $e';
    }
  }

  Future<Tuple2<double, double>> getCoordinate() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return Tuple2(position.latitude, position.longitude);
    } catch (e) {
      // Handle error
      throw Exception('Failed to get location: $e');
    }
  }

  void quickCapture(String circleName, String currentUserID, BuildContext context) async {
    File? mediaFile;
    String fileName = '${DateTime.now()}_${circleName}_${currentUserID}.jpg';
    print("fileName: $fileName");
    final XFile? image =
    await ImagePicker().pickImage(source: ImageSource.camera);
    mediaFile = File(image!.path);
    // Do something with the captured image
    if (mediaFile != null) {
      String location = await getLocation();
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String senderId = userId;
      Tuple2<double, double> coordinates = await getCoordinate();
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
      await generateFileSha256(mediaFile.path);

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

      String compressedUrl = await downloadAndUploadCompressedImage(mediaUrl, circleName, fileName);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending Quick Capture to Circle $circleName!'),
        ),
      );
      await sendFCMImageNotification(senderId, circleName, location, compressedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick Capture sent to Circle $circleName!'),
        ),
      );
    }
  }

  Future<String?> retrieveOAuthToken() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> oauthSnapshot =
      await FirebaseFirestore.instance.collection('token').doc('oauth').get();
      if (oauthSnapshot.exists) {
        return oauthSnapshot.data()?['oauth'];
      } else {
        print("OAuth token document not found in Firestore.");
        return null;
      }
    } catch (e) {
      print("Error retrieving OAuth token: $e");
      return null;
    }
  }

}

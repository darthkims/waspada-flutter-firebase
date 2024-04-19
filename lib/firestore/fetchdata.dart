import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FirestoreFetcher {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  // Retrieve current user data
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Retrieve user document from Firestore based on current user ID
        DocumentSnapshot userSnapshot = await firestore.collection('users').doc(currentUser.uid).get();

        if (userSnapshot.exists) {
          // Extract user data
          String fullName = userSnapshot['fullName'];
          String email = userSnapshot['email'];

          // Return user data
          return {'fullName': fullName, 'email': email};
        } else {
          // Handle case where user document doesn't exist
          return {'fullName': null, 'email': null};
        }
      } else {
        // Handle case where no user is signed in
        return {'fullName': null, 'email': null};
      }
    } catch (e) {
      // Handle errors
      print('Error fetching current user data: $e');
      return {'fullName': null, 'email': null};
    }
  }

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


  Future<void> uploadReport(String caseType, String location, File mediaFile, String city) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Generate SHA256 hash for the media file
      String hashKey = await generateFileSha256(mediaFile.path);
      DateTime date = DateTime.now();
      int flagsCount = 0;

      // Determine the file extension from the original file name
      String originalExtension = mediaFile.path.split('.').last;

      // Upload media file to Firebase Storage
      String fileName = '${DateTime.now()}_${caseType}_${currentUser.uid}.$originalExtension';
      print("fileName: $fileName");

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
        'flagsCount': flagsCount,
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
      final mediaRef = storage.ref().child('reportevidence/$mediaFileName.jpg');
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

  Future<void> toggleFlagReport(String documentId, String currentUserUid) async {
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
    // Implement logic to delete the circle with the given circleName
    // For example:
    FirebaseFirestore.instance.collection('circles').doc(circleName).delete();
  }

  Future<void> downloadImage(String url, String mediaFileName) async {
    print("1");
    final response = await http.get(Uri.parse(url));
    print("2");

    final directory = await getExternalStorageDirectory();

    if (directory == null) {
      print('Error: Failed to get directory.');
      return;
    }

    final dcimDirectory = Directory('${directory.path}/DCIM');
    if (!dcimDirectory.existsSync()) {
      dcimDirectory.createSync(recursive: true);
    }

    print("3");
    final file = File('${dcimDirectory.path}/$mediaFileName.jpg');
    print("4");

    try {
      await file.writeAsBytes(response.bodyBytes);
      print('Downloaded image to: ${file.path}');
    } catch (e) {
      print('Error saving file: $e');
      return;
    }
  }

}

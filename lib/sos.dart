import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({Key? key}) : super(key: key);

  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Timer _timer;
  int _elapsedSeconds = 0;
  String _currentLocation = '';
  bool _isOnline = false;
  final Connectivity connectivityResult = Connectivity();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirestoreFetcher firestoreFetcher = FirestoreFetcher();
  String location = '';
  late final GeoPoint coordinate;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _getCurrentLocation();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }


  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );
    // Initialize the camera controller
    await _controller.initialize();

    // Start recording
    _startTimer();
    await _controller.startVideoRecording();
    await firestoreFetcher.sendSOSFCMNotification(userId, _currentLocation);
    print('Start Recording');

    return;

  }

  Future<void> _stopAndSaveVideo() async {
    _timer.cancel();
      try {

        // Show circular progress indicator while saving and uploading video
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        XFile videoFile = await _controller.stopVideoRecording();
        // Get the current date and time
        DateTime now = DateTime.now();

// Format the current time
        String currentDate = DateFormat('ss-MM-dd-yyyy').format(now);
        String filename = "SOSRecording_$currentDate";

        // Upload the video file to Firebase Storage
        await _uploadToFirebaseStorage(File(videoFile.path));

        // Define the destination directory
        String destDirectory = '/storage/emulated/0/DCIM/Waspada';

        // Create the destination directory if it doesn't exist
        await Directory(destDirectory).create(recursive: true);

        // Define the destination path where you want to save the video
        String destPath = '$destDirectory/$filename.mp4';

        // Copy the video file to the destination path
        await videoFile.saveTo(destPath);

        print('Video saved to: $destPath');

        print('Stop Recording');
      } catch (e) {
        print('Error stopping video recording: $e');
        // Handle error appropriately
      }
  }

  Future<void> _uploadToFirebaseStorage(File video) async {
    try {
      DateTime date = DateTime.now();
      String filename = "${(DateTime.now()).toString()}_SOSRECORDING_$userId";
      final storage = FirebaseStorage.instance;
      final mediaRef = storage.ref().child('SOSRecording/$userId/$filename');
      print("mediaRef: $mediaRef");
      String hashKey = await firestoreFetcher.generateFileSha256(video.path);
      try {
        await mediaRef.putFile(video);
        print("Media file uploaded successfully");
      } catch (e) {
        // Handle errors
        print('Error uploading media file: $e');
      }

      // Get download URL of the uploaded media file
      final mediaUrl = await mediaRef.getDownloadURL();
      // Save report data to Firestore
      await firestore.collection('users').doc(userId).collection('SOSreports').add({
        'mediaUrl': mediaUrl,
        'videoName': filename,
        'timeStamp': date,
        'hashKey': hashKey,
        'location': location,
      });

      QuerySnapshot<Map<String, dynamic>> userCirclesSnapshot = await FirebaseFirestore.instance
          .collection('circles')
          .where('members', arrayContains: userId)
          .get();

      // Send message to all circles that contain the user
      for (var circleDoc in userCirclesSnapshot.docs) {
        await FirebaseFirestore.instance.collection('circles').doc(circleDoc.id).collection('messages').add({
          'fileName' : filename,
          'senderId': userId,
          'message': "SOS ALERT: ($location) (SHA256: $hashKey)",
          'location': coordinate,
          'timestamp': Timestamp.now(),
          'hashKey': hashKey,
          'mediaUrl': mediaUrl,
        });
      }

      print(mediaUrl);
    } catch (e) {
      print('Error uploading file to Firebase Storage: $e');
      // Handle error appropriately
    }
  }


  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatElapsedTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _getCurrentLocation() async {
    String offlineCoordinate = ''; // Define offlineCoordinate variable outside try block
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;
      coordinate = GeoPoint(latitude, longitude);
      location = "$latitude, $longitude";
      offlineCoordinate = '$latitude, $longitude'; // Update offlineCoordinate inside try block
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.name}, ${place.thoroughfare}';
        print("${place.name}, ${place.street}, ${place.locality}, ${place.subLocality}, ${place.street}, ${place.locality}");
        setState(() {
          _currentLocation = address;
        });
      } else {
        setState(() {
          _currentLocation = 'Address not found';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _currentLocation = '$offlineCoordinate'; // Use offlineCoordinate here
      });
    }
  }


  void _cancelAndUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Are you sure you want to exit and abort?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Home()), (route) => false);
          },
          child: const Text('Exit & Abort')
          ),
        ]
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          _cancelAndUpload();
        },
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: CameraPreview(_controller),
                  ),
                  Positioned(
                    top: 50,
                    right: 40,
                    child: _isOnline
                        ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20), // Adjust the radius to your preference
                      ),
                          child: const Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                        : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent, // Set color to red when offline
                        borderRadius: BorderRadius.circular(20), // Adjust the radius to your preference
                      ),
                          child: const Text('Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),


                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height / 3,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                bottomLeft: Radius.circular(20.0),
                              ),
                              child: Container(
                                color: const Color(0xFF66EEEE),
                                child: Center(
                                  child: Text(
                                    'Duration: ${_formatElapsedTime(_elapsedSeconds)}',
                                    style: const TextStyle(color: Colors.black, fontSize: 30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            color: const Color(0xFF20FFFF),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20.0),
                                    bottomRight: Radius.circular(20.0),
                                  ),
                                  child: Container(
                                    color: const Color(0xFF66EEEE),
                                    child: _currentLocation.isEmpty
                                        ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                        : Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                  _currentLocation,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all(Colors.blue),
                                            ),
                                            onPressed: () async {
                                              await _stopAndSaveVideo();
                                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Home()), (route) => false);
                                              print("uploaded");
                                            },
                                            child: const Text(
                                              'Upload',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 25,),
                                        Center(
                                          child: ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all(Colors.red),
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Exit and Abort?'),
                                                    content: const Text('Exit and Abort current SOS Recording?'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          child: const Text('Cancel')
                                                      ),
                                                      TextButton(
                                                          onPressed: () {
                                                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Home()), (route) => false);
                                                          },
                                                          child: const Text('Exit & Abort')
                                                      ),
                                                    ],
                                                  )
                                              );
                                              print("Exit & Abort");
                                            },
                                            child: const Text(
                                              'Exit & Abort',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class SOSAudioPage extends StatefulWidget {
  const SOSAudioPage({super.key});

  @override
  State<SOSAudioPage> createState() => _SOSAudioPageState();
}

class _SOSAudioPageState extends State<SOSAudioPage> {
  late AudioRecorder audioRecord;
  bool isRecording = false;
  late Timer _timer;
  int _elapsedSeconds = 0;
  String audioPath = '';
  String location = '';
  late final GeoPoint coordinate;
  String _currentLocation = '';
  String formattedTime = '';
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String currentDate = '';
  final FirestoreFetcher firestoreFetcher = FirestoreFetcher();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    _getCurrentLocation();
    audioRecord = AudioRecorder();

    // Start periodic timer to update time every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTime();
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    audioRecord.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    String offlineCoordinate = ''; // Define offlineCoordinate variable outside try block
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;
      location = "$latitude, $longitude";
      coordinate = GeoPoint(latitude, longitude);
      offlineCoordinate = '$latitude, $longitude'; // Update offlineCoordinate inside try block
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.name}, ${place.thoroughfare}, ${place.locality}, ${place.postalCode}, ${place.administrativeArea}';
        print("${place.name}, ${place.street}, ${place.locality}, ${place.subLocality}, ${place.street}, ${place.locality}");
        setState(() {
          _currentLocation = address;
        });
      } else {
        setState(() {
          _currentLocation = 'Address not found';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _currentLocation = '$offlineCoordinate'; // Use offlineCoordinate here
      });
    }
  }

  void updateTime() {
    setState(() {
      // Update current time
      DateTime now = DateTime.now();
      formattedTime = DateFormat('hh:mm:ss a').format(now);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatElapsedTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> startRecording() async {
    firestoreFetcher.sendSOSFCMNotification(userId, _currentLocation);
    DateTime now = DateTime.now();
    currentDate = DateFormat('HH:mm:ss-MM-dd-yyyy').format(now);
    _startTimer();
    final appDir = await getExternalStorageDirectory();
    String _filePath = '${appDir?.path}/SOSAudio_$currentDate.mp3';
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start(const RecordConfig(), path: _filePath);
        print(_filePath);
        setState(() {
          isRecording = true;
        });
      }
    }
    catch (e) {
      print('Error Start Recording: $e');
    }
  }

  bool uploading = false;

  Future<void> stopRecording() async {
    setState(() {
      uploading = true;
    });

    _timer.cancel();
    try {
      DateTime date = DateTime.now();
      // Stop recording
      await audioRecord.stop();

      // Get reference to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance.ref();

      // Get external storage directory
      final appDir = await getExternalStorageDirectory();

      // Define file path
      String audioPath = '${appDir?.path}/SOSAudio_$currentDate.mp3';

      // Get file bytes
      File audioFile = File(audioPath);
      List<int> audioBytes = await audioFile.readAsBytes();

      // Convert list of integers to Uint8List
      Uint8List uint8List = Uint8List.fromList(audioBytes);
      String fileName = '${currentDate}_SOSAudioRecording_${userId}';
      // Upload file to Firebase Storage
      String firebaseStoragePath = 'SOSAudioRecording/$userId/$fileName'; // Define path in Firebase Storage
      UploadTask uploadTask = storageRef.child(firebaseStoragePath).putData(uint8List, SettableMetadata(contentType: 'audio/mpeg'));

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {
        print('File uploaded to Firebase Storage');
      });

      String mediaUrl = await storageRef.child(firebaseStoragePath).getDownloadURL();
      String hashKey = await firestoreFetcher.generateFileSha256(audioPath);

      await firestore.collection('users').doc(userId).collection('SOSAudioreports').add({
        'mediaUrl': mediaUrl,
        'videoName': fileName,
        'timeStamp': date,
        'hashKey': hashKey,
        'location': location,
      });

      QuerySnapshot<Map<String, dynamic>> userCirclesSnapshot = await FirebaseFirestore.instance
          .collection('circles')
          .where('members', arrayContains: userId)
          .get();

      // Send message to all circles that contain the user
      for (var circleDoc in userCirclesSnapshot.docs) {
        await FirebaseFirestore.instance.collection('circles').doc(circleDoc.id).collection('messages').add({
          'fileName' : fileName,
          'senderId': userId,
          'message': "SOS ALERT: ($location) (SHA256: $hashKey)",
          'location': coordinate,
          'timestamp': Timestamp.now(),
          'hashKey': hashKey,
          'mediaUrl': mediaUrl,
        });
      }

      // Navigate back to home screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));

      setState(() {
        isRecording = false;
        uploading = false;
      });
    } catch(e) {
      print('Error Stopping Record: $e');
      setState(() {
        uploading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd MMMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOS Audio Recorder',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isRecording)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Text('Duration: ${_formatElapsedTime(_elapsedSeconds)}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                ),
              const SizedBox(height: 20,),

              if (isRecording)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Row(

                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic, // Choose the icon you want to use
                        color: Colors.white,
                        size: 25,
                      ),
                      SizedBox(width: 5), // Adding some space between icon and text
                      Text(
                        'Recording audio',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                ),
              const SizedBox(height: 20,),
              // Container to display location details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$formattedDate - $formattedTime',
                      style: const TextStyle(fontSize: 16,),
                    ),
                    const Text(
                      'Location:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_currentLocation',
                      style: const TextStyle(fontSize: 16,),
                    ),
                    const Text(
                      'Coordinate:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$location',
                      style: const TextStyle(fontSize: 16,),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () {
                  if (isRecording) {
                    stopRecording();
                  } else {
                    startRecording();
                  }
                },
                child: isRecording ? const Text('Stop & Upload Recording', style: TextStyle(color: Colors.white),) : const Text('Start Recording', style: TextStyle(color: Colors.white),),
              ),
              if (uploading) const CircularProgressIndicator(), // Display circular progress indicator if uploading is true

              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


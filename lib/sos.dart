import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fypppp/home.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _startTimer();
    _getCurrentLocation();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      setState(() {
        print("ONLINE");
        _isOnline = true;
      });
    } else {
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );
    return _controller.initialize();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
      offlineCoordinate = '$latitude, $longitude'; // Update offlineCoordinate inside try block
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.street}';
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
        title: Text("Confirmation"),
        content: Text("Are you sure you want to cancel and upload?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home()), (route) => false);
              print("cancelled and uploaded");
              },
            child: Text("Upload"),
          ),
        ],
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20), // Adjust the radius to your preference
                      ),
                      child: Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                        : Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent, // Set color to red when offline
                        borderRadius: BorderRadius.circular(20), // Adjust the radius to your preference
                      ),
                      child: Text('Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),


                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height / 3,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                bottomLeft: Radius.circular(20.0),
                              ),
                              child: Container(
                                color: Color(0xFF66EEEE),
                                child: Center(
                                  child: Text(
                                    'Duration: ${_formatElapsedTime(_elapsedSeconds)}',
                                    style: TextStyle(color: Colors.black, fontSize: 30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            color: Color(0xFF20FFFF),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20.0),
                                    bottomRight: Radius.circular(20.0),
                                  ),
                                  child: Container(
                                    color: Color(0xFF66EEEE),
                                    child: _currentLocation.isEmpty
                                        ? Center(
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
                                          child: Text(
                                            'Location:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 30,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                  _currentLocation,
                                              style: TextStyle(
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
                                              backgroundColor: MaterialStateProperty.all(Colors.red),
                                            ),
                                            onPressed: _cancelAndUpload,
                                            child: Text(
                                              'Cancel & Upload',
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
              return Center(
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

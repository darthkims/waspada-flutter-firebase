import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fypppp/casesaround.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/offlinehome.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/settings.dart';
import 'package:fypppp/sos.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fypppp/reportcase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}


class _HomeState extends State<Home> {
  late MapController mapController;
  LatLng _currentLocation = const LatLng(2.224388, 102.456645); // Default location
  int currentPageIndex = 0; // Index of the currently selected item
  List<Marker> _markers = []; // List to hold dynamic markers
  List<Map<String, dynamic>> _markerInfoList = [];
  late StreamSubscription<Position> _positionStreamSubscription;
  bool _shouldCenterMap = true; // Flag to determine if the map should be initially centered
  final CasesAround casesAround = CasesAround();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          if (_shouldCenterMap) {
            mapController.move(_currentLocation, 19.0);
            _shouldCenterMap = false; // Set to false after initial centering
          }
          print("$_currentLocation");
        });
      }
    });
    addDynamicMarkersFromFirestore();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel(); // Cancel the subscription to avoid memory leaks
    super.dispose();
  }

  Future<void> _getLocation() async {
    // Check if location permission is granted
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Location permission granted, proceed to get the current position
      if (mounted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          mapController.move(_currentLocation, 19.0);
          print("$_currentLocation");
        });
      }
    } else {
    }
  }

  void onItemTapped(int index) {
    setState(() {
      // _selectedIndex = index;
      switch (index) {
        case 0:
        // Handle Home navigation (already on Home page)
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
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                return const Circles();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
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

  Future<void> addDynamicMarkersFromFirestore() async {
    try {
      // Access the Firestore collection containing reports
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('reports').get();

      // Iterate through the documents in the collection
      querySnapshot.docs.forEach((doc) {
        // Extract the 'location' field from each document
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('location')) {
          // Extract latitude and longitude from the 'location' field
          String locationString = data['location'] as String;
          Timestamp timestamp = data['timeStamp'];
          String caseType = data['caseType'];
          String url = data['mediaUrl'];
          String mediaFileName = data['mediaFileName'];
          String? description;
          try {
            description = data['description'] as String?;
            if (description!.isEmpty) {
              description = "No description available";
            }
          } catch (error) {
            description = "No description available";
          }

          // Split the location string by comma to get latitude and longitude
          List<String> parts = locationString.split(',');

          double latitude = double.tryParse(parts[0].trim()) ?? 0.0;
          double longitude = double.tryParse(parts[1].trim()) ?? 0.0;
          String formattedDate = DateFormat('dd MMMM yyyy').format(timestamp.toDate());
          String formattedTime = DateFormat('hh:mm a').format(timestamp.toDate());

          calculateDistance(latitude, longitude, formattedDate, caseType, formattedTime, url, mediaFileName, description);
          // Call _addDynamicMarker with the location
          _addDynamicMarker(latitude, longitude, formattedDate, caseType, description, formattedTime, url, mediaFileName);
        }
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching locations from Firestore: $e');
    }
  }

  Future<void> calculateDistance(double latitude, double longitude, String date, String caseType, String time, String url, String mediaFileName, String description) async {
    // LatLng point = LatLng(latitude, longitude);
    final prefs = await SharedPreferences.getInstance();
    final int distanceAlert = prefs.getInt('distanceAlert') ?? 1;
    print('Distance Alert: $distanceAlert');
    // int _duration = 10000;
    // double _minHeight = 80;
    double distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      latitude,
      longitude,
    )/1000;
    print('Distance: $distance');
    // if (distance < distanceAlert) {
    //   try {
    //     InAppNotification.show(
    //       child: NotificationBody(
    //         caseType: caseType,
    //         minHeight: _minHeight,
    //       ),
    //       context: context,
    //       onTap: () {
    //         mapController.move(point, 19.0);
    //       },
    //       duration: Duration(milliseconds: _duration),
    //     );
    //   } catch (e) {
    //     print('Error calculate distance:  $e');
    //   }
    // };
  }

  void _addDynamicMarker(double latitude, double longitude, String date, String caseType, String description, String time, String url, String mediaFileName) {
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
    setState(() {
      // Add marker information to the list
      _markerInfoList.add({
        'latitude': latitude,
        'longitude': longitude,
        'date': date,
        'caseType': caseType,
        'description': description,
        'time': time,
      });
      // Add a dynamic marker to the map
      _markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          child: GestureDetector(
            onTap: () async {
              String? address = await getAddressFromCoordinates(latitude, longitude);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(caseType, style: const TextStyle(fontWeight: FontWeight.bold),),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Ensure the column takes minimum space
                        children: [
                          if (mediaFileName.endsWith('jpg'))
                            Image.network(
                              url,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                }
                              },
                            ),
                          if (mediaFileName.endsWith('mp4'))
                            GestureDetector(
                              onTap: () async {
                                  Uri uri = Uri.parse(url);
                                  // Create a VideoPlayerController instance
                                  final videoPlayerController = VideoPlayerController.networkUrl(uri);

                                  // Initialize the controller and display a loading indicator while it loads
                                  await videoPlayerController.initialize().then((_) {
                                    // Once initialized, show the video in a dialog
                                    _showVideoDialog(context, videoPlayerController);
                                  });
                              },
                              child: SizedBox(
                                child: Image.asset('assets/images/thumbnailvideo_horizontal.png'),
                              ),
                            ),
                          const SizedBox(height: 8), // Add some spacing between text items
                          Text('Description: $description'),
                          const SizedBox(height: 8), // Add some spacing between text items
                          Text('Address: $address'),
                          const SizedBox(height: 8), // Add some spacing between text items
                          Text('Date: $date'),
                          const SizedBox(height: 8), // Add some spacing between text items
                          Text('Time: $time'),
                        ],
                      ),
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

            },
            child: const Icon(Icons.warning, size: 50, color: Colors.red),
          ),
          rotate: true,
        ),
      );
    });
  }

  Future<void> _showMarkersList() async {
    final prefs = await SharedPreferences.getInstance();
    final int distanceAlert = prefs.getInt('distanceAlert') ?? 1;
    print('Distance Alert: $distanceAlert');

    // Sort the marker info list by distance
    _markerInfoList.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        a['latitude'],
        a['longitude'],
      );
      double distanceB = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        b['latitude'],
        b['longitude'],
      );
      return distanceA.compareTo(distanceB);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Filter _markerInfoList based on distance condition
        List<Map<String, dynamic>> filteredList = _markerInfoList.where((data) {
          double latitude = data['latitude'];
          double longitude = data['longitude'];
          double distance = Geolocator.distanceBetween(
            _currentLocation.latitude,
            _currentLocation.longitude,
            latitude,
            longitude,
          ) / 1000; // Convert to kilometers

          return distance < distanceAlert; // Only include if distance is less than distanceAlert
        }).toList();

        if (filteredList.isEmpty) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Reported Cases', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
              height: 100, // Adjust height as needed
              width: 200,
              child: Center(
                child: Text('There are no reported cases within ${distanceAlert.toStringAsFixed(2)} KM. Change the distance alert on Settings/Preferences page to view more cases.'),
              ),
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
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reported Cases', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(0),
            height: 300, // Adjust height as needed
            width: 400,
            child: SingleChildScrollView(
              child: Scrollbar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredList.map((data) {
                    double latitude = data['latitude'];
                    double longitude = data['longitude'];
                    String caseType = data['caseType'];
                    String description = data['description'];
                    double distance = Geolocator.distanceBetween(
                      _currentLocation.latitude,
                      _currentLocation.longitude,
                      latitude,
                      longitude,
                    ) / 1000; // Convert to kilometers

                    bool isKm = true;
                    double shownDistance = distance;
                    if (distance < 1) {
                      shownDistance = distance * 1000;
                      isKm = false;
                    }

                    LatLng point = LatLng(latitude, longitude);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: const EdgeInsets.all(5),
                      child: ListTile(
                        title: Text(
                          caseType,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: distance < distanceAlert ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: TextStyle(color: Colors.white,),
                            ),
                            Text(
                              'Distance: ${isKm ? '${shownDistance.toStringAsFixed(2)} KM' : '${shownDistance.toStringAsFixed(2)} meter'}',
                              style: TextStyle(color: Colors.white,),
                            ),
                          ],
                        ),
                        onTap: () {
                          mapController.move(point, 19.0);
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
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
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/darthkims/clulut7s900q401r2fbvm05ta/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZGFydGhraW1zIiwiYSI6ImNscWppYWEzNzFram8ya21temU5cDdmN3kifQ.AhgO7e5wWPUR1KCKHiqBwg',
                userAgentPackageName: 'com.example.app',
                additionalOptions: {
                  'accessToken' : 'pk.eyJ1IjoiZGFydGhraW1zIiwiYSI6ImNscWppYWEzNzFram8ya21temU5cDdmN3kifQ.AhgO7e5wWPUR1KCKHiqBwg',
                  'id' : 'mapbox.cluluqvrw00ut01r56i0e1sre'
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: const Icon(Icons.navigation_rounded, size: 50, color: Colors.blue,),
                    rotate: true,
                  ),
                  ..._markers,
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 36.0,
            right: 16.0,
            child: SizedBox(
              height: 60.0, // Adjust height and width as needed
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  heroTag: UniqueKey(),
                  onPressed: _getLocation,
                  tooltip: 'Locate Me',
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120.0,
            right: 16.0,
            child: SizedBox(
              height: 60.0, // Adjust height and width as needed
              width: 60.0,
              child: FittedBox(
                child: SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  animatedIconTheme: const IconThemeData(color: Colors.white),
                  backgroundColor: Colors.blue,
                  overlayColor: Colors.black,
                  overlayOpacity: 0.5,
                  spaceBetweenChildren: 5,
                  spacing: 5,
                  children: [
                    SpeedDialChild(
                      child: const Icon(Icons.offline_bolt_outlined, color: Colors.white,),
                      backgroundColor: Colors.lightBlueAccent,
                      label: 'Offline Mode',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OfflineHome())
                        );
                      },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.settings, color: Colors.white,),
                      backgroundColor: Colors.lightBlueAccent,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage())
                        );
                        },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.notifications, color: Colors.white,),
                      backgroundColor: Colors.lightBlueAccent,
                      label: 'Notifications',
                      onTap: () {
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(builder: (context) => NotificationPage())
                        // );
                      },
                    ),
                    SpeedDialChild(
                      child: const Icon(Icons.flag, color: Colors.white,),
                      backgroundColor: Colors.lightBlueAccent,
                      label: 'Report Case',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportCase()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100.0,
            right: 16.0,
            child: SizedBox(
              height: 60.0, // Adjust height and width as needed
              width: 60.0,
              child: FittedBox(
                child: FloatingActionButton(
                  backgroundColor: Colors.yellow,
                  heroTag: UniqueKey(),
                  onPressed: _showMarkersList,
                  tooltip: 'Show Markers',
                  child: const Icon(Icons.warning_amber, size: 35,),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SizedBox(
        width: 90,
        height: 90,
        child: FloatingActionButton(
          heroTag: UniqueKey(),
          backgroundColor: Colors.red,
          onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SOSAudioPage(),
                  ),
                );
          },
          child: const Icon(Icons.sos, size: 70, color: Colors.white),
          shape: const CircleBorder(),
        ),

      ),
      bottomNavigationBar: CustomNavigationBar(currentPageIndex: currentPageIndex, onItemTapped: onItemTapped)
    );
  }
}

void _showVideoDialog(BuildContext context, VideoPlayerController videoPlayerController) async {
  try {

    // Initialize video player
    await videoPlayerController.initialize();
    videoPlayerController.setLooping(true);
    // Show video player dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: videoPlayerController.value.aspectRatio,
                child: VideoPlayer(videoPlayerController),
              ),
              Positioned(
                top: 0.0,
                right: 0.0,
                child: GestureDetector(
                  onTap: () {
                    if (videoPlayerController.value.isPlaying) {
                      videoPlayerController.pause();
                    } else {
                      videoPlayerController.play();
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36.0,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,),
                        color: Colors.white,
                        onPressed: () {
                          Navigator.of(context).pop();
                          videoPlayerController.dispose();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Start playback after showing dialog
    videoPlayerController.play();
  } catch (error) {
    // Handle initialization error (optional)
    print('Error initializing video: $error');
  }
}
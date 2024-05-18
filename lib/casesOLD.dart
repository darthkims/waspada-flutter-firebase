import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/profileedit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CasesAround extends StatefulWidget {
  const CasesAround({super.key});

  @override
  _CasesAroundState createState() => _CasesAroundState();
}

class _CasesAroundState extends State<CasesAround> {
  late Position _userPosition;
  late bool _isLoading = true;
  int currentPageIndex = 2;

  void onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Home()));
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Circles()));
          break;
        case 2:

          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfileEditPage())); // Assuming Profile page
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userPosition = position;
        _isLoading = false; // Set loading to false once position is obtained
      });
    } catch (e) {
      print("Error getting user location: $e");
      setState(() {
        _isLoading = false; // Set loading to false in case of error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cases Around',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNearbyReportContainer(),
            Divider(),
            Expanded(
              child: _buildRefreshableReportList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                  (Set<MaterialState> states) => states.contains(MaterialState.selected)
                  ? const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                  : const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)

          ),
        ),
        child: NavigationBar(
          height: 75,
          backgroundColor: Colors.blue,
          // onDestinationSelected: _onItemTapped, // Use _onItemTapped for selection
          indicatorColor: Colors.white,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: ImageIcon(
                AssetImage('assets/images/appicon.png'), size: 30, // Replace with your image path
              ),
              icon: ImageIcon(
                AssetImage('assets/images/appicon.png',), size: 30, color: Colors.white, // Replace with your image path
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
              icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
              label: 'Circles', // Empty label for a cleaner look (optional)
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings_input_antenna_outlined, size: 30,),
              icon: Icon(Icons.settings_input_antenna, color: Colors.white, size: 30,),
              label: 'Cases Around',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
              icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
              label: 'Profile', // Empty label for a cleaner look (optional)
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNearbyReportContainer() {
    return Container(
      padding: EdgeInsets.all(16.0),
      alignment: Alignment.center,
      color: Colors.blue.withOpacity(0.1),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show indicator while data is loading
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // Convert QuerySnapshot to List for calculations
          List<DocumentSnapshot> documents = snapshot.data!.docs;

          // Count reports within 1km distance
          int nearbyReportsCount = documents.where((document) {
            String location = document['location'] as String;
            double distanceInMeters = Geolocator.distanceBetween(
              _userPosition.latitude,
              _userPosition.longitude,
              double.parse(location.split(',')[0]),
              double.parse(location.split(',')[1]),
            );
            return distanceInMeters <= 1000;
          }).length;

          return Text(
            'Number of reports nearby: $nearbyReportsCount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          );
        },
      ),
    );
  }


  Widget _buildRefreshableReportList() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: _buildReportList(),
    );
  }

  Widget _buildReportList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        // Convert QuerySnapshot to List for sorting
        List<DocumentSnapshot> documents = snapshot.data!.docs;

        // Sort reports by distance to the user
        documents.sort((a, b) {
          String locationA = a['location'] as String;
          String locationB = b['location'] as String;

          double distanceA = Geolocator.distanceBetween(
            _userPosition.latitude,
            _userPosition.longitude,
            double.parse(locationA.split(',')[0]),
            double.parse(locationA.split(',')[1]),
          );

          double distanceB = Geolocator.distanceBetween(
            _userPosition.latitude,
            _userPosition.longitude,
            double.parse(locationB.split(',')[0]),
            double.parse(locationB.split(',')[1]),
          );

          return distanceA.compareTo(distanceB);
        });

        return ListView(
          children: documents.map((document) {
            String documentId = document.id; // This line retrieves the document ID
            FirestoreFetcher _firestoreFetcher = FirestoreFetcher();
            String? caseType = (document.data() as Map<String, dynamic>)['caseType'] as String?;
            Timestamp? timestamp = (document.data() as Map<String, dynamic>)['timeStamp'] as Timestamp?;
            String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp!.toDate());
            String? location = (document.data() as Map<String, dynamic>)['location'] as String?;
            User? user = FirebaseAuth.instance.currentUser; // Get the current user

            List<String> locationParts = location!.split(',');
            double latitude = double.parse(locationParts[0]);
            double longitude = double.parse(locationParts[1]);
            String? imageUrl = (document.data() as Map<String, dynamic>)['mediaUrl'] as String?;
            String? mediaFileName = (document.data() as Map<String, dynamic>)['mediaFileName'] as String?;
            Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
              List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
              Placemark place = placemarks[0];
              return "${place.name}, ${place.thoroughfare}, ${place.locality}, ${place.postalCode}, ${place.administrativeArea}";
            }

            Widget imageWidget = imageUrl != null
                ? Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
                : Container();

            double distanceInMeters = Geolocator.distanceBetween(
              _userPosition.latitude,
              _userPosition.longitude,
              latitude,
              longitude,
            );

            String distance = "${(distanceInMeters / 1000).toStringAsFixed(2)}KM";
            Color containerColor = distanceInMeters <= 1000 ? Colors.red : Color(0xFF66EEEE);

            return Container(
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caseType!,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue,),
                              Text(
                                distance,
                                style: TextStyle(
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formattedDateTime,
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min, // Ensure the Column only occupies the space it needs
                                children: <Widget>[
                                  SizedBox(height: 10,),
                                  ListTile(
                                    leading: Icon(
                                      Icons.download,
                                      size: 36, // Adjust the size of the icon
                                    ),
                                    title: Text(
                                      'Download Image',
                                      style: TextStyle(fontSize: 20), // Adjust the font size
                                    ),
                                    onTap: () {
                                      _firestoreFetcher.downloadImage(imageUrl!, mediaFileName!);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  SizedBox(height: 10,),
                                  ListTile(
                                    leading: Icon(
                                      Icons.info_outline,
                                      size: 36, // Adjust the size of the icon
                                    ),
                                    title: Text(
                                      'See details',
                                      style: TextStyle(fontSize: 20), // Adjust the font size
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ListTile(
                                                  title: Center(
                                                      child: Text(
                                                        "$caseType",
                                                        style: TextStyle(
                                                            fontSize: 30, fontWeight: FontWeight.bold),
                                                      )
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Distance',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  '$distance',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                FutureBuilder(
                                                  future: getAddressFromCoordinates(latitude, longitude),
                                                  builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                                                    if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                                      return SizedBox.shrink(); // Return empty space while waiting for address
                                                    }
                                                    if (addressSnapshot.hasError || addressSnapshot.data == null) {
                                                      return SizedBox.shrink(); // Return empty space if there's an error or no address
                                                    }
                                                    return Text(
                                                      addressSnapshot.data!,
                                                      style: TextStyle(fontSize: 20),
                                                    );
                                                  },
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Coordinate',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  '$location',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Date & Time',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  '$formattedDateTime',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Evidence',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    _showImageDialog(context, imageUrl!);
                                                  },
                                                  child: imageWidget,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  SizedBox(height: 10,),
                                ],
                              );
                            },
                          );
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _showImageDialog(context, imageUrl!);
                    },
                    child: imageWidget,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.flag_outlined),
                        onPressed: () async {
                          await _firestoreFetcher.toggleFlagReport(documentId, user!.uid);
                        },
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('reports').doc(documentId).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('0 Flags');
                          }
                          if (!snapshot.hasData) {
                            return Text('0');
                          }
                          final flagsCount = snapshot.data!['flagsCount'] ?? 0;
                          return Text('$flagsCount Flags', style: TextStyle(fontSize: 15,),);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

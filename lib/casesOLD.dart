import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class CasesAround extends StatefulWidget {
  const CasesAround({Key? key});

  @override
  _CasesAroundState createState() => _CasesAroundState();
}

class _CasesAroundState extends State<CasesAround> {
  late Position _userPosition;
  bool _isLoading = true; // Variable to track loading state
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    setState(() {
      _isLoading = true; // Set loading state to true while fetching location
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userPosition = position;
        _isLoading = false; // Set loading state to false after fetching location
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading state to false in case of error
      });
      print("Error getting user location: $e");
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
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          _buildNearbyReportContainer(),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: _buildReportList(),
            ),
          ),
        ],
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
            return CircularProgressIndicator();
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

  Widget _buildReportList() {

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Convert QuerySnapshot to List for sorting
        List<DocumentSnapshot> documents = snapshot.data!.docs;

        // Sort reports by distance from the user
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
            return FutureBuilder<Widget>(
              future: _buildReportWidget(document),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return snapshot.data!;
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<Widget> _buildReportWidget(DocumentSnapshot document) async {
    String documentId = document.id; // This line retrieves the document ID
    String? caseType = document['caseType'] as String?;
    Timestamp? timestamp = document['timeStamp'] as Timestamp?;
    String formattedDateTime =
    DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp!.toDate());
    String? location = document['location'] as String?;
    String? imageUrl = document['mediaUrl'] as String?;
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    // Convert coordinates to location name
    String locationName = 'Unknown';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        double.parse(location!.split(',')[0]),
        double.parse(location.split(',')[1]),
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        locationName =
        '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      print('Error getting location name: $e');
    }

    double distanceInMeters = Geolocator.distanceBetween(
      _userPosition.latitude,
      _userPosition.longitude,
      double.parse(location!.split(',')[0]),
      double.parse(location.split(',')[1]),
    );
    double distanceInKm = distanceInMeters / 1000;
    String formattedDistance = distanceInKm.toStringAsFixed(2) + ' km';

    // Conditionally apply color to the report container
    Color containerColor =
    distanceInKm <= 1 ? Colors.red : Color(0xFF66EEEE);

    return Future.value(Container(
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
          Text(
            caseType!,
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$locationName',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.blue,
              ),
              Text(
                '$formattedDistance',
                style: TextStyle(
                  fontSize: 15,
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
          SizedBox(height: 10),
          imageUrl != null
              ? Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          )
              : Container(),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.flag_outlined),
                onPressed: () async {
                  await _firestoreFetcher.toggleFlagReport(documentId, user!.uid);
                },
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .doc(documentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('0 Flags');
                  }
                  if (!snapshot.hasData) {
                    return Text('0');
                  }
                  final flagsCount = snapshot.data!['flagsCount'] ?? 0;
                  return Text(
                    '$flagsCount Flags',
                    style: TextStyle(fontSize: 17),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ));
  }

}

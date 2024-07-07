import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class CasePreview extends StatelessWidget {
  final String documentId;

  const CasePreview({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report Case Preview",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('reports').doc(documentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Document does not exist'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var imageUrl = data['mediaUrl'] ?? '';
          var title = data['caseType'] ?? '';
          var description = data['description'] ?? '';
          var timestamp = data['timeStamp'] as Timestamp;
          var date = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp.toDate());
          var location = data['location'] ?? '';

          List<String> locationParts = location.split(',');
          double latitude = double.parse(locationParts[0]);
          double longitude = double.parse(locationParts[1]);

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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 8, top: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blue,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                              title,
                            style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Description ",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          description,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Date ",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          date,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Location ",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder(
                          future: getAddressFromCoordinates(latitude, longitude),
                          builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                            if (addressSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink(); // Return empty space while waiting for address
                            }
                            if (addressSnapshot.hasError || addressSnapshot.data == null) {
                              return const SizedBox.shrink(); // Return empty space if there's an error or no address
                            }
                            return Text(
                              addressSnapshot.data!,
                              style: TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

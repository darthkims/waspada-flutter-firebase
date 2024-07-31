import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CasePreview extends StatelessWidget {
  final String documentId;

  const CasePreview({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {

    FirestoreFetcher firestoreFetcher = FirestoreFetcher();
    Color content = Colors.black;

    return Scaffold(
      backgroundColor: Color(0xFFF4F3F2),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          "Report Case Preview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
          if (description == '')
            description = "No Description Available";
          var timestamp = data['timeStamp'] as Timestamp;
          var date = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp.toDate());
          var location = data['location'] ?? '';

          List<String> locationParts = location.split(',');
          double latitude = double.parse(locationParts[0]);
          double longitude = double.parse(locationParts[1]);

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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                              title,
                            style: TextStyle(fontSize: 30, color: content, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Description ",
                          style: TextStyle(color: content, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          description,
                          style: TextStyle(color: content),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Date ",
                          style: TextStyle(color: content, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          date,
                          style: TextStyle(color: content),
                        ),
                        SizedBox(height: 10,),
                        Text(
                          "Location ",
                          style: TextStyle(color: content, fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder(
                          future: firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
                          builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                            if (addressSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink(); // Return empty space while waiting for address
                            }
                            if (addressSnapshot.hasError || addressSnapshot.data == null) {
                              return const SizedBox.shrink(); // Return empty space if there's an error or no address
                            }
                            return Text(
                              addressSnapshot.data!,
                              style: TextStyle(color: content),
                            );
                          },
                        ),
                        Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(Radius.circular(15))),
                                child: IconButton(
                                    onPressed: () async {
                                      String googleMapsUrl = "https://www.google.com/maps?q=@$latitude,$longitude,17z";
                                      Uri link = Uri.parse(
                                          googleMapsUrl);
                                      if (await canLaunchUrl(
                                          link)) {
                                        await launchUrl(link);
                                      } else {
                                        throw 'Could not launch $googleMapsUrl';
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                    )),
                              ),
                              const SizedBox(width: 10,),
                              Container(
                                margin:
                                const EdgeInsets.symmetric(vertical: 5),
                                decoration: const BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.all(Radius.circular(15))),
                                child: IconButton(
                                    onPressed: () async {
                                      firestoreFetcher.downloadImage(imageUrl, imageUrl);
                                    },
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                    )
                                ),
                              ),
                            ],
                          ),
                        )
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

import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addreport.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fypppp/firestore/fetchdata.dart';

class ReportCase extends StatefulWidget {
  const ReportCase({Key? key}) : super(key: key);

  @override
  _ReportCaseState createState() => _ReportCaseState();
}

class _ReportCaseState extends State<ReportCase> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher(); // Instantiate FirestoreFetcher


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Case',
          style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white), // Set the leading icon color to white
    ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddReport()),
                    );
                  },
                  child: Text(
                    'Add Report',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  onPressed: () {
                    // Handle button 2 press
                  },
                  child: Text(
                    'Rate Report',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // Add space between buttons and text
            Text(
              'Your Reports',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Expanded(
              child: _buildRefreshableReportList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshableReportList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement your refresh logic here, such as fetching new data from Firestore
        // For example, refetch data from Firestore
        setState(() {}); // This will rebuild the FutureBuilder which in turn rebuilds the report list
      },
      child: _buildReportList(),
    );
  }

  // Modify the _buildReportList method
  Widget _buildReportList() {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user == null) {
      return Center(
        child: Text('User not logged in'), // Handle case where user is not logged in
      );
    }

    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('reports')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timeStamp', descending: true) // Order by timestamp in descending order
          .get(),      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
        return ListView(
          children: snapshot.data!.docs.map((document) {
            String documentId = document.id; // This line retrieves the document ID
            String? caseType = (document.data() as Map<String, dynamic>)['caseType'] as String?;
            Timestamp? timestamp = (document.data() as Map<String, dynamic>)['timeStamp'] as Timestamp?;
            String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp!.toDate());
            String? location = (document.data() as Map<String, dynamic>)['location'] as String?;

// Split the location string into latitude and longitude
            List<String> locationParts = location!.split(',');
            double latitude = double.parse(locationParts[0]);
            double longitude = double.parse(locationParts[1]);
            String? imageUrl = (document.data() as Map<String, dynamic>)['mediaUrl'] as String?;
            String? mediaFileName = (document.data() as Map<String, dynamic>)['mediaFileName'] as String?;

            // Convert coordinates to human-readable address
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

            return GestureDetector(
              onTap: () {
                _showImageDialog(context, imageUrl!);
              },
              child: Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Color(0xFF66EEEE),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caseType!,
                                style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                                    style: TextStyle(
                                      fontSize: 20,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                formattedDateTime,
                                style: TextStyle(
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Option Button
                        Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              final RenderBox overlay =
                              Overlay.of(context).context.findRenderObject() as RenderBox;
                              final RenderBox button = context.findRenderObject() as RenderBox;
                              final Offset position =
                              button.localToGlobal(Offset.zero, ancestor: overlay);
                              showMenu<int>(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  position.dx,
                                  position.dy + button.size.height,
                                  position.dx + button.size.width,
                                  position.dy + button.size.height,
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 1,
                                    child: Text('Download'),
                                  ),
                                  PopupMenuItem(
                                    value : 2,
                                    child: Text("See Details"),
                                  ),
                                  PopupMenuItem(
                                    value: 3,
                                    child: Text('Delete'),
                                  ),
                                ],
                              ).then((value) {
                                if (value != null) {
                                  // Handle selected option based on value
                                  switch (value) {
                                    case 1:
                                      _firestoreFetcher.downloadImage(imageUrl!, mediaFileName!);
                                      print('Download selected');
                                      break;
                                    case 2:
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
                                      break;
                                    case 3:
                                    // Option 2 action
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Confirmation"),
                                          content: Text("Are you sure you want to cancel and delete the report?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context); // Close the dialog
                                              },
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context); // Close the dialog
                                                setState(() {

                                                });
                                                await _firestoreFetcher.deleteReport(documentId, mediaFileName!);
                                                print("$caseType deleted!");
                                              },
                                              child: Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      break;
                                    default:
                                      break;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    imageWidget,
                    // Like and Dislike buttons
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.flag_outlined),
                          onPressed: () async {
                            await _firestoreFetcher.toggleFlagReport(documentId, user.uid);
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
                            return Text('$flagsCount Flags', style: TextStyle(fontSize: 17,),);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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

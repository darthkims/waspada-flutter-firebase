import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/casesaround_district.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/profile.dart';
import 'package:fypppp/sos.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

const Color theme = Colors.red;
const Color sectheme = Colors.white;

class CasesAround extends StatefulWidget {
  const CasesAround({super.key});

  @override
  State<CasesAround> createState() => _CasesAroundState();
}

class _CasesAroundState extends State<CasesAround> {
  Set<String> uniqueCities = Set<String>();
  Map<String, int> cityOccurrences = {};

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Help"),
          content: const Text(
            "Only cities with cases are listed.\n"
            "Green: 1-2 cases\n"
            "Yellow: 3-4 cases\n"
            "Red: 5 or more cases",
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF4F3F2),
        appBar: AppBar(
          backgroundColor: theme,
          title: const Text(
            'All Disctricts',
            style: TextStyle(color: sectheme, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: sectheme),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: sectheme,
                  ),
                  onPressed: () {
                    _showHelpDialog(context);
                  },
                ),
              ],
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.only(left: 8, right: 8,),
          child: FutureBuilder(
            future: FirebaseFirestore.instance.collection('reports').get(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final reports = snapshot.data!.docs;
                // Clear set to avoid duplicates when rebuilding
                uniqueCities.clear();
                cityOccurrences.clear(); // Clear cityOccurrences map
                for (var report in reports) {
                  // Preprocess city name before adding to set
                  String cityName = report['city'];
                  if (cityName.toLowerCase() == 'malacca') {
                    cityName = 'Malacca City'; // Treat 'Malacca' as 'Melaka'
                  }
                  if (cityName.toLowerCase() == 'melaka') {
                    cityName = 'Malacca City'; // Treat 'Malacca' as 'Melaka'
                  }
                  uniqueCities.add(cityName);
                  // Update cityOccurrences map
                  if (cityOccurrences.containsKey(cityName)) {
                    cityOccurrences[cityName] = cityOccurrences[cityName]! + 1;
                  } else {
                    cityOccurrences[cityName] = 1;
                  }
                }
                final cityList = uniqueCities.toList();
                // Add a blank city to the end if the city list has an odd number of elements
                if (cityList.length % 2 != 0) {
                  cityList.add('');
                }
                return ListView.builder(
                  itemCount: (cityList.length / 2).ceil(),
                  // Calculate number of rows
                  itemBuilder: (context, index) {
                    final int startIndex = index * 2;
                    final int endIndex = startIndex + 2;
                    final List<String> rowCities =
                        cityList.sublist(startIndex, endIndex);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: rowCities.map((cityName) {
                        final int cases = cityOccurrences[cityName] ?? 0;
                        final bool highCases = cases > 4;
                        final bool midCases = cases > 2;
                        Color color = highCases
                            ? Color(0xffF88379)
                            : midCases
                                ? const Color(0xFFFFFAA0)
                                : const Color(0xFFF1E3C8);
                        Color style = highCases
                            ? Colors.white
                            : midCases
                                ? const Color(0xFF04234D)
                                : const Color(0xFF04234D);
                        return Expanded(
                          child: cityName.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CityDetailsPage(
                                              cityName: cityName,
                                              color: color,
                                              style: style,
                                              totalCases: cityOccurrences[cityName]!
                                          )
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 120,
                                    // Specify a fixed height for the container
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 4.0),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cityName,
                                            style: TextStyle(
                                                color: highCases
                                                    ? Color(0xFF04234D)
                                                    : midCases
                                                        ? const Color(0xFF04234D)
                                                        : const Color(0xFF04234D),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "Cases: ${cityOccurrences[cityName] ?? 0}",
                                            // Display the number of occurrences
                                            style: TextStyle(
                                                color: highCases
                                                    ? Color(0xFF04234D)
                                                    : midCases
                                                        ? const Color(0xFF04234D)
                                                        : const Color(0xFF04234D),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              : Container(
                                  height: 120,
                                  // Specify a fixed height for the container
                                  padding: const EdgeInsets.all(16.0),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    color: highCases
                                        ? Colors.red
                                        : const Color(0xFFFAF4F4),
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child:
                                      Image.asset("assets/images/icon_red.png"),
                                ),
                        );
                      }).toList(),
                    );
                  },
                );
              }
            },
          ),
        )
    );
  }
}

class CityDetailsPage extends StatefulWidget {
  final String cityName;
  final Color color;
  final Color style;
  final int totalCases;

  CityDetailsPage(
      {super.key,
      required this.cityName,
      required this.color,
      required this.style,
      required this.totalCases});

  @override
  State<CityDetailsPage> createState() => _CityDetailsPageState();
}

class _CityDetailsPageState extends State<CityDetailsPage> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String statusText;

    if (widget.totalCases <= 2) {
      statusText = "Low Alert";
    } else if (widget.totalCases <= 4) {
      statusText = "Mid Alert";
    } else {
      statusText = "High Alert";
    }

    return Scaffold(
      backgroundColor: Color(0xFFD5D3D3),
      appBar: AppBar(
        backgroundColor: theme,
        title: Row(
          children: [
            Text(
              widget.cityName,
              style: TextStyle(
                color: sectheme,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                    color: widget.style,
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: sectheme),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('city', isEqualTo: widget.cityName)
            .orderBy('timeStamp',
                descending:
                    true) // Sort documents by timestamp in descending order
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final reports = snapshot.data!.docs;
            if (reports.isEmpty) {
              return Center(
                  child: Text('No reports available for ${widget.cityName}'));
            }
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                String documentId = report.id; // Get the document ID
                String caseType = report['caseType'];
                String? desc;
                try {
                  desc = report['description'] as String?;
                  if (desc!.isEmpty) {
                    desc = "No description available";
                  }
                } catch (error) {
                  desc = "No description available";
                }
                String hashkey = report['hashkey'];
                Timestamp timestamp = report['timeStamp'];
                String imageUrl = report['mediaUrl'];
                String location = report['location'];
                String mediaFileName = report['mediaFileName'];
                String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a')
                    .format(timestamp.toDate());
                Future<String?> getAddressFromCoordinates(
                    double latitude, double longitude) async {
                  try {
                    List<Placemark> placemarks =
                        await placemarkFromCoordinates(latitude, longitude);
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
                    String address = addressParts
                        .where((part) => part != null && part.isNotEmpty)
                        .join(', ');
                    print(
                        '${place.name}, ${place.isoCountryCode},${place.country},${place.postalCode},${place.administrativeArea},${place.subAdministrativeArea},${place.locality},${place.subLocality}, ${place.thoroughfare}, ${place.subThoroughfare}');

                    return address;
                  } catch (e) {
                    print("Error getting address: $e");
                    return null;
                  }
                }

                List<String> locationParts = location.split(',');
                double latitude = double.parse(locationParts[0]);
                double longitude = double.parse(locationParts[1]);
                User? user =
                    FirebaseAuth.instance.currentUser; // Get the current user

                Widget imageWidget = imageUrl != null
                    ? mediaFileName.toLowerCase().endsWith('.mp4')
                        ? SizedBox(
                            child: Image.asset(
                                'assets/images/thumbnailvideo_horizontal.png'),
                          )
                        : Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              } else {
                                return SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                    : Container();

                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 8.0), // Add margin here
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caseType,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  formattedDateTime,
                                  style: const TextStyle(
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
                                      mainAxisSize: MainAxisSize.min,
                                      // Ensure the Column only occupies the space it needs
                                      children: <Widget>[
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.download,
                                            size: 33, // Adjust the size of the icon
                                          ),
                                          title: const Text(
                                            'Download Image',
                                            style: TextStyle(
                                                fontSize: 17,
                                            ), // Adjust the font size
                                          ),
                                          onTap: () {
                                            _firestoreFetcher.downloadImage(
                                                imageUrl, mediaFileName);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        const SizedBox(height: 10,),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.info_outline,
                                            size:
                                                33, // Adjust the size of the icon
                                          ),
                                          title: const Text(
                                            'See details',
                                            style: TextStyle(
                                                fontSize:
                                                    17), // Adjust the font size
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            showModalBottomSheet(
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Container(
                                                  height: 500,
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        ListTile(
                                                          title: Center(
                                                            child: Text(
                                                              caseType,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 30,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const Text(
                                                          'Description: ',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        Text(
                                                          desc!,
                                                          style: const TextStyle(fontSize: 20),
                                                        ),
                                                        const SizedBox(height: 8.0),
                                                        const Text(
                                                          'Location',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        FutureBuilder(
                                                          future: getAddressFromCoordinates(latitude, longitude),
                                                          builder: (context, AsyncSnapshot<String?>addressSnapshot) {
                                                            if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                                              return const SizedBox.shrink(); // Return empty space while waiting for address
                                                            }
                                                            if (addressSnapshot.hasError ||
                                                                addressSnapshot.data == null) {
                                                              return const SizedBox.shrink(); // Return empty space if there's an error or no address
                                                            }
                                                            return Text(
                                                              addressSnapshot.data!,
                                                              style: const TextStyle(
                                                                      fontSize: 20),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(height: 8.0),
                                                        const Text(
                                                          'Coordinate',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            String googleMapsUrl = "https://www.google.com/maps?q=@$location,17z";
                                                            Uri link = Uri.parse(googleMapsUrl);
                                                            if (await canLaunchUrl(link)) {
                                                              await launchUrl(link);
                                                            } else {
                                                              throw 'Could not launch $googleMapsUrl';
                                                            }
                                                          },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Colors.green,
                                                              borderRadius: BorderRadius.circular(10.0),
                                                            ),
                                                            padding: const EdgeInsets.all(4),
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  location,
                                                                  style: const TextStyle(
                                                                      fontSize: 20,
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold),
                                                                ),
                                                                const Icon(
                                                                  Icons.location_on,
                                                                  color: Colors.white,
                                                                ),
                                                                // Add your desired icon here
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8.0),
                                                        const Text(
                                                          'Date & Time',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        Text(
                                                          formattedDateTime,
                                                          style:
                                                              const TextStyle(fontSize: 20),
                                                        ),
                                                        const SizedBox(height: 8.0),
                                                        const Text(
                                                          'Evidence',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            if (mediaFileName.endsWith('mp4')) {
                                                              // Import the video_player package
                                                              Uri uri = Uri.parse(imageUrl);
                                                              // Create a VideoPlayerController instance
                                                              final videoPlayerController = VideoPlayerController.networkUrl(uri);

                                                              // Initialize the controller and display a loading indicator while it loads
                                                              await videoPlayerController
                                                                  .initialize()
                                                                  .then((_) {
                                                                // Once initialized, show the video in a dialog
                                                                _showVideoDialog(
                                                                    context,
                                                                    videoPlayerController);
                                                              });
                                                            } else if (mediaFileName
                                                                .endsWith(
                                                                    'jpg')) {
                                                              _showImageDialog(
                                                                  context,
                                                                  imageUrl);
                                                            } else {
                                                              // Handle other file types (optional)
                                                              print(
                                                                  'Unsupported file type: $mediaFileName');
                                                            }
                                                          },
                                                          child: imageWidget,
                                                        ),
                                                        const SizedBox(
                                                            height: 8.0),
                                                        const Text(
                                                          'SHA256 Hash:',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        Text(
                                                          hashkey,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            if (mediaFileName.endsWith('mp4')) {
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Video Loading'),
                                ),
                              );
                              // Import the video_player package
                              Uri uri = Uri.parse(imageUrl);
                              // Create a VideoPlayerController instance
                              final videoPlayerController =
                                  VideoPlayerController.networkUrl(uri);

                              // Initialize the controller and display a loading indicator while it loads
                              await videoPlayerController
                                  .initialize()
                                  .then((_) {
                                // Once initialized, show the video in a dialog
                                _showVideoDialog(
                                    context, videoPlayerController);
                              });
                            } else if (mediaFileName.endsWith('jpg')) {
                              _showImageDialog(context, imageUrl);
                            } else {
                              // Handle other file types (optional)
                              print('Unsupported file type: $mediaFileName');
                            }
                          },
                          child: imageWidget,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(documentId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    '⟳',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  );
                                }
                                final likesCount =
                                    snapshot.data!['likesCount'] ?? 0;
                                return Text(
                                  '$likesCount',
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                );
                              },
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('userFlags')
                                  .doc(user!.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return IconButton(
                                    icon:
                                        const Icon(Icons.thumb_up_alt_outlined),
                                    onPressed: () async {
                                      await _firestoreFetcher.toggleLikeReport(
                                          documentId, user.uid);
                                    },
                                  );
                                }
                                // final userLikes = snapshot.data!['likeReports'] ?? [];
                                // final hasLiked = userLikes.contains(documentId);
                                return IconButton(
                                  icon: Icon(Icons.thumb_up_alt_outlined),
                                  onPressed: () async {
                                    await _firestoreFetcher.toggleLikeReport(
                                        documentId, user.uid);
                                  },
                                );
                              },
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(documentId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    '⟳',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  );
                                }
                                final flagsCount =
                                    snapshot.data!['flagsCount'] ?? 0;
                                if (flagsCount >= 5) {
                                  _firestoreFetcher.deleteReport(
                                      documentId, mediaFileName);
                                }
                                return Text(
                                  '$flagsCount',
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                );
                              },
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('userFlags')
                                  .doc(user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return IconButton(
                                    icon: const Icon(Icons.flag_outlined),
                                    onPressed: () async {
                                      await _firestoreFetcher.toggleFlagReport(
                                          documentId, user.uid, context);
                                    },
                                  );
                                }
                                final userFlags =
                                    snapshot.data!['flagReports'] ?? [];
                                final hasFlagged =
                                    userFlags.contains(documentId);
                                return IconButton(
                                  icon: Icon(
                                    hasFlagged
                                        ? Icons.flag
                                        : Icons.flag_outlined,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await _firestoreFetcher.toggleFlagReport(
                                        documentId, user.uid, context);
                                  },
                                );
                              },
                            ),
                            IconButton(
                                onPressed: () {
                                  String link =
                                      "https://www.waspada.com/casePreview/$documentId";
                                  Share.share(link);
                                },
                                icon: Icon(Icons.share)),
                            GestureDetector(
                              onTap: () async {
                                String googleMapsUrl =
                                    "https://www.google.com/maps?q=@$location,17z";
                                Uri link = Uri.parse(googleMapsUrl);
                                if (await canLaunchUrl(link)) {
                                  await launchUrl(link);
                                } else {
                                  throw 'Could not launch $googleMapsUrl';
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Navigate',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                    ),
                                    // Add your desired icon here
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

void _showVideoDialog(
    BuildContext context, VideoPlayerController videoPlayerController) async {
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
                        videoPlayerController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 36.0,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                        ),
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

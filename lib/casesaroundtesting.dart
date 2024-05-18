import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/profileedit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class CasesAroundTesting extends StatefulWidget {
  const CasesAroundTesting({Key? key}) : super(key: key);

  @override
  State<CasesAroundTesting> createState() => _CasesAroundTestingState();
}

class _CasesAroundTestingState extends State<CasesAroundTesting> {
  int currentPageIndex = 2;
  Set<String> uniqueCities = Set<String>();
  Map<String, int> cityOccurrences = {};

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
        // Current page, do nothing
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfileEditPage()));
          break;
      }
    });
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Help"),
          content: Text("Only cities with cases are listed.",
          style: TextStyle(fontSize: 20),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
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
        actions: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
        ],
      ),

      body: Container(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: FirebaseFirestore.instance.collection('reports').get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
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
                itemCount: (cityList.length / 2).ceil(), // Calculate number of rows
                itemBuilder: (context, index) {
                  final int startIndex = index * 2;
                  final int endIndex = startIndex + 2;
                  final List<String> rowCities = cityList.sublist(startIndex, endIndex);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: rowCities.map((cityName) {
                      final int cases = cityOccurrences[cityName] ?? 0;
                      final bool highCases = cases > 4;
                      return Expanded (
                          child: cityName.isNotEmpty
                              ?
                           GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CityDetailsPage(cityName: cityName)),
                              );
                            },
                            child: Container(
                            height: 120, // Specify a fixed height for the container
                            padding: EdgeInsets.all(16.0),
                            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              color: highCases ? Colors.red : Color(0xFFF1E3C8),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cityName,
                                  style: TextStyle(color: highCases ? Colors.white : Color(0xFF04234D), fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Cases: ${cityOccurrences[cityName] ?? 0}", // Display the number of occurrences
                                  style: TextStyle(color: highCases ? Colors.white : Color(0xFF04234D), fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                           ) :
                            Container(
                              height: 120, // Specify a fixed height for the container
                              padding: EdgeInsets.all(16.0),
                              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: highCases ? Colors.red : Color(0xFFFAF4F4),
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
                              child: Image.asset("assets/images/appicon.png"),
                            ),
                        );
                    }).toList(),
                  );
                },
              );

            }
          },
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            )
                : const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
                AssetImage('assets/images/appicon.png'),
                size: 30,
              ),
              icon: ImageIcon(
                AssetImage('assets/images/appicon.png'),
                size: 30,
                color: Colors.white,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
              icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
              label: 'Circles',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings_input_antenna_outlined, size: 30,),
              icon: Icon(Icons.settings_input_antenna, color: Colors.white, size: 30,),
              label: 'Cases Around',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
              icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class CityDetailsPage extends StatefulWidget {
  final String cityName;

  CityDetailsPage({required this.cityName});

  @override
  State<CityDetailsPage> createState() => _CityDetailsPageState();
}

class _CityDetailsPageState extends State<CityDetailsPage> {
  FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cityName,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),

      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('city', isEqualTo: widget.cityName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final reports = snapshot.data!.docs;
            if (reports.isEmpty) {
              return Center(child: Text('No reports available for ${widget.cityName}'));
            }
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                String documentId = report.id; // Get the document ID
                String caseType = report['caseType'];
                Timestamp timestamp = report['timeStamp'];
                String imageUrl = report['mediaUrl'];
                String location = report['location'];
                String mediaFileName = report['mediaFileName'];
                String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp.toDate());
                Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
                  List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
                  Placemark place = placemarks[0];
                  return "${place.name}, ${place.thoroughfare}, ${place.locality}, ${place.postalCode}, ${place.administrativeArea}";
                }
                List<String> locationParts = location.split(',');
                double latitude = double.parse(locationParts[0]);
                double longitude = double.parse(locationParts[1]);
                User? user = FirebaseAuth.instance.currentUser; // Get the current user

                Widget imageWidget = imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
                    : Container();

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add margin here
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
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
                                  caseType,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                            _firestoreFetcher.downloadImage(imageUrl, mediaFileName);
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
                                                          _showImageDialog(context, imageUrl);
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
                            _showImageDialog(context, imageUrl);
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



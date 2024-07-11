import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/addreport.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ReportCase extends StatefulWidget {
  const ReportCase({Key? key}) : super(key: key);

  @override
  _ReportCaseState createState() => _ReportCaseState();
}

class _ReportCaseState extends State<ReportCase> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();
  Color theme = Colors.red;
  Color sectheme = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F2),
      appBar: AppBar(
        backgroundColor: theme,
        title: Text('Report Case',
          style: TextStyle(color: sectheme, fontWeight: FontWeight.bold),
      ),
      iconTheme: IconThemeData(color: sectheme), // Set the leading icon color to white
        actions: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 35,),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReport()));
                  },
                ),
            ],
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Reports',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const Divider(),
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
      return const Center(
        child: Text('User not logged in'), // Handle case where user is not logged in
      );
    }

    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('reports')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timeStamp', descending: true) // Order by timestamp in descending order
          .get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
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
            String? hashkey = (document.data() as Map<String, dynamic>)['hashkey'];
            String description = (document.data() as Map<String, dynamic>)['description'] as String? ?? "No description available";
            Timestamp? timestamp = (document.data() as Map<String, dynamic>)['timeStamp'] as Timestamp?;
            String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timestamp!.toDate());
            String? location = (document.data() as Map<String, dynamic>)['location'] as String?;

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
                ? mediaFileName!.toLowerCase().endsWith('.mp4')
                ? SizedBox(
              child: Image.asset('assets/images/thumbnailvideo_horizontal.png'),
            )
                : Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
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
            )
                : Container();

            return GestureDetector(
              onTap: () async {
                if (mediaFileName!.endsWith('mp4')) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Video Loading'),
                    ),
                  );
                  // Import the video_player package
                  Uri uri = Uri.parse(imageUrl!);
                  // Create a VideoPlayerController instance
                  final videoPlayerController = VideoPlayerController.networkUrl(uri);

                  // Initialize the controller and display a loading indicator while it loads
                  await videoPlayerController.initialize().then((_) {
                    // Once initialized, show the video in a dialog
                    _showVideoDialog(context, videoPlayerController);
                  });
                } else if (mediaFileName.endsWith('jpg')) {
                  _showImageDialog(context, imageUrl!);
                } else {
                  // Handle other file types (optional)
                  print('Unsupported file type: $mediaFileName');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color:  Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
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
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                                    style: const TextStyle(
                                      fontSize: 20,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                formattedDateTime,
                                style: const TextStyle(
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
                            icon: const Icon(Icons.more_vert),
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
                                  const PopupMenuItem(
                                    value: 1,
                                    child: Text('Download'),
                                  ),
                                  const PopupMenuItem(
                                    value : 2,
                                    child: Text("See Details"),
                                  ),
                                  const PopupMenuItem(
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
                                                          "$caseType",
                                                          style: const TextStyle(
                                                              fontSize: 30, fontWeight: FontWeight.bold),
                                                        )
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  const Text(
                                                    'Description',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$description',
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
                                                    builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                                                      if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                                        return const SizedBox.shrink(); // Return empty space while waiting for address
                                                      }
                                                      if (addressSnapshot.hasError || addressSnapshot.data == null) {
                                                        return const SizedBox.shrink(); // Return empty space if there's an error or no address
                                                      }
                                                      return Text(
                                                        addressSnapshot.data!,
                                                        style: const TextStyle(fontSize: 20),
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
                                                            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                                          ),
                                                          const Icon(Icons.location_on, color: Colors.white,), // Add your desired icon here
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
                                                    '$formattedDateTime',
                                                    style: const TextStyle(fontSize: 20),
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
                                                      if (mediaFileName!.endsWith('mp4')) {
                                                        // Import the video_player package
                                                        Uri uri = Uri.parse(imageUrl!);
                                                        // Create a VideoPlayerController instance
                                                        final videoPlayerController = VideoPlayerController.networkUrl(uri);
                                              
                                                        // Initialize the controller and display a loading indicator while it loads
                                                        await videoPlayerController.initialize().then((_) {
                                                          // Once initialized, show the video in a dialog
                                                          _showVideoDialog(context, videoPlayerController);
                                                        });
                                                      } else if (mediaFileName.endsWith('jpg')) {
                                                        _showImageDialog(context, imageUrl!);
                                                      } else {
                                                        // Handle other file types (optional)
                                                        print('Unsupported file type: $mediaFileName');
                                                      }
                                                    },
                                              
                                                    child: imageWidget,
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  const Text(
                                                    'SHA256 Hash: ',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$hashkey',
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                ],
                                              ),
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
                                          title: const Text("Confirmation"),
                                          content: const Text("Are you sure you want to delete the report?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context); // Close the dialog
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context); // Close the dialog
                                                setState(() {

                                                });
                                                await _firestoreFetcher.deleteReport(documentId, mediaFileName!);
                                                print("$caseType deleted!");
                                              },
                                              child: const Text("Delete"),
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
                    const SizedBox(height: 10),
                    imageWidget,
                    // Like and Dislike buttons
                    Row(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('userFlags').doc(user!.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                onPressed: () async {
                                  await _firestoreFetcher.toggleLikeReport(documentId, user.uid);
                                },
                              );
                            }
                            final userLikes = snapshot.data!['likeReports'] ?? [];
                            final hasLiked = userLikes.contains(documentId);
                            return IconButton(
                              icon: Icon(hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined),
                              onPressed: () async {
                                await _firestoreFetcher.toggleLikeReport(documentId, user.uid);
                              },
                            );
                          },
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('reports').doc(documentId).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('⟳ Likes', style: TextStyle(fontSize: 17,),);
                            }
                            if (!snapshot.hasData) {
                              return const Text('0 Likes', style: TextStyle(fontSize: 17,),);
                            }
                            final likesCount = snapshot.data!['likesCount'] ?? 0;
                            return Text('$likesCount Likes', style: const TextStyle(fontSize: 17,),);
                          },
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('userFlags').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return IconButton(
                                icon: const Icon(Icons.flag_outlined),
                                onPressed: () async {
                                  await _firestoreFetcher.toggleFlagReport(documentId, user.uid, context);
                                },
                              );
                            }
                            final userFlags = snapshot.data!['flagReports'] ?? [];
                            final hasFlagged = userFlags.contains(documentId);
                            return IconButton(
                              icon: Icon(hasFlagged ? Icons.flag: Icons.flag_outlined),
                              onPressed: () async {
                                await _firestoreFetcher.toggleFlagReport(documentId, user.uid, context);
                              },
                            );
                          },
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('reports').doc(documentId).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('0 Flags');
                            }
                            if (!snapshot.hasData) {
                              return const Text('0');
                            }
                            final flagsCount = snapshot.data!['flagsCount'] ?? 0;
                            return Text('$flagsCount Flags', style: const TextStyle(fontSize: 17,),);
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

}

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/casesaround_district.dart';
import 'package:fypppp/circles.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:fypppp/home.dart';
import 'package:fypppp/navbar.dart';
import 'package:fypppp/profileedit.dart';
import 'package:fypppp/settings.dart';
import 'package:fypppp/sos.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

Color appbar = Colors.red;
Color textappbar = Colors.white;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentPageIndex = 4;
  String name = '';

  void onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                return const Home();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
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
                return const CasesAroundDistrict();
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case 4:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // The user is signed in
      name = user.displayName ?? "Anonymous";
    } else {
      print("No user signed in.");
    }

    return Scaffold(
        backgroundColor: Color(0xFFF4F3F2),
        appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: textappbar, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appbar,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hello $name!', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
              const SizedBox(height: 20,),
              const Divider(),
              ListTile(
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditPage() ));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('SOS Video Recordings'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewSOS()));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('SOS Audio Recordings'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewSOSAudio()));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Settings'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(currentPageIndex: currentPageIndex, onItemTapped: onItemTapped)
    );
  }
}

class ViewSOS extends StatefulWidget {
  const ViewSOS({Key? key}) : super(key: key);

  @override
  State<ViewSOS> createState() => _ViewSOSState();
}

class _ViewSOSState extends State<ViewSOS> {
  final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();

  @override
  Widget build(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFF4F3F2),
      appBar: AppBar(
        title: Text(
          'SOS Video Recordings',
          style: TextStyle(color: textappbar, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appbar,
        iconTheme: IconThemeData(color: textappbar),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('SOSreports').orderBy('timeStamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No SOS recordings'));
          } else {
            return ListView.separated(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {

                final Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final String mediaUrl = data['mediaUrl'];
                final String mediaFileName = data['videoName'];
                final String hashKey = data['hashKey'];
                final String location = data['location'] ?? 'No Location';
                List<String> locationParts = location.split(',');
                double latitude = double.parse(locationParts[0]);
                double longitude = double.parse(locationParts[1]);
                // Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
                //   List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
                //   Placemark place = placemarks[0];
                //   return "${place.name}, ${place.thoroughfare}, ${place.locality}, ${place.postalCode}, ${place.administrativeArea}";
                // }
                _firestoreFetcher.getAddressFromCoordinates(latitude, longitude);
                final String documentId = snapshot.data!.docs[index].id;


                // Convert timestamp to DateTime
                DateTime timeStamp = (snapshot.data!.docs[index]['timeStamp'] as Timestamp).toDate();

                // Format the DateTime
                String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timeStamp);


                return FutureBuilder<String?>(
                    future: _firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
                    builder: (context, addressSnapshot) {
                      if (addressSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: const CircularProgressIndicator(),
                          subtitle: Text(formattedDateTime),
                        );
                      }
                      if (addressSnapshot.hasError) {
                        return ListTile(
                          title: const Text('Error getting address'),
                          subtitle: Text(formattedDateTime),
                        );
                      }
                      final String? address = addressSnapshot.data ?? 'Unknown address';
                    return GestureDetector(
                      onTap: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Video Loading'),
                          ),
                        );
                        Uri uri = Uri.parse(mediaUrl);
                        final videoPlayerController = VideoPlayerController.networkUrl(uri);

                        // Initialize the controller and display a loading indicator while it loads
                        await videoPlayerController.initialize().then((_) {
                          // Once initialized, show the video in a dialog
                          _showVideoDialog(context, videoPlayerController);
                        });
                      },
                      child: ListTile(
                        title: Text(address!),
                        subtitle: Text(formattedDateTime),
                        trailing: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 10,),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.download,
                                            size: 36, // Adjust the size of the icon
                                          ),
                                          title: const Text(
                                            'Download Recording',
                                            style: TextStyle(fontSize: 20), // Adjust the font size
                                          ),
                                          onTap: () {
                                            _firestoreFetcher.downloadImage(mediaUrl, mediaFileName);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.info_outline,
                                            size: 36, // Adjust the size of the icon
                                          ),
                                          title: const Text(
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
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Location',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      FutureBuilder(
                                                        future: _firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
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
                                                      Text(
                                                        location,
                                                        style: const TextStyle(fontSize: 20),
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
                                                        style: const TextStyle(fontSize: 20),
                                                      ),
                                                      const SizedBox(height: 8.0),
                                                      const Text(
                                                        'SHA256 Hash:',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        hashKey,
                                                        style: const TextStyle(fontSize: 20),
                                                      )
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete,
                                            size: 36, // Adjust the size of the icon
                                          ),
                                          title: const Text(
                                            'Delete Recording',
                                            style: TextStyle(fontSize: 20), // Adjust the font size
                                          ),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Confirmation"),
                                                content: const Text("Are you sure you want to delete the recording?"),
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
                                                      await _firestoreFetcher.deleteRecording(documentId, mediaFileName);
                                                      Navigator.of(context).pop(); // Close the modal bottom sheet
                                                    },
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  }
                              );
                            }, icon: const Icon(Icons.more_vert)
                        )
                      ),
                    );
                  }
                );

              },
              separatorBuilder: (context, index) => const Divider(),
            );
          }
        },
      ),
    );
  }
}

class ViewSOSAudio extends StatefulWidget {
  const ViewSOSAudio({super.key});

  @override
  State<ViewSOSAudio> createState() => _ViewSOSAudioState();
}

class _ViewSOSAudioState extends State<ViewSOSAudio> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreFetcher _firestoreFetcher = FirestoreFetcher();
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SOS Audio Recordings',
          style: TextStyle(color: textappbar, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appbar,
        iconTheme: IconThemeData(color: textappbar),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('SOSAudioreports')
            .orderBy('timeStamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          if (documents.isEmpty) {
            return const Center(
              child: Text('No SOS audio recording'),
            );
          }

          return ListView.separated(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data() as Map<String, dynamic>;
              final String mediaUrl = data['mediaUrl'];
              final String mediaFileName = data['videoName'];
              final String hashKey = data['hashKey'];
              final String location = data['location'] ?? 'No Location';
              List<String> locationParts = location.split(',');
              double latitude = 0.0;
              double longitude = 0.0;
              if (locationParts.length >= 2) {
                try {
                  latitude = double.parse(locationParts[0].trim());
                  longitude = double.parse(locationParts[1].trim());
                } catch (e) {
                  print('Error parsing latitude or longitude: $e');
                  // Handle error, perhaps set default values or show an error message
                }
              }

              final String documentId = snapshot.data!.docs[index].id;
              DateTime timeStamp = (snapshot.data!.docs[index]['timeStamp'] as Timestamp).toDate();
              String formattedDateTime = DateFormat('dd MMMM yyyy, hh:mm a').format(timeStamp);

              return FutureBuilder<String?>(
                future: _firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
                builder: (context, addressSnapshot) {
                  if (addressSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: const CircularProgressIndicator(),
                      subtitle: Text(formattedDateTime),
                    );
                  }
                  if (addressSnapshot.hasError) {
                    return ListTile(
                      title: const Text('Error getting address'),
                      subtitle: Text(formattedDateTime),
                    );
                  }
                  final String? address = addressSnapshot.data ?? 'Unknown address';

                  return GestureDetector(
                    onTap: () async {
                      await _audioPlayer.setSourceUrl(mediaUrl);
                      Duration? duration = await _audioPlayer.getDuration();
                      print(duration.toString());
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text(address),
                                content: Row(
                                  children: [
                                    Text(formattedDateTime),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      if (!_isPlaying) {
                                        await _audioPlayer.setSourceUrl(mediaUrl);
                                        await _audioPlayer.resume();
                                        setState(() {
                                          _isPlaying = true;
                                          _isPaused = false;
                                        });
                                      } else if (_isPaused) {
                                        await _audioPlayer.resume();
                                        setState(() {
                                          _isPaused = false;
                                        });
                                      }
                                    },
                                    child: Text(_isPaused ? 'Resume' : 'Play'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (_isPlaying && !_isPaused) {
                                        await _audioPlayer.pause();
                                        setState(() {
                                          _isPaused = true;
                                        });
                                      }
                                    },
                                    child: const Text('Pause'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _audioPlayer.stop();
                                      setState(() {
                                        _isPlaying = false;
                                        _isPaused = false;
                                      });
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    child: const Text('Stop'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: ListTile(
                      title: Text(address!),
                      subtitle: Text(formattedDateTime),
                      trailing: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.download,
                                      size: 36,
                                    ),
                                    title: const Text(
                                      'Download Recording',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    onTap: () {
                                      _firestoreFetcher.downloadImage(mediaUrl, mediaFileName);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.info_outline,
                                      size: 36,
                                    ),
                                    title: const Text(
                                      'See details',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                FutureBuilder(
                                                  future: _firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
                                                  builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                                                    if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    if (addressSnapshot.hasError || addressSnapshot.data == null) {
                                                      return const SizedBox.shrink();
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
                                                Text(
                                                  location,
                                                  style: const TextStyle(fontSize: 20),
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
                                                  style: const TextStyle(fontSize: 20),
                                                ),
                                                const SizedBox(height: 8.0),
                                                const Text(
                                                  'SHA256 Hash:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  hashKey,
                                                  style: const TextStyle(fontSize: 20),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      size: 36,
                                    ),
                                    title: const Text(
                                      'Delete Recording',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirmation"),
                                          content: const Text("Are you sure you want to delete the recording?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await _firestoreFetcher.deleteAudioRecording(documentId, mediaFileName);
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.more_vert),
                      ),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
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






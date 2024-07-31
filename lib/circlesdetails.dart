import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

const Color theme = Colors.red;
const Color sectheme = Colors.white;

class CircleDetailsPage extends StatefulWidget {
  final String circleName;

  const CircleDetailsPage(this.circleName, {super.key});

  @override
  State<CircleDetailsPage> createState() => _CircleDetailsPageState();
}

class _CircleDetailsPageState extends State<CircleDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  FirestoreFetcher firestoreFetcher = FirestoreFetcher();
  final ScrollController _scrollController = ScrollController();
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _scrollController;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circleName)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> messages = [];
    for (var doc in querySnapshot.docs) {
      messages.add({
        'senderId': doc['senderId'],
        'message': doc['message'],
        'timestamp': doc['timestamp'],
      });
    }

    setState(() {
      _messages = messages;
    });

    // Scroll to the bottom after fetching messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(50.0);
      } else {
        print('scrollcontroller no client');
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F2),
      appBar: AppBar(
        backgroundColor: theme,
        title: Text(
          widget.circleName,
          style: const TextStyle(color: sectheme),
        ),
        iconTheme: const IconThemeData(color: sectheme),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showBottomSheet(context);
            },
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('circles')
                    .doc(widget.circleName)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  _messages = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Check if the document contains the "mediaUrl" field
                    final mediaUrl = data.containsKey('mediaUrl')
                        ? data['mediaUrl'] as String
                        : null;
                    final fileName = data.containsKey('fileName')
                        ? data['fileName'] as String
                        : null;

                    return {
                      'senderId': data['senderId'],
                      'fileName': fileName,
                      'message': data['message'],
                      'timestamp': data['timestamp'],
                      'mediaUrl': mediaUrl,
                      'location': data['location'],
                    };
                  }).toList();

                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        String senderId = _messages[index]['senderId'];
                        String? fileName = _messages[index]['fileName'];
                        GeoPoint? location = _messages[index]['location'];
                        double latitude = location?.latitude ?? 0.0;
                        double longitude = location?.longitude ?? 0.0;
                        String message = _messages[index]['message'];
                        String? mediaUrl = _messages[index]
                            ['mediaUrl']; // Make mediaUrl nullable
                        Timestamp timestamp = _messages[index]['timestamp'];
                        String time = DateFormat('d MMMM, hh:mm a')
                            .format(timestamp.toDate());

                        // Check if the senderId matches the current user's ID
                        bool isCurrentUserMessage =
                            senderId == FirebaseAuth.instance.currentUser!.uid;
                        CrossAxisAlignment messageAlignment =
                            isCurrentUserMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start;

                        // Check if the message contains "check in"
                        bool containsCheckIn = message.toLowerCase().contains("check in report");
                        // Check if the message contains a mediaUrl
                        bool containsMedia = mediaUrl != null && mediaUrl.isNotEmpty;
                        bool containsJPG = false;
                        if (fileName != null && fileName.isNotEmpty) {
                          containsJPG = fileName.toLowerCase().contains('.jpg');
                        }
                        bool containsVideo = false;
                        if (fileName != null && fileName.isNotEmpty) {
                          containsVideo =
                              fileName.toLowerCase().contains('sosrecording');
                        }
                        bool containsAudio = false;
                        if (fileName != null && fileName.isNotEmpty) {
                          containsAudio =
                              fileName.toLowerCase().contains('audio');
                        }

                        String username = "";

                        return Column(
                          crossAxisAlignment: isCurrentUserMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            IntrinsicWidth(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isCurrentUserMessage
                                          ? const Color(0xFF89cff0) // If the message doesn't contain "check in" and it's sent by the current user, make it blue
                                          : const Color(0xFF98FB98), // If the message doesn't contain "check in" and it's not sent by the current user, make it white
                                ),
                                child: ListTile(
                                  title: FutureBuilder(
                                    future: firestoreFetcher
                                        .getUsernameFromSenderId(senderId),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<String?>
                                            usernameSnapshot) {
                                      if (usernameSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else {
                                        if (usernameSnapshot.hasData &&
                                            usernameSnapshot.data != null) {
                                          username = usernameSnapshot.data!;
                                          return Text(
                                            username,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          );
                                        } else {
                                          return const Text('Unknown User');
                                        }
                                      }
                                    },
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: messageAlignment,
                                    children: [
                                      if (containsMedia)
                                        if (containsJPG)
                                          GestureDetector(
                                            onTap: () {
                                              _showImageDialog(
                                                  context, mediaUrl);
                                            },
                                            child: SizedBox(
                                              height: 400,
                                              // Adjust the height as needed
                                              child: Image.network(
                                                mediaUrl,
                                                fit: BoxFit.cover,
                                                // Adjust the fit of the image
                                                loadingBuilder:
                                                    (BuildContext context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  } else {
                                                    return SizedBox(
                                                      height: 400,
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
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
                                              ),
                                            ),
                                          ),
                                      if (containsVideo)
                                        GestureDetector(
                                          onTap: () async {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content:
                                                        Text("Video loading")));
                                            Uri uri = Uri.parse(mediaUrl!);
                                            // Create a VideoPlayerController instance
                                            final videoPlayerController =
                                                VideoPlayerController
                                                    .networkUrl(uri);

                                            // Initialize the controller and display a loading indicator while it loads
                                            await videoPlayerController
                                                .initialize()
                                                .then((_) {
                                              // Once initialized, show the video in a dialog
                                              _showVideoDialog(context,
                                                  videoPlayerController);
                                            });
                                          },
                                          child: Container(
                                            height: 300,
                                            // Adjust the height as needed
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Image.asset(
                                                  'assets/images/thumbnailvideo.png'),
                                            ),
                                          ),
                                        ),
                                      if (containsAudio)
                                        GestureDetector(
                                          onTap: () async {
                                            await _audioPlayer
                                                .setSourceUrl(mediaUrl!);
                                            Duration position = Duration.zero;
                                            Duration? duration =
                                                await _audioPlayer
                                                    .getDuration();
                                            StreamSubscription<Duration>
                                                positionSubscription;

                                            String formatDuration(
                                                Duration duration) {
                                              String twoDigits(int n) =>
                                                  n.toString().padLeft(2, '0');
                                              String twoDigitMinutes =
                                                  twoDigits(duration.inMinutes
                                                      .remainder(60));
                                              String twoDigitSeconds =
                                                  twoDigits(duration.inSeconds
                                                      .remainder(60));
                                              return "$twoDigitMinutes:$twoDigitSeconds";
                                            }

                                            print(duration);
                                            if (duration! >
                                                const Duration(seconds: 1)) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return StatefulBuilder(
                                                    builder:
                                                        (context, setState) {
                                                      // Listen to audio position updates
                                                      positionSubscription =
                                                          _audioPlayer
                                                              .onPositionChanged
                                                              .listen(
                                                                  (newPosition) {
                                                        setState(() {
                                                          position =
                                                              newPosition;
                                                        });
                                                      });

                                                      _audioPlayer
                                                          .setReleaseMode(
                                                              ReleaseMode.loop);

                                                      return AlertDialog(
                                                        title: Text(
                                                            "$username's SOS Recording"),
                                                        content: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          // Ensure the column takes minimum space
                                                          children: [
                                                            Slider(
                                                              value: position
                                                                  .inSeconds
                                                                  .toDouble(),
                                                              min: 0,
                                                              max: duration
                                                                  .inSeconds
                                                                  .toDouble(),
                                                              onChanged:
                                                                  (value) async {
                                                                // Seek to the new position in the audio
                                                                await _audioPlayer
                                                                    .seek(Duration(
                                                                        seconds:
                                                                            value.toInt()));
                                                              },
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(formatDuration(
                                                                      position)),
                                                                  Text(formatDuration(
                                                                      duration -
                                                                          position)),
                                                                ],
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () async {
                                                              if (!_isPlaying) {
                                                                await _audioPlayer
                                                                    .setSourceUrl(
                                                                        mediaUrl);
                                                                await _audioPlayer
                                                                    .resume();
                                                                setState(() {
                                                                  _isPlaying =
                                                                      true;
                                                                  _isPaused =
                                                                      false;
                                                                });
                                                              } else if (_isPaused) {
                                                                await _audioPlayer
                                                                    .resume();
                                                                setState(() {
                                                                  _isPaused =
                                                                      false;
                                                                });
                                                              }
                                                            },
                                                            child: Text(
                                                                _isPaused
                                                                    ? 'Resume'
                                                                    : 'Play'),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () async {
                                                              if (_isPlaying &&
                                                                  !_isPaused) {
                                                                await _audioPlayer
                                                                    .pause();
                                                                setState(() {
                                                                  _isPaused =
                                                                      true;
                                                                });
                                                              }
                                                            },
                                                            child: const Text(
                                                                'Pause'),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () async {
                                                              await _audioPlayer
                                                                  .stop();
                                                              setState(() {
                                                                _isPlaying =
                                                                    false;
                                                                _isPaused =
                                                                    false;
                                                              });
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(); // Close the dialog
                                                              positionSubscription
                                                                  .cancel(); // Cancel the subscription when dialog is closed
                                                            },
                                                            child: const Text(
                                                                'Stop'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            } else {
                                              await _audioPlayer
                                                  .setSourceUrl(mediaUrl);
                                              Duration? duration =
                                                  await _audioPlayer
                                                      .getDuration();
                                              print(duration.toString());
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return StatefulBuilder(
                                                    builder:
                                                        (context, setState) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            "$username's SOS Recording"),
                                                        content: const Row(
                                                          children: [],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () async {
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
                                                            child: Text(_isPaused
                                                                    ? 'Resume'
                                                                    : 'Play'),
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
                                            }
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: Image.asset(
                                                    'assets/images/thumbnail_audio.png')),
                                          ),
                                        ),
                                      if (containsCheckIn || containsMedia)
                                        Row(
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
                                            if (containsMedia)
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(vertical: 5),
                                                decoration: const BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.all(Radius.circular(15))),
                                                child: IconButton(
                                                    onPressed: () async {
                                                      firestoreFetcher.downloadImage(mediaUrl, mediaUrl);
                                                    },
                                                    icon: const Icon(
                                                      Icons.download,
                                                      color: Colors.white,
                                                    )
                                                ),
                                              ),
                                          ],
                                        ),
                                      // Apply bold style if the message contains "check in"
                                      Text(
                                        message,
                                        style: containsCheckIn || containsAudio || containsVideo || containsJPG
                                            ? const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            )
                                            : const TextStyle(
                                          fontWeight: FontWeight.normal,
                                        )
                                      ),
                                      SizedBox(height: 10,),
                                      FutureBuilder(
                                        future: firestoreFetcher.getAddressFromCoordinates(latitude, longitude),
                                        builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                                          if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox.shrink();
                                          }
                                          if (addressSnapshot.hasError || addressSnapshot.data == null) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                            "Address: ${addressSnapshot.data!}",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(time)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(color: theme),
                        ),
                        hintText: 'Enter your message...',
                      ),
                    ),
                  ),
                  PopupMenuButton<int>(
                    offset: const Offset(0, -125),
                    icon: const Icon(Icons.add_circle_outline, color: theme),
                    onSelected: (value) {
                      // Handle menu selection here
                      if (value == 1) {
                        firestoreFetcher.checkIn(widget.circleName, userId, context);
                      } else if (value == 2) {
                        firestoreFetcher.quickCapture(widget.circleName, userId, context);
                      }
                      // Add more conditions if you have more options
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Text("Check In"),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Text("Quick Capture"),
                      ),
                      // Add more items if needed
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: theme,
                    ),
                    onPressed: () {
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String senderId = userId;

      // Add the new message locally to prevent the screen from refreshing
      setState(() {
        _messages.add({
          'senderId': senderId,
          'message': _messageController.text,
          'timestamp': Timestamp.now(),
        });
      });

      // Scroll to the bottom when a new message is sent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients)
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });

      // Add the message to Firestore
      FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleName)
          .collection('messages')
          .add({
        'senderId': senderId,
        'message': _messageController.text,
        'timestamp': Timestamp.now(),
      }).then((value) {
        // Clear the message controller after sending
        _messageController.clear();
      }).catchError((error) {
        print("Failed to send message: $error");
      });
      await firestoreFetcher.sendFCMNotification(
          senderId, widget.circleName, _messageController.text);
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('circles')
              .doc(widget.circleName)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var circleData = snapshot.data!.data() as Map<String, dynamic>?;

            // Check if circleData is not null and if 'members' array exists
            var members = circleData != null
                ? (circleData['members'] as List<dynamic>?)
                : null;

            return Container(
              padding: const EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "Circle Details",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Example of accessing userid for each member in the array
                    if (members !=
                        null) // Check if members is not null before using it
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (BuildContext context, int index) {
                          var userid = members[
                              index]; // Adjust the field name as per your Firestore structure
                          // Asynchronously fetch username from Firestore based on userid
                          return FutureBuilder<String?>(
                            future: firestoreFetcher
                                .getUsernameFromSenderId(userid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator(); // While fetching data, show a loading indicator
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                String username = snapshot.data ??
                                    'Unknown'; // Default to 'Unknown' if username not found
                                return Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ExpansionTile(
                                        shape: Border.all(
                                            color: Colors.transparent),
                                        title: Text(username),
                                        iconColor: Colors.white,
                                        textColor: Colors.white,
                                        collapsedBackgroundColor:
                                            Colors.grey[300],
                                        backgroundColor: theme,
                                        trailing: const Icon(Icons.expand_more),
                                        children: [
                                          FutureBuilder(
                                            future: FirebaseFirestore.instance
                                                .collection('circles')
                                                .doc(widget.circleName)
                                                .collection('checkin')
                                                .where('senderId',
                                                    isEqualTo:
                                                        userid) // Adjust 'userId' to your actual field name
                                                .orderBy('timestamp',
                                                    descending: true)
                                                .get(),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<QuerySnapshot>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }
                                              if (snapshot.hasError) {
                                                return Center(
                                                    child: Text(
                                                        'Error: ${snapshot.error}'));
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data!.docs.isEmpty) {
                                                return const Text(
                                                    'No check-ins found.');
                                              }
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFF66EEEE)),
                                                ),
                                                height: 300,
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount: snapshot.data!.docs.length,
                                                  itemBuilder: (context, index) {
                                                    var checkIn = snapshot.data!.docs[index];
                                                    var coordinate = checkIn['location'] as GeoPoint;
                                                    var timestamp = checkIn['timestamp'] as Timestamp;
                                                    var dateTime = timestamp.toDate();
                                                    String formattedDate = DateFormat('h:mm a, d MMMM yyyy').format(dateTime);

                                                    return Column(
                                                      children: [
                                                        ListTile(
                                                            title: FutureBuilder(
                                                              future: firestoreFetcher.getAddressFromCoordinates(coordinate.latitude, coordinate.longitude),
                                                              builder: (context, AsyncSnapshot<String?> addressSnapshot) {
                                                                if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                                                  return const SizedBox.shrink();
                                                                }
                                                                if (addressSnapshot.hasError || addressSnapshot.data == null) {
                                                                  return const SizedBox.shrink();
                                                                }
                                                                return Text(
                                                                  "Check In at: ${addressSnapshot.data!}",
                                                                );
                                                              },
                                                            ),
                                                            subtitle: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                    "Coordinate: ${coordinate.latitude}.${coordinate.longitude}"
                                                                ),
                                                                Text(
                                                                    formattedDate
                                                                ),
                                                              ],
                                                            ),
                                                            trailing:
                                                                IconButton(
                                                                    onPressed:
                                                                        () async {
                                                                      String
                                                                          googleMapsUrl =
                                                                          "https://www.google.com/maps?q=@${coordinate.latitude},${coordinate.longitude},17z"; // Replace with your pre-defined link
                                                                      Uri link =
                                                                          Uri.parse(
                                                                              googleMapsUrl);
                                                                      if (await canLaunchUrl(
                                                                          link)) {
                                                                        await launchUrl(
                                                                            link);
                                                                      } else {
                                                                        throw 'Could not launch $googleMapsUrl';
                                                                      }
                                                                    },
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .location_on))),
                                                        const Divider(),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

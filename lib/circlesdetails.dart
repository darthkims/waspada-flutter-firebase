import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fypppp/firestore/fetchdata.dart';
import 'package:intl/intl.dart';

class CircleDetailsPage extends StatefulWidget {
  final String circleName;

  const CircleDetailsPage(this.circleName, {Key? key}) : super(key: key);

  @override
  State<CircleDetailsPage> createState() => _CircleDetailsPageState();
}

class _CircleDetailsPageState extends State<CircleDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  FirestoreFetcher firestoreFetcher = FirestoreFetcher();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _scrollController;
  }

  Future<void> _fetchMessages() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circleName)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> messages = [];
    querySnapshot.docs.forEach((doc) {
      messages.add({
        'senderId': doc['senderId'],
        'message': doc['message'],
        'timestamp': doc['timestamp'],
      });
    });

    setState(() {
      _messages = messages;
    });

    // Scroll to the bottom after fetching messages
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.circleName,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showBottomSheet(context);
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(10),
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
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  _messages = snapshot.data!.docs.map((doc) {
                    return {
                      'senderId': doc['senderId'],
                      'message': doc['message'],
                      'timestamp': doc['timestamp'],
                    };
                  }).toList();

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      String senderId = _messages[index]['senderId'];
                      String message = _messages[index]['message'];
                      Timestamp timestamp = _messages[index]['timestamp'];
                      String time = DateFormat('d MMMM, hh:mm a').format(timestamp.toDate());

                      // Check if the senderId matches the current user's ID
                      bool isCurrentUserMessage = senderId == FirebaseAuth.instance.currentUser!.uid;
                      CrossAxisAlignment messageAlignment =
                      isCurrentUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;

                      // Check if the message contains "check in"
                      bool containsCheckIn = message.toLowerCase().contains("check in report");

                      return Column(
                        crossAxisAlignment: isCurrentUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          IntrinsicWidth(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: containsCheckIn
                                    ? Colors.red // If the message contains "check in", make it red
                                    : isCurrentUserMessage
                                    ? Color(0xFF66EEEE)// If the message doesn't contain "check in" and it's sent by the current user, make it blue
                                    : Color(0xFFECFFB9), // If the message doesn't contain "check in" and it's not sent by the current user, make it white

                              ),
                              child: ListTile(
                                title: FutureBuilder(
                                  future: firestoreFetcher.getUsernameFromSenderId(senderId),
                                  builder: (BuildContext context, AsyncSnapshot<String?> usernameSnapshot) {
                                    if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else {
                                      if (usernameSnapshot.hasData && usernameSnapshot.data != null) {
                                        String username = usernameSnapshot.data!;
                                        return Text(username, style: TextStyle(fontWeight: FontWeight.bold),);
                                      } else {
                                        return Text('Unknown User');
                                      }
                                    }
                                  },
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: messageAlignment,
                                  children: [
                                    // Apply bold style if the message contains "check in"
                                    Text(
                                      message,
                                      style: containsCheckIn ? TextStyle(fontWeight: FontWeight.bold, fontSize: 15) : TextStyle(fontSize: 15),
                                    ),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(time)
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
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

  void _sendMessage() {
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
        // Scroll to the bottom when a new message is sent
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });

      // Add the message to Firestore
      FirebaseFirestore.instance.collection('circles').doc(widget.circleName).collection('messages').add({
        'senderId': senderId,
        'message': _messageController.text,
        'timestamp': Timestamp.now(),
      }).then((value) {
        // Clear the message controller after sending
        _messageController.clear();
      }).catchError((error) {
        print("Failed to send message: $error");
      });
    }
  }


  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                widget.circleName,
                style: TextStyle(fontSize: 25),
              ),
              Divider(),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('circles').doc(widget.circleName).snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var members = snapshot.data!.get('members') as List<dynamic>;
                    return FutureBuilder(
                      future: firestoreFetcher.convertIDtoUsername(members),
                      builder: (BuildContext context, AsyncSnapshot<List<String>> usernameSnapshot) {
                        if (!usernameSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        List<String> usernames = usernameSnapshot.data!;
                        return ListView.builder(
                          itemCount: usernames.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Color(0xFF66EEEE)),
                                  ),
                                  child: ListTile(
                                    title: Text(usernames[index]),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

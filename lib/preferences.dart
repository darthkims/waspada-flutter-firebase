import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Set<String> caseTypes = Set(); // Set to store unique case types
  String? selectedCaseType; // Currently selected case type for filtering
  bool isLoading = true; // Flag to indicate if data is loading

  @override
  void initState() {
    super.initState();
    listenToReportsCollection();
  }

  void listenToReportsCollection() {
    FirebaseFirestore.instance.collection('reports').get().then((querySnapshot) {
      setState(() {
        caseTypes.clear(); // Clear existing case types
        querySnapshot.docs.forEach((doc) {
          // Access the 'caseType' field from each document
          String? caseType = doc['caseType'];
          if (caseType != null) {
            caseTypes.add(caseType); // Add case type to the set
          } else {
            print("Case Type field not found in document ${doc.id}");
          }
        });
        isLoading = false; // Data loading completed
      });
    }).catchError((error) {
      print("Error getting documents: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case Type Filter Demo'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Filter by Case Type:'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isLoading
                ? CircularProgressIndicator() // Show loading indicator while data is loading
                : DropdownButton<String>(
              value: selectedCaseType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCaseType = newValue;
                });
              },
              items: caseTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20), // Spacer
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedCaseType != null
                  ? FirebaseFirestore.instance.collection('reports').where('caseType', isEqualTo: selectedCaseType).snapshots()
                  : FirebaseFirestore.instance.collection('reports').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data available'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data!.docs[index]['caseType']),
                      // Display other fields as needed
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

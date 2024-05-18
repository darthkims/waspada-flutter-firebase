import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class OfflineHome extends StatefulWidget {
  const OfflineHome({Key? key}) : super(key: key);

  @override
  _OfflineHomeState createState() => _OfflineHomeState();
}

class _OfflineHomeState extends State<OfflineHome> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Users",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['fullname']),
                    subtitle: Text(user['phone'].toString()),
                    // You can add more user details here
                  );
                },
              ),
            ),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFF6798F8)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onPressed: () async {
                  final databasePath = await getDatabasesPath();
                  final path = '$databasePath/waspada.db';
                  print(path);
                  final db = await openDatabase(path);
                  await db.close(); // Close the database when you're done with it

                  // Delete the database file
                  await deleteDatabase(path);
                  print("Database deleted successfully");
                }, child: Text("ff"))
          ],
        ),
      ),
    );
  }

  Future<void> loadUsers() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = '$databasePath/waspada.db';
      final db = await openDatabase(path);

      // Retrieve users from the database
      final List<Map<String, dynamic>> fetchedUsers = await db.query('circle_members');
      setState(() {
        users = fetchedUsers;
      });

      await db.close(); // Close the database
    } catch (e) {
      print("Error loading users: $e");
    }
  }
}

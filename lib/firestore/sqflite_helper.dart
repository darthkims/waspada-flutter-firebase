import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String DATABASE_NAME = "waspada.db";
  static const String TABLE_NAME = "circle_members";
  final firestoresql = FirebaseFirestore.instance.collection('users');

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Future<Database> get database async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/$DATABASE_NAME';
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        print("Creating table circle_members...");
        db.execute('''
      CREATE TABLE $TABLE_NAME (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullname TEXT NOT NULL,
        phone INTEGER NOT NULL,
        userId TEXT NOT NULL
      )
    ''');
        print("Table circle_members created successfully.");
      },
    );

  }

  Future<void> insertUser(CircleMembers members) async {
    print("inserting users");
    final Database db = await database;
    await db.insert(TABLE_NAME, members.toMap());
  }




  Future<void> getUserFromFirebase(String id) async {
    await firestoresql.doc(id).get().then((docSnapshot) async {
      if (docSnapshot.exists) {
        final Map<String, dynamic>? userData = docSnapshot.data() as Map<String, dynamic>?; // Cast to nullable Map
        if (userData != null) {
          final userId = userData['uid'];
          final name = userData['fullName'];
          final phoneNumber = userData['phoneNumber'];
          print("$userId $name $phoneNumber");
          final userDetails = CircleMembers(
            fullname: name,
            phone: phoneNumber,
            userId: userId,
          );
          // Check if the user already exists in the local database
          final existingUser = await getUserById(userId);
          if (existingUser != null) {
            // If the user exists, update the user data
            await updateUserData(userId, userDetails);
          } else {
            // If the user doesn't exist, insert the new user data
            await insertUser(userDetails);
          }

          final allUsers = await getAllUsers();
          allUsers.forEach((user) {
            print('User in DB: ${user.fullname}, ${user.phone}');
          });
        } else {
          print('Unexpected data type for user document');
        }
      }
    });
  }



  Future<CircleMembers?> getUserById(String userId) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      TABLE_NAME,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return CircleMembers.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<void> updateUserData( userId, CircleMembers newUser) async {
    final Database db = await database;
    print("updating db");
    await db.update(
      TABLE_NAME,
      newUser.toMap(),
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }


  Future<List<CircleMembers>> getAllUsers() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(TABLE_NAME);
    print("retrieving users");
    return List.generate(maps.length, (i) {
      final String phoneString = maps[i]['phone'].toString(); // Convert phone to string
      return CircleMembers(
        fullname: maps[i]['fullname'],
        phone: phoneString,
        userId: maps[i]['userId'],
      );
    });
  }


}

class CircleMembers {
  final String userId;
  final String fullname;
  final String phone;

  CircleMembers({
    required this.userId,
    required this.fullname,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullname': fullname,
      'phone': phone,
      'userId': userId,
    };
  }

  factory CircleMembers.fromMap(Map<String, dynamic> map) {
    return CircleMembers(
      fullname: map['fullname'],
      phone: map['phone'].toString(), // Convert int to String
      userId: map['userId'],
    );
  }

}


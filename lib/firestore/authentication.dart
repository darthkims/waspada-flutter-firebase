import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationHelper {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for current user
  get user => auth.currentUser;

  // SIGN UP METHOD
  Future<String?> signUp({required String email, required String password, required String fullName, required String userName}) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Access the user from the userCredential
      User? user = userCredential.user;

      if (user != null) {
        try {
          await user.updateDisplayName(fullName);

          final docRef = _firestore.collection('users').doc(user.uid);
          await docRef.set({
            'fullName': fullName,
            'uid': user.uid,
            'username' : userName,
          });

          return null; // Sign-up successful
        } catch (e) {
          print("Error updating profile: $e");
          return "Error creating account: $e";
        }
      } else {
        return "Failed to create user";
      }
    } on FirebaseAuthException catch (e) {
      return e.message; // Return specific Firebase Auth error message
    } catch (e) {
      print("Unexpected error: $e");
      return "An error occurred. Please try again later."; // Generic error message for other errors
    }
  }

  // SIGN IN METHOD
  Future signIn({required String email, required String password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> getIdToken() async {
    try {
      // Retrieve the user
      User? user = auth.currentUser;

      if (user != null) {
        // Get the ID token
        IdTokenResult tokenResult = await user.getIdTokenResult();

        // Access the token
        String? idToken = tokenResult.token;

        return idToken;
      } else {
        // User is not signed in
        return null;
      }
    } catch (e) {
      print("Error retrieving ID token: $e");
      return null;
    }
  }

  // SIGN OUT METHOD
  Future<void> signOut() async {
    print('User logout');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Remove the token from SharedPreferences
    prefs.remove('refreshToken');
    // Sign out the user from FirebaseAuth
    await auth.signOut();
  }
  // Getter for user email
  String? getUserEmail() {
    return auth.currentUser?.email;
  }
}

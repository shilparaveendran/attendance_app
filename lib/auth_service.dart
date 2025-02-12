import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Save user info in Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": name,  // ✅ Save the name
          "email": email,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("❌ Error signing up: $e");
      return null;
    }
  }


  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

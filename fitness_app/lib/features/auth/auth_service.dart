import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(String email, String password, String firstName) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;
      
      // 2. Save extra user data to Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          // CRITICAL: Add these defaults so Home Screen doesn't crash
          'height': 0, 
          'weight': 0,
          'age': 0,
        });
      }
      
      return user;
    } catch (e) {
      // It is better to rethrow the error so the UI can show a SnackBar
      // e.g., "Email already in use" or "Weak password"
      print("Signup Error: ${e.toString()}"); 
      throw e; 
    }
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Login Error: ${e.toString()}");
      throw e;
    }
  }
  
  // Sign Out (You will need this later)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
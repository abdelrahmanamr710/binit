import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Import UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? phone, // Make phone optional
    String? taxId, // Make taxId optional
    String? address,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        // Create a UserModel instance.
        final UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          userType: userType,
          phone: phone,
          taxId: taxId,
        );

        // Convert the UserModel to a JSON map.
        final Map<String, dynamic> userData = newUser.toJson();

        // Use the set method to create a document with the user's UID.  This will overwrite any existing document with the user's UID.
        await _firestore.collection('users').doc(user.uid).set(userData);

        return newUser;
      }
      return null;
    } catch (error) {
      print('Error signing up: $error');
      throw _handleSignUpError(error);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          // Ensure that userData is not null and is a map.
          if (userData != null && userData is Map<String, dynamic>) {
            try {
              return UserModel.fromJson(userData);
            } catch (e) {
              print("Error decoding user data: $e.  Data: $userData");
              return null; // Or throw an exception if you want to handle it differently
            }
          }
          else{
            print("Error: userData is null or not a map");
            return null;
          }
        }
        return null;
      }
      return null;
    } catch (error) {
      print('Error signing in: $error');
      throw _handleSignInError(error);
    }
  }

  // Helper method to handle sign up errors
  Exception _handleSignUpError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return Exception('The password is too weak.');
        case 'email-already-in-use':
          return Exception('The email address is already in use.');
        case 'invalid-email':
          return Exception('The email address is invalid.');
        default:
          return Exception('Failed to sign up: ${error.message}');
      }
    }
    return Exception('Failed to sign up: $error');
  }

  // Helper method to handle sign in errors
  Exception _handleSignInError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('User not found.');
        case 'wrong-password':
          return Exception('Invalid password.');
        case 'invalid-email':
          return Exception('Invalid email address.');
        default:
          return Exception('Failed to sign in: ${error.message}');
      }
    }
    return Exception('Failed to sign in: $error');
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}


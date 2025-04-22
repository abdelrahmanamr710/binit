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
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          userType: userType,
          phone: phone, // Store phone
          taxId: taxId, // Store taxId
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
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
            return UserModel.fromJson(userData);
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

  // Change password
  Future<void> changePassword({required String email, required String oldPassword, required String newPassword}) async {
    try {
      // 1. Re-authenticate the user
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: oldPassword,
      );

      final User? user = userCredential.user;


      if (user == null) {
        throw Exception('User not found.');
      }
      // 2. Update the password
      await user.updatePassword(newPassword);

      print('Password changed successfully.');

    } on FirebaseAuthException catch (e) {
      print('Error changing password: ${e.message}');
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password is too weak.');
        case 'requires-recent-login':
          throw Exception('Requires recent login. Please sign in again.');
        default:
          throw Exception('Failed to change password: ${e.message}');
      }
    } catch (error) {
      print('Error changing password: $error');
      throw Exception('Failed to change password: $error');
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      // 1. Get a reference to the user document in Firestore.
      final DocumentReference userRef = _firestore.collection('users').doc(user.uid);

      // 2.  Update the fields.
      await userRef.update(user.toJson()); //  use the toJson() method of your UserModel
      print('User profile updated successfully.');


    } catch (error) {
      print('Error updating user profile: $error');
      throw Exception('Failed to update user profile: $error');
    }
  }
}


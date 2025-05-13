import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart'; // Import UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Check if user is already signed in and return user data
  Future<UserModel?> getCurrentUser() async {
    try {
      print('Checking current user status...');
      // First check Firebase Auth's current user
      User? currentUser = _auth.currentUser;
      print('Firebase current user: ${currentUser?.email}');
      
      String? storedEmail = await _storage.read(key: 'email');
      String? storedUid = await _storage.read(key: 'uid');
      print('Stored credentials - Email: $storedEmail, UID: $storedUid');
      
      // If Firebase has current user, verify and return user data
      if (currentUser != null) {
        print('Fetching user document for uid: ${currentUser.uid}');
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          print('User document exists in Firestore');
          // Update stored credentials if they don't match
          if (storedEmail != currentUser.email || storedUid != currentUser.uid) {
            print('Updating stored credentials');
            await _storage.write(key: 'email', value: currentUser.email);
            await _storage.write(key: 'uid', value: currentUser.uid);
          }
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          return UserModel.fromJson(userData);
        } else {
          print('No Firestore document found for current user');
        }
      } else {
        print('No current Firebase user found');
      }
      
      // If no current user but have stored credentials, try to sign in
      if (storedEmail != null && storedUid != null) {
        print('Attempting to use stored credentials');
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(storedUid).get();
        if (userDoc.exists) {
          print('Found user document using stored credentials');
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          return UserModel.fromJson(userData);
        } else {
          print('No user document found for stored credentials');
          // Clear invalid stored credentials
          await _storage.deleteAll();
          print('Cleared invalid stored credentials');
        }
      }
      print('No valid user found, returning null');
      return null;
    } catch (error) {
      print('Error getting current user: $error');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

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
        await user.updateDisplayName(name); // Set Firebase display name
        await user.reload(); // Reload user to apply changes

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
          if (userData != null && userData is Map<String, dynamic>) {
            // Store user credentials securely
            await _storage.write(key: 'email', value: email);
            await _storage.write(key: 'uid', value: user.uid);
            return UserModel.fromJson(userData);
          } else {
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
          return Exception('No user found with this email.');
        case 'wrong-password':
          return Exception('Wrong password.');
        case 'invalid-email':
          return Exception('Invalid email address.');
        case 'user-disabled':
          return Exception('This account has been disabled.');
        default:
          return Exception('An error occurred while signing in.');
      }
    }
    return Exception('An unexpected error occurred.');
  }

  // Sign out and clear stored credentials
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.deleteAll(); // Clear all stored credentials
    } catch (error) {
      print('Error signing out: $error');
      throw Exception('Failed to sign out.');
    }
  }

  // Change password
  Future<void> changePassword({required String email, required String oldPassword, required String newPassword}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: oldPassword,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User not found.');
      }
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
      final DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update(user.toJson());
      print('User profile updated successfully.');
    } catch (error) {
      print('Error updating user profile: $error');
      throw Exception('Failed to update user profile: $error');
    }
  }
}

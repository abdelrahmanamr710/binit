// pigeon.dart
import 'package:pigeon/pigeon.dart';

// Pigeon file defining the API for communication between Flutter and native platforms.

@ConfigurePigeon(PigeonOptions(
  // Dart out file will be generated in the same directory.
  dartOut: 'lib/src/pigeon.g.dart',
  //  objective-c output
  objcOptions: ObjcOptions(
      prefix: 'Pigeon'
  ),
  //  java output configuration
  javaOptions: JavaOptions(
    package: 'com.example.pigeon',
  ),
  // C++ output
  cppOptions: CppOptions(
    namespace: 'pigeon',
  ),
))
// Class for User details.  Used to transfer user data.
class UserDetails {
  String? uid;
  String? email;
  String? name;
}

//  defining the API for user authentication
@HostApi()
abstract class AuthApi {
  UserDetails? getCurrentUser();
  @async
  UserDetails? signInWithEmail(String email, String password);
  @async
  UserDetails? signUpWithEmail(String email, String password, String name);
  void signOut();
}

//  defining the API for Firestore communication
@HostApi()
abstract class FirestoreApi {
  Map<String?, String?>? getDocument(String collection, String documentId);
  void setDocument(String collection, String documentId, Map<String?, String?> data);
  void deleteDocument(String collection, String documentId);
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Temporarily removed Google Sign-In for internal app focus
// import 'package:google_sign_in/google_sign_in.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Temporarily removed Google Sign-In for internal app focus
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Temporarily disabled Google Sign-In for internal app focus
  Future<UserCredential?> signInWithGoogle() async {
    // Temporarily return null to bypass authentication
    // TODO: Re-enable Google Sign-In later
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // await _googleSignIn.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

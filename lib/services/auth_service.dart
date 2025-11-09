// @ lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Import Firestore

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // 2. Create a Firestore instance

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp(String email, String password) async {
    // 3. Create the user
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    // 4. After creation, save their email to the 'users' collection
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': credential.user!.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 5. Send the verification email
    await sendVerification();
  }

  Future<void> sendVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signIn(String email, String password) => _auth.signInWithEmailAndPassword(email: email, password: password);
  Future<void> signOut() => _auth.signOut();
}

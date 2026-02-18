import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;
  final _firestore = FirebaseFirestore.instance;

  AuthService(this._auth);
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> loginWithUsername(String username, String password) async {
    // 🔎 Chercher user par username
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Username introuvable");
    }

    final email = query.docs.first['email'];

    // 🔐 Login avec email récupéré
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;

    if (user == null) {
      throw Exception("User non créé");
    }
    await user.reload();

    await _firestore.collection('users').doc(user.uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> createAccount(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Cet email est déjà utilisé';
      if (e.code == 'weak-password') return 'Mot de passe trop faible';
      if (e.code == 'invalid-email') return 'Email invalide';
      return 'Erreur: ${e.message}';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Aucun compte avec cet email';
      if (e.code == 'wrong-password') return 'Mot de passe incorrect';
      if (e.code == 'invalid-credential') return 'Email ou mot de passe incorrect';
      return 'Erreur: ${e.message}';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
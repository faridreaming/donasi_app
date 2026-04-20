import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi Register
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageFromAuthException(e));
    } catch (e) {
      throw Exception('Registrasi gagal: $e');
    }
  }

  // Fungsi Login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageFromAuthException(e));
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  String _messageFromAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email belum terdaftar.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah, minimal 6 karakter.';
      default:
        return error.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}

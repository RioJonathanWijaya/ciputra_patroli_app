import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  StreamSubscription<User?>? _authStateSubscription;

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  User? get user => _user;

  AuthService() {
    // Don't initialize auth state listener in constructor
  }

  Future<void> initialize() async {
    try {
      _authStateSubscription?.cancel();
      _authStateSubscription = auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
      log("Authentication service has been initialized");
    } catch (e) {
      log("Failed to initialize authentication service: $e");
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      if (_authStateSubscription == null) {
        await initialize();
      }

      final UserCredential cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _user = auth.currentUser;
      log("User ${_user?.email} has logged in successfully");
      return _user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage = 'Password yang Anda masukkan salah';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        case 'user-disabled':
          errorMessage = 'Akun telah dinonaktifkan';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password yang Anda masukkan salah';
          break;
        default:
          errorMessage = 'Terjadi kesalahan saat login: ${e.message}';
      }
      log("Login failed: $errorMessage");
      throw errorMessage;
    } catch (e) {
      log("An unexpected error occurred during login: $e");
      throw 'Terjadi kesalahan saat login: $e';
    }
  }

  Future<void> signOutUser() async {
    try {
      await auth.signOut();
      _user = null;
      notifyListeners();
      log("User has been signed out successfully");
    } catch (e) {
      log("Failed to sign out user: $e");
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

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
      // Initialize auth state listener only when needed
      _authStateSubscription?.cancel();
      _authStateSubscription = auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
      log("AuthService initialized successfully");
    } catch (e) {
      log("AuthService initialization error: $e");
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      log("Signing in with: Email: $email, Password: $password");

      // Initialize if not already done
      if (_authStateSubscription == null) {
        await initialize();
      }

      final UserCredential cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _user = auth.currentUser;
      log("Login successful: ${_user?.email}");
      return _user;
    } catch (e) {
      log("[AuthService] Login failed: $e");
      return null;
    }
  }

  Future<void> signOutUser() async {
    try {
      await auth.signOut();
      _user = null;
      notifyListeners();
      log("User signed out");
    } catch (e) {
      log("Logout failed: $e");
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

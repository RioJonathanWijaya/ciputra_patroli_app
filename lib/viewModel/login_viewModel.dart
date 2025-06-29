import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ciputra_patroli/auth/auth_service.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/satpam.dart';
import 'package:ciputra_patroli/services/notification_service.dart';
import 'dart:developer';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  static const String _sessionKey = 'login_session';
  static const String _satpamIdKey = 'satpam_id';
  static const int _sessionTimeoutHours = 12;

  bool _isLoading = false;
  bool _isInitialized = false;
  Satpam? _satpam;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Satpam? get satpam => _satpam;
  String? get satpamId => _satpam?.satpamId;
  bool get isLoggedIn => _satpam != null;

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await _authService.initialize();
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        log("Failed to initialize login view model: $e");
        rethrow;
      }
    }
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email dan password tidak boleh kosong');
    }

    _setLoading(true);
    try {
      log("Starting login process...");
      final user = await _authService.loginUser(email, password);

      if (user == null) {
        throw Exception('Email atau password yang Anda masukkan salah');
      }

      try {
        await fetchSatpamData(user.uid);
        log("User data has been retrieved successfully");

        if (_satpam != null) {
          await saveSession(_satpam!.satpamId);
          log("User session has been saved");

          final notificationService = NotificationService();
          await notificationService.initNotification();
          await updateFcmToken();
          log("Notifications have been initialized");

          _firebaseService.setupTokenRefreshListener(_satpam!.satpamId);
          log("Token refresh listener has been set up");

          await NavigationService.navigateTo('/home', clearStack: true);
          log("User has been redirected to home page");
        } else {
          log("User data not found in the system");
          throw Exception(
              'Data satpam tidak ditemukan. Silakan hubungi admin.');
        }
      } catch (e) {
        log("Failed to fetch user data: $e");
        await _authService.signOutUser();
        rethrow;
      }
    } catch (e) {
      log("Login process failed: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSatpamData(String satpamId) async {
    try {
      _satpam = await _apiService.getSatpamById(satpamId);
      notifyListeners();
    } catch (e) {
      log("Failed to fetch satpam data: $e");
      rethrow;
    }
  }

  Future<void> loadSession() async {
    try {
      log("Loading saved session...");
      final prefs = await SharedPreferences.getInstance();
      final savedSatpamId = prefs.getString(_satpamIdKey);

      if (savedSatpamId != null) {
        if (await isSessionValid()) {
          await fetchSatpamData(savedSatpamId);

          if (_satpam != null) {
            final notificationService = NotificationService();
            await notificationService.initNotification();
            await updateFcmToken();
            _firebaseService.setupTokenRefreshListener(_satpam!.satpamId);
            log("Auto-login completed successfully");
          }
        } else {
          log("Session has expired, clearing data");
          await clearSession();
        }
      } else {
        log("No saved session found");
      }
    } catch (e) {
      log("Failed to load session: $e");
      await clearSession();
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getInt(_sessionKey);
      final savedSatpamId = prefs.getString(_satpamIdKey);

      if (lastLogin == null || savedSatpamId == null) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration =
          Duration(hours: _sessionTimeoutHours).inMilliseconds;
      final isValid = (now - lastLogin) < sessionDuration;

      if (!isValid) {
        log("Session has expired");
        await clearSession();
      }

      return isValid;
    } catch (e) {
      log("Failed to validate session: $e");
      return false;
    }
  }

  Future<void> saveSession(String satpamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      await Future.wait([
        prefs.setString(_satpamIdKey, satpamId),
        prefs.setInt(_sessionKey, now)
      ]);

      log("Session has been saved for satpam: $satpamId");
    } catch (e) {
      log("Failed to save session: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(false);
      await _authService.signOutUser();
      _satpam = null;
      await clearSession();
      notifyListeners();
      final currentContext = NavigationService.navigatorKey.currentContext;
      final currentRoute = ModalRoute.of(currentContext!)?.settings.name;
      if (currentRoute != '/login') {
        await NavigationService.navigateTo('/login', clearStack: true);
      }
      log("User has been logged out successfully");
    } catch (e) {
      log("Failed to logout: $e");
      rethrow;
    }
  }

  Future<void> updateFcmToken() async {
    try {
      if (satpam != null && satpam!.satpamId.isNotEmpty) {
        final token = await _firebaseService.getFcmToken();
        if (token != null) {
          await _firebaseService.updateSatpamFcmToken(satpam!.satpamId);
          log("FCM token has been updated for satpam: ${satpam!.satpamId}");
        } else {
          log("No FCM token is available");
        }
      }
    } catch (e) {
      log("Failed to update FCM token: $e");
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait(
          [prefs.remove(_sessionKey), prefs.remove(_satpamIdKey)]);
      _satpam = null;
      notifyListeners();
      log("Session data has been cleared");
    } catch (e) {
      log("Failed to clear session: $e");
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void resetLoadingState() {
    _setLoading(false);
  }
}

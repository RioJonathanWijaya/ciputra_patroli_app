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

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await _authService.initialize();
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        print('Error initializing LoginViewModel: $e');
        rethrow;
      }
    }
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;

    _setLoading(true);
    try {
      log('[DEBUG] Starting login process...');
      final user = await _authService.loginUser(email, password);
      log('[DEBUG] Firebase auth successful, user: ${user?.uid}');

      if (user != null) {
        log('[DEBUG] Fetching satpam data...');
        try {
          await fetchSatpamData(user.uid);
          log('[DEBUG] Satpam data fetched: ${_satpam?.toString()}');

          if (_satpam != null) {
            log('[DEBUG] Saving session...');
            await saveSession(_satpam!.satpamId);
            log('[DEBUG] Session saved successfully');

            final notificationService = NotificationService();
            await notificationService.initNotification();
            await updateFcmToken();
            log('[DEBUG] Notifications initialized');

            log('[DEBUG] Setting up token refresh listener...');
            _firebaseService.setupTokenRefreshListener(_satpam!.satpamId);
            log('[DEBUG] Token refresh listener setup complete');

            log('[DEBUG] Attempting navigation to home page...');
            await NavigationService.navigateTo('/home', clearStack: true);
            log('[DEBUG] Navigation to home page completed');
            return true;
          } else {
            log('[ERROR] Satpam data is null after fetch');
            throw Exception('Satpam data not found. Please contact support.');
          }
        } catch (e) {
          log('[ERROR] Error fetching satpam data: $e');
          await _authService.signOutUser();
          rethrow;
        }
      }
      log('[ERROR] Firebase auth returned null user');
      return false;
    } catch (e, stackTrace) {
      log('[ERROR] Login error: $e');
      log('[STACKTRACE] $stackTrace');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSatpamData(String satpamId) async {
    try {
      _satpam = await _apiService.getSatpamById(satpamId);
      notifyListeners();
    } catch (e) {
      print('Error fetching satpam data: $e');
      rethrow;
    }
  }

  Future<void> loadSession() async {
    try {
      log('[DEBUG] Loading session...');
      final prefs = await SharedPreferences.getInstance();
      final savedSatpamId = prefs.getString(_satpamIdKey);

      if (savedSatpamId != null) {
        log('[DEBUG] Found saved satpam ID: $savedSatpamId');
        if (await isSessionValid()) {
          log('[DEBUG] Session is valid, fetching satpam data...');
          await fetchSatpamData(savedSatpamId);

          if (_satpam != null) {
            log('[DEBUG] Initializing notifications for auto-login...');
            final notificationService = NotificationService();
            await notificationService.initNotification();
            await updateFcmToken();
            _firebaseService.setupTokenRefreshListener(_satpam!.satpamId);
            log('[DEBUG] Auto-login successful');
          }
        } else {
          log('[DEBUG] Session expired, clearing session data...');
          await clearSession();
        }
      } else {
        log('[DEBUG] No saved session found');
      }
    } catch (e, stackTrace) {
      log('[ERROR] Error loading session: $e');
      log('[STACKTRACE] $stackTrace');
      await clearSession();
    }
  }

  Future<bool> isSessionValid() async {
    try {
      log('[DEBUG] Checking session validity...');
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getInt(_sessionKey);
      final savedSatpamId = prefs.getString(_satpamIdKey);

      if (lastLogin == null || savedSatpamId == null) {
        log('[DEBUG] No session data found');
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration =
          Duration(hours: _sessionTimeoutHours).inMilliseconds;
      final isValid = (now - lastLogin) < sessionDuration;

      log('[DEBUG] Session check - Last login: ${DateTime.fromMillisecondsSinceEpoch(lastLogin)}, Valid: $isValid');

      if (!isValid) {
        log('[DEBUG] Session expired, clearing session data...');
        await clearSession();
      }

      return isValid;
    } catch (e, stackTrace) {
      log('[ERROR] Error checking session: $e');
      log('[STACKTRACE] $stackTrace');
      return false;
    }
  }

  Future<void> saveSession(String satpamId) async {
    try {
      log('[DEBUG] Saving session for satpam: $satpamId');
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      await Future.wait([
        prefs.setString(_satpamIdKey, satpamId),
        prefs.setInt(_sessionKey, now)
      ]);

      log('[DEBUG] Session saved successfully at ${DateTime.fromMillisecondsSinceEpoch(now)}');
    } catch (e, stackTrace) {
      log('[ERROR] Error saving session: $e');
      log('[STACKTRACE] $stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOutUser();
      _satpam = null;
      await clearSession();
      notifyListeners();
      await NavigationService.navigateTo('/login', clearStack: true);
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> updateFcmToken() async {
    try {
      if (satpam != null && satpam!.satpamId.isNotEmpty) {
        final token = await _firebaseService.getFcmToken();
        if (token != null) {
          await _firebaseService.updateSatpamFcmToken(satpam!.satpamId);
          log('FCM token updated successfully for satpam ${satpam!.satpamId}');
        } else {
          log('Failed to get FCM token');
        }
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      log('[DEBUG] Clearing session data...');
      final prefs = await SharedPreferences.getInstance();
      await Future.wait(
          [prefs.remove(_sessionKey), prefs.remove(_satpamIdKey)]);
      _satpam = null;
      notifyListeners();
      log('[DEBUG] Session data cleared successfully');
    } catch (e, stackTrace) {
      log('[ERROR] Error clearing session: $e');
      log('[STACKTRACE] $stackTrace');
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

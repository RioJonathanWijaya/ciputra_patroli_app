import 'dart:developer';
import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/patroli_checkpoint.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models/satpam.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';

class PatroliViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LoginViewModel _loginViewModel;
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  ApiService get apiService => _apiService;

  Satpam? _satpam;
  bool _isLoading = false;

  Satpam? get satpam => _satpam;
  bool get isLoading => _isLoading;

  Patroli? _currentPatroli;
  Patroli? get currentPatroli => _currentPatroli;

  List<PatroliCheckpoint> _checkpoints = [];
  bool _isDisposed = false;
  bool _isPatroliActive = false;
  bool _isLocationTracking = false;
  DateTime? _lastLocationUpdate;
  static const Duration _locationUpdateInterval = Duration(seconds: 30);

  PatroliViewModel(this._loginViewModel) {
    loadSatpamData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopLocationTracking();
    super.dispose();
  }

  Future<void> loadSatpamData() async {
    final satpamId = _loginViewModel.satpamId;
    log("Loading satpam data for ID: $satpamId");

    if (satpamId != null) {
      _setLoading(true);

      try {
        _satpam = _loginViewModel.satpam;
        if (_satpam != null) {
          log("Satpam data loaded successfully");
          log("Satpam details - ID: ${_satpam?.satpamId}, Name: ${_satpam?.nama}, NIP: ${_satpam?.nip}");
        } else {
          log("Satpam data not found after loading");
        }
      } catch (e) {
        log("Failed to load satpam data: $e");
      } finally {
        _setLoading(false);
      }
    } else {
      log("No satpam ID found in session");
    }
  }

  Future<void> createPatroli({
    required String satpamId,
    required String lokasiId,
    required String penugasanId,
    required String jadwalPatroliId,
  }) async {
    log("Starting patrol creation process");
    log("Patrol parameters - Satpam ID: $satpamId, Location ID: $lokasiId, Assignment ID: $penugasanId, Schedule ID: $jadwalPatroliId");

    try {
      _setLoading(true);

      final patroliId = const Uuid().v4();
      log("Generated patrol ID: $patroliId");

      _currentPatroli = Patroli(
        id: patroliId,
        jamMulai: DateTime.now(),
        jamSelesai: null,
        durasiPatroli: Duration.zero,
        catatanPatroli: '',
        rutePatroli: ' ',
        satpamId: satpamId,
        lokasiId: lokasiId,
        jadwalPatroliId: jadwalPatroliId,
        penugasanId: penugasanId,
        isTerlambat: false,
        tanggal: DateTime.now(),
      );

      log("Saving initial patrol data to Firebase");
      await _firebaseService.savePatroli(_currentPatroli!);
      log("Initial patrol data saved successfully");

      notifyListeners();
    } catch (e) {
      _currentPatroli = null;
      log("Failed to create patrol: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitCheckpoint({
    required Patroli patroli,
    required Penugasan penugasan,
    required int currentIndex,
    required String checkpointName,
    required double latitude,
    required double longitude,
    required String? buktiImage,
    required String? catatan,
  }) async {
    try {
      log('[DEBUG] Submitting checkpoint for patroli: ${patroli.id}');

      if (_currentPatroli == null) {
        log('[ERROR] Cannot submit checkpoint: currentPatroli is null');
        throw Exception('Data patroli tidak ditemukan');
      }

      log('[DEBUG] Fetching current location...');
      LatLng? currentLocation = await _locationService.fetchCurrentLocation();
      if (currentLocation == null) {
        throw Exception('Failed to fetch current location');
      }
      log('[DEBUG] Current location fetched: ${currentLocation.latitude}, ${currentLocation.longitude}');

      final distanceStatus =
          _checkDistance(currentLocation, latitude, longitude);
      final isLate = _checkLateness(DateTime.now());
      final status = isLate ? 'Late' : 'On Time';
      final statusJarak = distanceStatus ? 'Close' : 'Far';

      final newCheckpoint = PatroliCheckpoint(
        patroliId: _currentPatroli!.id,
        checkpointName: checkpointName,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().toIso8601String(),
        imagePath: buktiImage,
        keterangan: catatan,
        status: status,
        distanceStatus: statusJarak,
        currentLatitude: currentLocation.latitude,
        currentLongitude: currentLocation.longitude,
        isLate: isLate,
      );

      log('[DEBUG] Saving checkpoint to Firebase...');
      await _firebaseService.saveCheckpoint(newCheckpoint);
      log('[DEBUG] Checkpoint saved to Firebase successfully');

      _currentPatroli!.addCheckpoint({
        'id': newCheckpoint.id,
        'timestamp': newCheckpoint.timestamp,
        'status': newCheckpoint.status,
      });

      notifyListeners();
      return;
    } catch (e) {
      log('[ERROR] Error submitting checkpoint: $e');
      rethrow;
    }
  }

  bool _checkDistance(LatLng currentLocation, double checkpointLatitude,
      double checkpointLongitude) {
    if (_currentPatroli == null || _currentPatroli!.checkpoints.isEmpty) {
      return false;
    }

    final distanceInMeters = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      checkpointLatitude,
      checkpointLongitude,
    );
    return distanceInMeters <= 50 ? true : false;
  }

  bool _checkLateness(DateTime currentTimestamp) {
    if (_currentPatroli == null || _currentPatroli!.checkpoints.isEmpty) {
      return false;
    }

    final lastCheckpoint = _currentPatroli!.checkpoints.last;
    final lastTimestamp = DateTime.parse(lastCheckpoint['timestamp']);

    final difference = currentTimestamp.difference(lastTimestamp).inMinutes;
    return difference > 15;
  }

  bool _checkTerlambat(String penugasanJamPatroli) {
    DateFormat format = DateFormat('HH:mm');
    DateTime jamPatroli = format.parse(penugasanJamPatroli);
    DateTime todayJamPatroli = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      jamPatroli.hour,
      jamPatroli.minute,
    );

    if (_currentPatroli!.jamMulai!.difference(todayJamPatroli).inMinutes >
        120) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> endPatroli({
    required String catatanPatroli,
    required Penugasan penugasan,
    required BuildContext context,
  }) async {
    if (_currentPatroli == null) {
      throw Exception('Data patroli tidak ditemukan');
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        log('[DEBUG] Updating patroli data...');
        _currentPatroli!.catatanPatroli = catatanPatroli;
        _currentPatroli!.jamSelesai = DateTime.now();

        if (_currentPatroli!.jamMulai != null &&
            _currentPatroli!.jamSelesai != null) {
          final duration = _currentPatroli!.jamSelesai!
              .difference(_currentPatroli!.jamMulai!);
          _currentPatroli!.durasiPatroli = duration;
          _currentPatroli!.isTerlambat = _checkTerlambat(penugasan.jamPatroli);
        }
        log('[DEBUG] Patroli data updated successfully');

        log('[DEBUG] Saving patroli data to API...');
        log('[DEBUG] Final patroli data to save: ${_currentPatroli!.toMap()}');
        await _apiService.savePatroli(_currentPatroli!.toMap());
        log('[DEBUG] Patroli data saved successfully to API');

        log('[DEBUG] Updating patroli data in Firebase...');
        await _firebaseService.savePatroli(_currentPatroli!);
        log('[DEBUG] Patroli data updated successfully in Firebase');

        log('[DEBUG] Refreshing patroli stats...');
        await _apiService.refreshPatroliStats();
        log('[DEBUG] Stats refreshed successfully');

        _currentPatroli = null;
        log('[DEBUG] Cleared patroli from memory');

        NavigationService.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patroli berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );

        log('[DEBUG] Navigating to patroli jadwal page');
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/patroliJadwal');
        }
      } catch (e, stackTrace) {
        NavigationService.pop();

        log('[ERROR] Failed to end patroli: $e');
        log('[STACKTRACE] $stackTrace');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan patroli: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      log('[ERROR] Error in endPatroli: $e');
      log('[STACKTRACE] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void savePatroli() {
    _firebaseService.savePatroli(_currentPatroli!);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> deleteTemporaryPatroli() async {
    if (_currentPatroli == null) return;

    try {
      await _firebaseService.deletePatroli(_currentPatroli!.id);
      log("Temporary patrol data deleted successfully");

      _currentPatroli = null;
      _isPatroliActive = false;
      _checkpoints.clear();
      stopLocationTracking();
      notifyListeners();
    } catch (e) {
      log("Failed to delete temporary patrol data: $e");
    }
  }

  void startLocationTracking() {
    if (_isLocationTracking) return;

    _isLocationTracking = true;
    _lastLocationUpdate = DateTime.now();
    _checkLocationUpdates();
    log("Location tracking has been started");
  }

  void stopLocationTracking() {
    _isLocationTracking = false;
    log("Location tracking has been stopped");
  }

  void _checkLocationUpdates() {
    if (_isLocationTracking) {
      final now = DateTime.now();
      final difference = now.difference(_lastLocationUpdate!);

      if (difference >= _locationUpdateInterval) {
        _lastLocationUpdate = now;
        _checkLocation();
      }

      Future.delayed(Duration.zero, _checkLocationUpdates);
    }
  }

  void _checkLocation() {
    // Implementation of _checkLocation method
  }
}

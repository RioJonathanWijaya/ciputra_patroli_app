import 'dart:developer';
import 'dart:io';
import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/patroli_checkpoint.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/services/location_service.dart'; // Add LocationService import
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart'; // Import LatLng
import 'package:uuid/uuid.dart';

import '../models/satpam.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';

class PatroliViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LoginViewModel _loginViewModel;
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService =
      LocationService(); // Instance of LocationService

  // Make apiService accessible
  ApiService get apiService => _apiService;

  Satpam? _satpam;
  bool _isLoading = false;

  Satpam? get satpam => _satpam;
  bool get isLoading => _isLoading;

  Patroli? _currentPatroli;
  Patroli? get currentPatroli => _currentPatroli;

  PatroliViewModel(this._loginViewModel) {
    loadSatpamData();
  }

  Future<void> loadSatpamData() async {
    final satpamId = _loginViewModel.satpamId;
    log('[DEBUG] PatroliViewModel: Starting loadSatpamData, satpamId: $satpamId');

    if (satpamId != null) {
      log('[DEBUG] PatroliViewModel: Loading Satpam data...');
      _setLoading(true);

      try {
        _satpam = _loginViewModel.satpam;
        if (_satpam != null) {
          log('[DEBUG] PatroliViewModel: Satpam data loaded successfully');
          log('[DEBUG] PatroliViewModel: Satpam details - ID: ${_satpam?.satpamId}, Name: ${_satpam?.nama}, NIP: ${_satpam?.nip}');
        } else {
          log('[ERROR] PatroliViewModel: Satpam data is null after loading');
        }
      } catch (e, stacktrace) {
        log('[ERROR] PatroliViewModel: Failed to load Satpam data');
        log('[ERROR] PatroliViewModel: Error details: $e');
        log('[STACKTRACE] $stacktrace');
      } finally {
        _setLoading(false);
        log('[DEBUG] PatroliViewModel: loadSatpamData completed, isLoading: $_isLoading');
      }
    } else {
      log('[WARNING] PatroliViewModel: No Satpam ID found in session');
    }
  }

  Future<void> createPatroli({
    required String satpamId,
    required String lokasiId,
    required String penugasanId,
    required String jadwalPatroliId,
  }) async {
    log('[DEBUG] PatroliViewModel: Starting createPatroli');
    log('[DEBUG] PatroliViewModel: Creating patroli with parameters:');
    log('[DEBUG] satpamId: $satpamId');
    log('[DEBUG] lokasiId: $lokasiId');
    log('[DEBUG] penugasanId: $penugasanId');
    log('[DEBUG] jadwalPatroliId: $jadwalPatroliId');
    log('[DEBUG] Current patroli before creation: ${_currentPatroli?.toMap()}');

    try {
      _setLoading(true);

      final patroliId = const Uuid().v4();
      log('[DEBUG] Generated patroli ID: $patroliId');

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

      notifyListeners();
    } catch (e) {
      _currentPatroli = null; // Clear the patroli on error
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

      // Get current location
      log('[DEBUG] Fetching current location...');
      LatLng? currentLocation = await _locationService.fetchCurrentLocation();
      if (currentLocation == null) {
        throw Exception('Failed to fetch current location');
      }
      log('[DEBUG] Current location fetched: ${currentLocation.latitude}, ${currentLocation.longitude}');

      // Check distance and lateness
      final distanceStatus =
          _checkDistance(currentLocation, latitude, longitude);
      final isLate = _checkLateness(DateTime.now());
      final status = isLate ? 'Late' : 'On Time';
      final statusJarak = distanceStatus ? 'Close' : 'Far';

      // Create new checkpoint
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
      );

      // Save checkpoint directly to Firebase
      log('[DEBUG] Saving checkpoint to Firebase...');
      await _firebaseService.saveCheckpoint(newCheckpoint);
      log('[DEBUG] Checkpoint saved to Firebase successfully');

      // Only store minimal checkpoint info in memory
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
    final distanceInMeters = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      checkpointLatitude,
      checkpointLongitude,
    );
    return distanceInMeters <= 25 ? true : false;
  }

  bool _checkLateness(DateTime currentTimestamp) {
    if (_currentPatroli == null || _currentPatroli!.checkpoints.isEmpty)
      return false;

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
    try {
      if (_currentPatroli == null) {
        log('[ERROR] Cannot end patroli: _currentPatroli is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Data patroli tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      log('[DEBUG] Preparing to end patroli: ${_currentPatroli!.id}');
      log('[DEBUG] Current patroli state: ${_currentPatroli!.toMap()}');

      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah Anda yakin ingin menyelesaikan patroli?'),
              const SizedBox(height: 8),
              Text(
                'Patroli ID: ${_currentPatroli!.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Jumlah Checkpoint: ${_currentPatroli!.checkpoints.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        log('[DEBUG] User cancelled ending patroli');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Update patroli data
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

        // Save the patroli data to Firebase
        log('[DEBUG] Saving patroli data to Firebase...');
        log('[DEBUG] Final patroli data to save: ${_currentPatroli!.toMap()}');
        await _firebaseService.savePatroli(_currentPatroli!);
        log('[DEBUG] Patroli data saved successfully to Firebase');

        // Refresh stats
        log('[DEBUG] Refreshing patroli stats...');
        await _apiService.refreshPatroliStats();
        log('[DEBUG] Stats refreshed successfully');

        // Clear the current patroli from memory
        _currentPatroli = null;
        log('[DEBUG] Cleared patroli from memory');

        // Close loading indicator
        NavigationService.pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patroli berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to patroli_jadwal_page
        log('[DEBUG] Navigating back to patroli jadwal page');
        await NavigationService.navigateTo('/patroliJadwal', clearStack: true);
      } catch (e, stackTrace) {
        // Close loading indicator
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
}

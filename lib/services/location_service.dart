import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:latlong2/latlong.dart';
import 'dart:developer';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  final loc.Location _location = loc.Location();
  LatLng? currentPosition;
  bool isInitialized = false;

  LocationService._internal();

  Future<void> initialize() async {
    if (!await _checkRequestPermission()) return;

    _location.onLocationChanged.listen((loc.LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        currentPosition =
            LatLng(locationData.latitude!, locationData.longitude!);
        isInitialized = true;
      }
    });
  }

  Future<bool> _checkRequestPermission() async {
    perm.PermissionStatus status =
        await perm.Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await perm.Permission.locationWhenInUse.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      perm.openAppSettings();
      return false;
    }

    return false;
  }

  Future<LatLng?> fetchCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('[ERROR] Location services are disabled.');
        return null;
      }

      // Check and request permissions if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('[ERROR] Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('[ERROR] Location permissions are permanently denied.');
        return null;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      log('[DEBUG] Current Location: ${position.latitude}, ${position.longitude}');
      currentPosition = LatLng(position.latitude, position.longitude);
      return currentPosition;
    } catch (e) {
      log('[ERROR] Failed to fetch current location: $e');
      return null;
    }
  }
}

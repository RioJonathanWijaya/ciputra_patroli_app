import 'package:uuid/uuid.dart';

class PatroliCheckpoint {
  final String id;
  final String patroliId;
  final String checkpointName;
  final double? latitude;
  final double? longitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final String timestamp;
  final String? imagePath;
  final String? keterangan;
  final String status;
  final String distanceStatus;
  final bool isLate;

  PatroliCheckpoint({
    String? id,
    required this.patroliId,
    required this.checkpointName,
    this.latitude,
    this.longitude,
    this.currentLatitude,
    this.currentLongitude,
    required this.timestamp,
    this.imagePath,
    this.keterangan,
    required this.status,
    required this.distanceStatus,
    required this.isLate,
  }) : id = id ?? const Uuid().v4();

  factory PatroliCheckpoint.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing double from string: $value');
          return null;
        }
      }
      print(
          'Warning: Unhandled type for double conversion: ${value.runtimeType}');
      return null;
    }

    // Helper function to safely convert to string
    String toString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    // Helper function to safely convert to boolean
    bool toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    }

    // Create a new map with string keys
    final Map<String, dynamic> safeJson = {};
    json.forEach((key, value) {
      if (key != null) {
        safeJson[key.toString()] = value;
      }
    });

    // Print the safe JSON for debugging
    print('Safe JSON for checkpoint: $safeJson');

    return PatroliCheckpoint(
      id: toString(safeJson['id']),
      patroliId: toString(safeJson['patroli_id']),
      checkpointName: toString(safeJson['checkpoint_name']),
      latitude: toDouble(safeJson['latitude']),
      longitude: toDouble(safeJson['longitude']),
      currentLatitude: toDouble(safeJson['current_latitude']),
      currentLongitude: toDouble(safeJson['current_longitude']),
      timestamp: toString(safeJson['timestamp']),
      imagePath: safeJson['image_path']?.toString(),
      keterangan: safeJson['keterangan']?.toString(),
      status: toString(safeJson['status']),
      distanceStatus: toString(safeJson['distance_status']),
      isLate: toBool(safeJson['is_late']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patroli_id': patroliId,
      'checkpoint_name': checkpointName,
      'latitude': latitude,
      'longitude': longitude,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'timestamp': timestamp,
      'image_path': imagePath,
      'keterangan': keterangan,
      'status': status,
      'distance_status': distanceStatus,
      'is_late': isLate,
    };
  }
}

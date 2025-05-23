import 'package:uuid/uuid.dart';

class PatroliCheckpoint {
  final String id;
  final String patroliId;
  final String checkpointName;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? imagePath;
  final String? keterangan;
  final String status;
  final String distanceStatus;
  final double currentLatitude;
  final double currentLongitude;

  PatroliCheckpoint({
    String? id,
    required this.patroliId,
    required this.checkpointName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.imagePath,
    this.keterangan,
    required this.status,
    required this.distanceStatus,
    required this.currentLatitude,
    required this.currentLongitude,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patroli_id': patroliId,
      'checkpoint_name': checkpointName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'image_path': imagePath,
      'keterangan': keterangan,
      'status': status,
      'distance_status': distanceStatus,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
    };
  }

  factory PatroliCheckpoint.fromJson(Map<String, dynamic> json) {
    return PatroliCheckpoint(
      id: json['id'],
      patroliId: json['patroli_id'],
      checkpointName: json['checkpoint_name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: json['timestamp'],
      imagePath: json['image_path'],
      keterangan: json['keterangan'],
      status: json['status'],
      distanceStatus: json['distance_status'],
      currentLatitude: json['current_latitude'],
      currentLongitude: json['current_longitude'],
    );
  }
}

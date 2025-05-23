import 'dart:developer';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OpenStreetMapWidget extends StatefulWidget {
  final Penugasan penugasan;
  final Function(LatLng)? onLocationUpdate;
  final bool isTracking;

  const OpenStreetMapWidget({
    Key? key,
    required this.penugasan,
    this.onLocationUpdate,
    this.isTracking = false,
  }) : super(key: key);

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.isTracking) {
      _initLocationStream();
    }
  }

  Future<void> _initLocationStream() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> _initializeMap() async {
    _currentPosition = LatLng(-7.288670, 112.634888);
    setState(() {});
  }

  void _updateRoutePoints(LatLng newPosition) {
    if (widget.isTracking && _routePoints.isEmpty ||
        (_routePoints.isNotEmpty && _routePoints.last != newPosition)) {
      setState(() {
        _routePoints.add(newPosition);
      });
      if (widget.onLocationUpdate != null) {
        widget.onLocationUpdate!(newPosition);
      }
    }
  }

  List<Marker> _generateMarkersFromTitikPatroli() {
    return widget.penugasan.titikPatroli.asMap().entries.map<Marker>((entry) {
      final index = entry.key;
      final titik = entry.value;
      final lat = titik['lat'];
      final lng = titik['lng'];

      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
            Positioned(
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15,
                minZoom: 0,
                maxZoom: 100,
                onPositionChanged: (position, hasGesture) {
                  if (!hasGesture && widget.isTracking) {
                    _updateRoutePoints(position.center!);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                if (_routePoints.isNotEmpty && widget.isTracking)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                CurrentLocationLayer(
                  positionStream: LocationMarkerDataStreamFactory()
                      .fromGeolocatorPositionStream(
                    stream: _positionStream,
                  ),
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(
                        Icons.navigation,
                        color: Colors.white,
                      ),
                    ),
                    markerSize: Size(40, 40),
                    accuracyCircleColor: Colors.blue,
                  ),
                ),
                MarkerLayer(
                  markers: _generateMarkersFromTitikPatroli(),
                ),
              ],
            ),
    );
  }
}

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
  final List<LatLng>? patrolRoute;
  final bool simulatePolyline;

  const OpenStreetMapWidget({
    Key? key,
    required this.penugasan,
    this.onLocationUpdate,
    this.isTracking = true,
    this.patrolRoute,
    this.simulatePolyline = false,
  }) : super(key: key);

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];
  final List<LatLng> _userTrail = [];
  Stream<Position>? _positionStream;
  List<LatLng> _simulatedRoute = [];
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _checkLocationPermissions();
  }

  Future<void> _checkLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG: Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG: Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permissions are permanently denied');
        return;
      }

      _locationPermissionGranted = true;
      print('DEBUG: Location permissions granted');
      await _initLocationStream();
    } catch (e) {
      print('DEBUG: Error checking location permissions: $e');
    }
  }

  Future<void> _initLocationStream() async {
    if (!_locationPermissionGranted) {
      print('DEBUG: Cannot init location stream - no permissions');
      return;
    }

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _positionStream?.listen(
        (Position position) {
          print(
              'DEBUG: New position received: ${position.latitude}, ${position.longitude}');
          final newPosition = LatLng(position.latitude, position.longitude);

          setState(() {
            _currentPosition = newPosition;
            if (widget.isTracking) {
              if (_userTrail.isEmpty ||
                  _calculateDistance(_userTrail.last, newPosition) > 5) {
                _userTrail.add(newPosition);
                print(
                    'DEBUG: Added point to trail. Total points: ${_userTrail.length}');
              }
            }
          });

          if (widget.onLocationUpdate != null) {
            widget.onLocationUpdate!(newPosition);
          }
        },
        onError: (error) {
          print('DEBUG: Position stream error: $error');
        },
      );
    } catch (e) {
      print('DEBUG: Error initializing location stream: $e');
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  Future<void> _initializeMap() async {
    _currentPosition = LatLng(-7.288670, 112.634888);

    if (widget.simulatePolyline) {
      _simulatedRoute = [
        LatLng(-7.288670, 112.634888),
        LatLng(-7.288700, 112.635000),
        LatLng(-7.288800, 112.635200),
        LatLng(-7.288900, 112.635400),
        LatLng(-7.289000, 112.635600),
      ];
      _currentPosition = _simulatedRoute.first;
    }

    setState(() {});
  }

  void _updateRoutePoints(LatLng newPosition) {
    if (widget.isTracking &&
        (_routePoints.isEmpty || _routePoints.last != newPosition)) {
      setState(() {
        _routePoints.add(newPosition);
      });
      print(
          'DEBUG: Added point to route. Total route points: ${_routePoints.length}');
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
                initialZoom: 16,
                minZoom: 0,
                maxZoom: 100,
                onPositionChanged: (position, hasGesture) {
                  if (!hasGesture &&
                      widget.isTracking &&
                      position.center != null) {
                    _updateRoutePoints(position.center!);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                if (widget.simulatePolyline)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _simulatedRoute,
                        color: Colors.red,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (widget.patrolRoute != null &&
                    widget.patrolRoute!.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.patrolRoute!,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (_routePoints.length > 1 && widget.isTracking)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.orange,
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),
                if (_userTrail.length > 1 && widget.isTracking)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _userTrail,
                        color: Colors.green,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (_locationPermissionGranted && _positionStream != null)
                  CurrentLocationLayer(
                    positionStream: LocationMarkerDataStreamFactory()
                        .fromGeolocatorPositionStream(
                      stream: _positionStream!,
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
      floatingActionButton: widget.isTracking
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Permissions: $_locationPermissionGranted'),
                        Text('Current Position: $_currentPosition'),
                        Text('User Trail Points: ${_userTrail.length}'),
                        Text('Route Points: ${_routePoints.length}'),
                        Text('Is Tracking: ${widget.isTracking}'),
                        Text('Stream Active: ${_positionStream != null}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              label: Text('Trail: ${_userTrail.length}'),
              icon: const Icon(Icons.info),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _positionStream = null;
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KejadianMapPicker extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const KejadianMapPicker({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  _KejadianMapPickerState createState() => _KejadianMapPickerState();
}

class _KejadianMapPickerState extends State<KejadianMapPicker> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = LatLng(-7.288670, 112.634888); // Default location

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onLocationSelected(_selectedLocation);
              // Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation,
          initialZoom: 15,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

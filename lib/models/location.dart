import 'package:latlong2/latlong.dart';

class Lokasi {
  final String id;
  final String nama;
  final String alamat;
  final LatLng latLng;

  Lokasi({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latLng,
  });

  factory Lokasi.fromJson(String id, Map data) {
    return Lokasi(
      id: id,
      nama: data['nama_lokasi'] ?? '',
      alamat: data['alamat'] ?? '',
      latLng: LatLng(
        double.parse(data['latitude'].toString()),
        double.parse(data['longitude'].toString()),
      ),
    );
  }
}

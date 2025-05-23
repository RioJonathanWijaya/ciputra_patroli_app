import 'package:ciputra_patroli/models/titik_patroli.dart';

class JadwalPatroli {
  final String id;
  final String nama;
  final String lokasiId;
  final String deskripsi;
  final int intervalPatroli;
  final List<TitikPatroli> titikPatroli;

  JadwalPatroli({
    required this.id,
    required this.nama,
    required this.lokasiId,
    required this.deskripsi,
    required this.intervalPatroli,
    required this.titikPatroli,
  });

  factory JadwalPatroli.fromMap(String id, Map<String, dynamic> data) {
    return JadwalPatroli(
      id: id,
      nama: data['nama'] ?? '',
      lokasiId: data['lokasi'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      intervalPatroli: data['interval_patroli'] ?? 0,
      titikPatroli: (data['titik_patrol'] as List<dynamic>?)
              ?.map((e) => TitikPatroli.fromMap(e))
              .toList() ??
          [],
    );
  }
}

class Penugasan {
  final String id;
  final String jamPatroli;
  final String satpamId;
  final String shift;
  final String namaLokasi;
  final int interval;
  final List<Map<String, dynamic>> titikPatroli;
  final String lokasiId;
  final String jadwalPatroliId;

  Penugasan({
    required this.id,
    required this.jamPatroli,
    required this.satpamId,
    required this.shift,
    required this.namaLokasi,
    required this.interval,
    required this.titikPatroli,
    required this.lokasiId,
    required this.jadwalPatroliId,
  });

  factory Penugasan.fromMap(Map<String, dynamic> map) {
    return Penugasan(
      id: map['id'] ?? '',
      jamPatroli: map['jam_patroli'] ?? '',
      satpamId: map['satpamId'] ?? '',
      shift: map['shift'] ?? "Tidak ada Shift",
      namaLokasi: map['nama_lokasi'] ?? 'Tidak ada Lokasi',
      interval: map['interval'] ?? 2,
      lokasiId: map['lokasi_id'] ?? '',
      jadwalPatroliId: map['jadwal_patroli_id'] ?? '',
      titikPatroli: map['titik_patroli'] != null
          ? List<Map<String, dynamic>>.from(map['titik_patroli'])
          : [],
    );
  }
}

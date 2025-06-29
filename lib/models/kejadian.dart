import 'package:ciputra_patroli/models/tindakan.dart';

class Kejadian {
  final String id;
  final String namaKejadian;
  final DateTime tanggalKejadian;
  final String lokasiKejadian;
  final double? latitude;
  final double? longitude;
  final String tipeKejadian;
  final String keterangan;
  final List<String>? fotoBuktiUrls;
  final bool isKecelakaan;
  final bool isPencurian;
  final bool isNotifikasi;
  final String? namaKorban;
  final String? alamatKorban;
  final String? keteranganKorban;
  final String satpamId;
  final String satpamNama;
  final DateTime waktuLaporan;
  DateTime? waktuSelesai;
  String status;
  final List<Tindakan>? tindakan;
  final String? kategoriId;

  Kejadian(
      {required this.id,
      required this.namaKejadian,
      required this.tanggalKejadian,
      required this.lokasiKejadian,
      this.latitude,
      this.longitude,
      required this.tipeKejadian,
      required this.keterangan,
      this.fotoBuktiUrls,
      required this.isKecelakaan,
      required this.isPencurian,
      required this.isNotifikasi,
      this.namaKorban,
      this.alamatKorban,
      this.keteranganKorban,
      required this.satpamId,
      required this.satpamNama,
      required this.waktuLaporan,
      this.waktuSelesai,
      required this.status,
      this.tindakan,
      this.kategoriId});

  factory Kejadian.fromMap(Map<String, dynamic> map) {
    List<String>? fotoUrls;
    if (map['foto_bukti_kejadian'] != null) {
      if (map['foto_bukti_kejadian'] is List) {
        fotoUrls = List<String>.from(map['foto_bukti_kejadian']);
      } else if (map['foto_bukti_kejadian'] is String) {
        fotoUrls = [map['foto_bukti_kejadian']];
      }
    }

    List<Tindakan>? tindakanList;
    if (map['tindakan'] != null && map['tindakan'] is List) {
      tindakanList = (map['tindakan'] as List)
          .map((e) => Tindakan.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return Kejadian(
      id: map['id'].toString(),
      namaKejadian: map['nama_kejadian'] ?? '',
      tanggalKejadian:
          DateTime.tryParse(map['tanggal_kejadian'] ?? '') ?? DateTime.now(),
      lokasiKejadian: map['lokasi_kejadian'] ?? '',
      latitude: _parseToDouble(map['latitude']),
      longitude: _parseToDouble(map['longitude']),
      tipeKejadian: map['tipe_kejadian'] ?? '',
      keterangan: map['keterangan'] ?? '',
      fotoBuktiUrls: fotoUrls,
      isKecelakaan: map['is_kecelakaan'] ?? false,
      isPencurian: map['is_pencurian'] ?? false,
      isNotifikasi: map['is_notifikasi'] ?? false,
      namaKorban: map['nama_korban'] ?? '',
      alamatKorban: map['alamat_korban'] ?? '',
      keteranganKorban: map['keterangan_korban'] ?? '',
      satpamId: map['satpam_id'] ?? '',
      satpamNama: map['satpam_nama'] ?? '',
      waktuLaporan:
          DateTime.tryParse(map['waktu_laporan'] ?? '') ?? DateTime.now(),
      waktuSelesai: map['waktu_selesai'] != null
          ? DateTime.tryParse(map['waktu_selesai'])
          : null,
      status: map['status'] ?? '',
      tindakan: tindakanList,
      kategoriId: map['kategori_id'],
    );
  }

  factory Kejadian.empty() => Kejadian(
      id: '',
      namaKejadian: '',
      tanggalKejadian: DateTime.now(),
      lokasiKejadian: '',
      latitude: null,
      longitude: null,
      tipeKejadian: '',
      keterangan: '',
      fotoBuktiUrls: [],
      isKecelakaan: false,
      isPencurian: false,
      isNotifikasi: false,
      namaKorban: '',
      alamatKorban: '',
      keteranganKorban: '',
      satpamId: '',
      satpamNama: '',
      waktuLaporan: DateTime.now(),
      waktuSelesai: null,
      status: '',
      tindakan: [],
      kategoriId: null);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_kejadian': namaKejadian,
      'tanggal_kejadian': tanggalKejadian.toIso8601String(),
      'lokasi_kejadian': lokasiKejadian,
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'tipe_kejadian': tipeKejadian,
      'keterangan': keterangan,
      'foto_bukti_kejadian': fotoBuktiUrls ?? [],
      'is_kecelakaan': isKecelakaan,
      'is_pencurian': isPencurian,
      'is_notifikasi': isNotifikasi,
      'nama_korban': namaKorban,
      'alamat_korban': alamatKorban,
      'keterangan_korban': keteranganKorban,
      'satpam_id': satpamId,
      'satpam_nama': satpamNama,
      'waktu_laporan': waktuLaporan.toIso8601String(),
      'waktu_selesai': waktuSelesai?.toIso8601String(),
      'status': status,
      'tindakan': tindakan?.map((e) => e.toMap()).toList() ?? [],
      'kategori_id': kategoriId,
    };
  }
}

double? _parseToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
  return null;
}

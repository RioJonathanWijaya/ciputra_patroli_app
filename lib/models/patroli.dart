import 'package:intl/intl.dart';

class Patroli {
  final String id;
  DateTime? jamMulai;
  DateTime? jamSelesai;
  String catatanPatroli;
  Duration? durasiPatroli;
  String rutePatroli;
  final String satpamId;
  final String lokasiId;
  final String jadwalPatroliId;
  final String penugasanId;
  bool isTerlambat;
  final List<Map<String, dynamic>> checkpoints;
  DateTime tanggal;
  final String? lokasiNama;
  final String? satpamNama;

  Patroli({
    required this.id,
    this.jamMulai,
    this.jamSelesai,
    required this.catatanPatroli,
    this.durasiPatroli,
    required this.rutePatroli,
    required this.satpamId,
    required this.lokasiId,
    required this.jadwalPatroliId,
    required this.penugasanId,
    required this.isTerlambat,
    List<Map<String, dynamic>>? checkpoints,
    required this.tanggal,
    this.lokasiNama,
    this.satpamNama,
  }) : checkpoints = checkpoints ?? [];

  DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null) return null;

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        final timeParts = dateStr.split(':');
        if (timeParts.length == 2) {
          final now = DateTime.now();
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        try {
          final months = {
            'January': 1,
            'February': 2,
            'March': 3,
            'April': 4,
            'May': 5,
            'June': 6,
            'July': 7,
            'August': 8,
            'September': 9,
            'October': 10,
            'November': 11,
            'December': 12
          };

          final parts = dateStr.split(' ');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = months[parts[1]];
            final year = int.parse(parts[2]);

            if (month != null) {
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          print('Error parsing date: $dateStr - $e');
        }
      }
    }
    return null;
  }

  factory Patroli.fromMap(Map<String, dynamic> map) {
    DateTime? safeParse(String? dateString) {
      if (dateString == null || dateString.trim().isEmpty) return null;

      try {
        return DateTime.parse(dateString);
      } catch (_) {}

      try {
        return DateFormat('dd MMM yyyy', 'en_US').parse(dateString);
      } catch (_) {}

      try {
        return DateFormat('dd MMMM yyyy', 'id_ID').parse(dateString);
      } catch (_) {}

      try {
        final parts = dateString.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final second = parts.length == 3 ? int.parse(parts[2]) : 0;
          return DateTime(now.year, now.month, now.day, hour, minute, second);
        }
      } catch (_) {}

      return null;
    }

    return Patroli(
      id: map['id'] ?? '',
      catatanPatroli: map['catatan_patroli'] ?? '',
      rutePatroli: map['rute_patroli'] ?? '',
      satpamId: map['satpamId'] ?? map['satpam_id'] ?? '',
      lokasiId: map['lokasiId'] ?? map['lokasi_id'] ?? '',
      jadwalPatroliId: map['jadwalPatroliId'] ?? map['jadwal_patroli_id'] ?? '',
      penugasanId: map['penugasanId'] ?? map['penugasan_id'] ?? '',
      jamMulai: safeParse(
          map['jam_mulai']?.toString() ?? map['jamMulai']?.toString()),
      jamSelesai: safeParse(
          map['jam_selesai']?.toString() ?? map['jamSelesai']?.toString()),
      durasiPatroli: map['durasi_patroli'] != null
          ? Duration(seconds: map['durasi_patroli'])
          : map['durasiPatroli'] != null
              ? Duration(seconds: map['durasiPatroli'])
              : null,
      isTerlambat: map['is_terlambat'] ?? map['isTerlambat'] ?? false,
      checkpoints: map['checkpoints'] != null
          ? List<Map<String, dynamic>>.from(map['checkpoints']).toList()
          : [],
      tanggal: safeParse(map['tanggal']?.toString()) ?? DateTime.now(),
      lokasiNama: map['lokasi_nama'],
      satpamNama: map['satpam_nama'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jamMulai': jamMulai?.toIso8601String(),
      'jamSelesai': jamSelesai?.toIso8601String(),
      'catatan_patroli': catatanPatroli,
      'durasiPatroli': durasiPatroli?.inSeconds,
      'rute_patroli': rutePatroli,
      'satpamId': satpamId,
      'lokasiId': lokasiId,
      'jadwalPatroliId': jadwalPatroliId,
      'penugasanId': penugasanId,
      'isTerlambat': isTerlambat,
      'checkpoints': checkpoints,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  int get checkpointCount => checkpoints.length;

  String getCheckpointStatus(int index) {
    if (index >= 0 && index < checkpoints.length) {
      return checkpoints[index]['status'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  String? getCheckpointTimestamp(int index) {
    if (index >= 0 && index < checkpoints.length) {
      return checkpoints[index]['timestamp'];
    }
    return null;
  }

  void addCheckpoint(Map<String, dynamic> checkpointData) {
    checkpoints.add({
      'id': checkpointData['id'],
      'timestamp': checkpointData['timestamp'],
      'status': checkpointData['status'],
    });
  }
}

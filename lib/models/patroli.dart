class Patroli {
  final String id;
  final DateTime? jamMulai;
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
  final DateTime tanggal;

  Patroli({
    required this.id,
    required this.jamMulai,
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
  }) : checkpoints = checkpoints ?? [];

  factory Patroli.fromMap(Map<String, dynamic> map) {
    return Patroli(
      id: map['id'],
      catatanPatroli: map['catatan_patroli'] ?? '',
      rutePatroli: map['rute_patroli'] ?? '',
      satpamId: map['satpam_id'],
      lokasiId: map['lokasi_id'],
      jadwalPatroliId: map['jadwal_patroli_id'],
      penugasanId: map['penugasan_id'],
      jamMulai:
          map['jamMulai'] != null ? DateTime.parse(map['jamMulai']) : null,
      jamSelesai:
          map['jamSelesai'] != null ? DateTime.parse(map['jamSelesai']) : null,
      durasiPatroli: map['durasiPatroli'] != null
          ? Duration(seconds: map['durasiPatroli'])
          : null,
      isTerlambat: map['isTerlambat'] ?? false,
      checkpoints: map['checkpoints'] != null
          ? List<Map<String, dynamic>>.from(map['checkpoints']).toList()
          : [],
      tanggal: map['tanggal'] != null
          ? DateTime.parse(map['tanggal'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jamMulai': jamMulai?.toIso8601String(),
      'jamSelesai': jamSelesai?.toIso8601String(),
      'durasiPatroli': durasiPatroli?.inSeconds,
      'catatanPatroli': catatanPatroli,
      'rutePatroli': rutePatroli,
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

class Tindakan {
  final String tindakanId;
  final String tindakan;
  final String? manajemenId;
  final String? kejadianId;
  final DateTime? waktuTindakan;
  final DateTime? createdAt;

  Tindakan({
    required this.tindakanId,
    required this.tindakan,
    this.manajemenId,
    this.kejadianId,
    this.waktuTindakan,
    this.createdAt,
  });

  factory Tindakan.fromMap(Map<String, dynamic> map) {
    return Tindakan(
      tindakanId: map['tindakan_id'] ?? '',
      tindakan: map['tindakan'] ?? '',
      manajemenId: map['manajemen_id'],
      kejadianId: map['kejadian_id'],
      waktuTindakan: map['waktu_tindakan'] != null
          ? DateTime.tryParse(map['waktu_tindakan'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tindakan_id': tindakanId,
      'tindakan': tindakan,
      'manajemen_id': manajemenId,
      'kejadian_id': kejadianId,
      'waktu_tindakan': waktuTindakan?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Satpam {
  final String satpamId;
  final String nama;
  final String nip;
  final String email;
  final String nomorTelepon;
  final String alamat;
  final String tempatLahir;
  final String tanggalLahir;
  final String tanggalBergabung;
  final String pendidikanTerakhir;
  final String fotoProfile;
  final String namaLokasi;
  final String penugasanId;
  final String supervisorId;
  final String lokasiId;
  final int jenisKelamin;
  final int shift;
  final int jabatan;
  final int status;
  final int statusPernikahan;
  final String? fcmToken;

  Satpam({
    required this.satpamId,
    required this.nama,
    required this.nip,
    required this.email,
    required this.nomorTelepon,
    required this.alamat,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.tanggalBergabung,
    required this.pendidikanTerakhir,
    required this.fotoProfile,
    required this.jenisKelamin,
    required this.namaLokasi,
    required this.shift,
    required this.jabatan,
    required this.status,
    required this.statusPernikahan,
    required this.supervisorId,
    required this.penugasanId,
    required this.lokasiId,
    this.fcmToken,
  });

  factory Satpam.fromJson(Map<String, dynamic> json) {
    try {
      // Log the raw JSON for debugging
      print('Raw JSON data: $json');

      // Helper function to safely convert to string
      String toString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }

      // Helper function to safely convert to int
      int toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Error parsing int from string: $value');
            return 0;
          }
        }
        return 0;
      }

      return Satpam(
        satpamId: toString(json['satpam_id']),
        nama: toString(json['nama']),
        nip: toString(json['nip']),
        email: toString(json['email']),
        nomorTelepon: toString(json['nomor_telepon']),
        alamat: toString(json['alamat']),
        tempatLahir: toString(json['tempat_lahir']),
        tanggalLahir: toString(json['tanggal_lahir']),
        tanggalBergabung: toString(json['tanggal_bergabung']),
        pendidikanTerakhir: toString(json['pendidikan_terakhir']),
        fotoProfile: toString(json['foto_profile']),
        jenisKelamin: toInt(json['jenis_kelamin']),
        shift: toInt(json['shift']),
        jabatan: toInt(json['jabatan']),
        status: toInt(json['status']),
        statusPernikahan: toInt(json['status_pernikahan']),
        supervisorId: toString(json['supervisor_id']),
        penugasanId: toString(json['penugasan_id']),
        lokasiId: toString(json['lokasi_id']),
        namaLokasi: toString(json['nama_lokasi']),
        fcmToken: json['fcm_token']?.toString(),
      );
    } catch (e, stackTrace) {
      print('Error creating Satpam object: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'Satpam(satpamId: $satpamId, nama: $nama, email: $email)';
  }
}

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

  Satpam(
      {required this.satpamId,
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
      this.fcmToken});

  factory Satpam.fromJson(Map<String, dynamic> json) {
    print('Raw JSON data: $json');

    // Log each field's type and value
    print(
        'supervisor_id type: ${json['supervisor_id']?.runtimeType}, value: ${json['supervisor_id']}');
    print(
        'penugasan_id type: ${json['penugasan_id']?.runtimeType}, value: ${json['penugasan_id']}');
    print(
        'lokasi_id type: ${json['lokasi_id']?.runtimeType}, value: ${json['lokasi_id']}');
    print(
        'jenis_kelamin type: ${json['jenis_kelamin']?.runtimeType}, value: ${json['jenis_kelamin']}');
    print('shift type: ${json['shift']?.runtimeType}, value: ${json['shift']}');
    print(
        'jabatan type: ${json['jabatan']?.runtimeType}, value: ${json['jabatan']}');
    print(
        'status type: ${json['status']?.runtimeType}, value: ${json['status']}');
    print(
        'status_pernikahan type: ${json['status_pernikahan']?.runtimeType}, value: ${json['status_pernikahan']}');

    try {
      return Satpam(
          satpamId: json['satpam_id']?.toString() ?? '',
          nama: json['nama'] ?? '',
          nip: json['nip'] ?? '',
          email: json['email'] ?? '',
          nomorTelepon: json['nomor_telepon'] ?? '',
          alamat: json['alamat'] ?? '',
          tempatLahir: json['tempat_lahir'] ?? '',
          tanggalLahir: json['tanggal_lahir'] ?? '',
          tanggalBergabung: json['tanggal_bergabung'] ?? '',
          pendidikanTerakhir: json['pendidikan_terakhir'] ?? '',
          fotoProfile: json['foto_profile'] ?? '',
          jenisKelamin: json['jenis_kelamin'] ?? 0,
          shift: json['shift'] ?? 0,
          jabatan: json['jabatan'] ?? 0,
          status: json['status'] ?? 0,
          statusPernikahan: json['status_pernikahan'] ?? 0,
          supervisorId: json['supervisor_id']?.toString() ?? '',
          penugasanId: json['penugasan_id']?.toString() ?? '',
          lokasiId: json['lokasi_id']?.toString() ?? '',
          namaLokasi: json['nama_lokasi'] ?? '',
          fcmToken: json['fcm_token']);
    } catch (e) {
      print('Error creating Satpam object: $e');
      print('Failed at field: ${e.toString().split("'")[1]}');
      rethrow;
    }
  }
}

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/viewModel/kejadian_viewModel.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:ciputra_patroli/services/api_service.dart';
import 'package:ciputra_patroli/widgets/maps/kejadian_map_picker.dart';
import 'package:latlong2/latlong.dart';

class KejadianInputPage extends StatefulWidget {
  const KejadianInputPage({super.key});

  @override
  State<KejadianInputPage> createState() => _KejadianInputPageState();
}

class _KejadianInputPageState extends State<KejadianInputPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _namaKejadianController = TextEditingController();
  final TextEditingController _tanggalKejadianController =
      TextEditingController();
  final TextEditingController _lokasiKejadianController =
      TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _namaKorbanController = TextEditingController();
  final TextEditingController _alamatKorbanController = TextEditingController();
  final TextEditingController _keteranganKorbanController =
      TextEditingController();
  final TextEditingController _coordinateController = TextEditingController();

  DateTime? _selectedDate;
  bool _isKecelakaan = false;
  bool _isPencurian = false;
  bool _isNotifikasi = false;
  String? _selectedTipeKejadian;
  LatLng? _selectedLocation;

  List<String> tipeKejadianOptions = ['Ringan', 'Sedang', 'Berat', 'Kritis'];

  @override
  void initState() {
    super.initState();
    _tanggalKejadianController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _namaKejadianController.dispose();
    _tanggalKejadianController.dispose();
    _lokasiKejadianController.dispose();
    _keteranganController.dispose();
    _namaKorbanController.dispose();
    _alamatKorbanController.dispose();
    _keteranganKorbanController.dispose();
    _coordinateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalKejadianController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting photo: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final loginVM = Provider.of<LoginViewModel>(context, listen: false);
      final kejadianVM = Provider.of<KejadianViewModel>(context, listen: false);

      try {
        // Generate kejadian ID first
        final kejadianId = DateTime.now().millisecondsSinceEpoch.toString();

        // Upload photos first if any
        List<String> photoUrls = [];
        if (_selectedPhotos.isNotEmpty) {
          photoUrls = await _apiService.uploadMultiplePhotos(
            kejadianId,
            _selectedPhotos,
          );
        }

        // Create kejadian with photo URLs
        final kejadian = Kejadian(
            id: kejadianId,
            namaKejadian: _namaKejadianController.text,
            tanggalKejadian: _selectedDate!,
            lokasiKejadian: _lokasiKejadianController.text,
            tipeKejadian: _selectedTipeKejadian!,
            keterangan: _keteranganController.text,
            fotoBuktiUrls: photoUrls,
            isKecelakaan: _isKecelakaan,
            isPencurian: _isPencurian,
            isNotifikasi: _isNotifikasi,
            namaKorban: _isKecelakaan || _isPencurian
                ? _namaKorbanController.text
                : null,
            alamatKorban: _isKecelakaan || _isPencurian
                ? _alamatKorbanController.text
                : null,
            keteranganKorban: _isKecelakaan || _isPencurian
                ? _keteranganKorbanController.text
                : null,
            satpamId: loginVM.satpamId ?? '',
            satpamNama: loginVM.satpam?.nama ?? 'Satpam',
            waktuLaporan: DateTime.now(),
            waktuSelesai: null,
            status: "Aktif",
            latitude: _selectedLocation?.latitude,
            longitude: _selectedLocation?.longitude);

        // Save kejadian with photo URLs
        final result = await kejadianVM.saveKejadian(kejadian);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? 'Laporan kejadian berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to previous page
          if (mounted) {
            NavigationService.pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    result['message'] ?? 'Gagal menyimpan laporan kejadian'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Laporan Kejadian"),
        backgroundColor: const Color(0xFF1C3A6B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Satpam Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<LoginViewModel>(
                  builder: (context, loginVM, child) {
                    return Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1C3A6B).withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF1C3A6B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pelapor:",
                              style: TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              loginVM.satpam?.nama ?? "Satpam",
                              style: const TextStyle(
                                color: Color(0xFF1C3A6B),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Waktu: ${DateFormat('HH:mm').format(DateTime.now())}",
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Detail Kejadian",
                      style: TextStyle(
                        color: Color(0xFF1C3A6B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _namaKejadianController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kejadian',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap masukkan nama kejadian';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tanggalKejadianController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kejadian',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap pilih tanggal kejadian';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lokasiKejadianController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Kejadian',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap masukkan lokasi kejadian';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _coordinateController,
                      decoration: const InputDecoration(
                        labelText: 'Koordinat Kejadian',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KejadianMapPicker(
                                    onLocationSelected: (location) {
                                      setState(() {
                                        _selectedLocation = location;
                                        _coordinateController.text =
                                            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.location_on),
                            label: const Text('Pilih Lokasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C3A6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Koordinat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTipeKejadian,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Kejadian',
                        border: OutlineInputBorder(),
                      ),
                      items: tipeKejadianOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTipeKejadian = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap pilih tipe kejadian';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _keteranganController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Kejadian',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap masukkan keterangan kejadian';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto Bukti Kejadian',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_selectedPhotos.isEmpty)
                                Container(
                                  height: 150,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Belum ada foto'),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _selectedPhotos.length +
                                      1, // +1 for add button
                                  itemBuilder: (context, index) {
                                    if (index == _selectedPhotos.length) {
                                      // Add photo button
                                      return InkWell(
                                        onTap: () => _showPhotoOptions(context),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.add_a_photo,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    }
                                    // Photo preview
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            _selectedPhotos[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () => _removePhoto(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showPhotoOptions(context),
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Tambah Foto'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1C3A6B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jenis Kejadian:',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _isKecelakaan,
                          onChanged: (bool? value) {
                            setState(() {
                              _isKecelakaan = value ?? false;
                              if (_isKecelakaan) {
                                _isPencurian = false;
                              }
                            });
                          },
                          activeColor: const Color(0xFF1C3A6B),
                        ),
                        const Text('Kecelakaan'),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _isPencurian,
                          onChanged: (bool? value) {
                            setState(() {
                              _isPencurian = value ?? false;
                              if (_isPencurian) {
                                _isKecelakaan = false;
                              }
                            });
                          },
                          activeColor: const Color(0xFF1C3A6B),
                        ),
                        const Text('Pencurian'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _isNotifikasi,
                          onChanged: (bool? value) {
                            setState(() {
                              _isNotifikasi = value ?? false;
                              log(_isNotifikasi.toString());
                            });
                          },
                          activeColor: const Color(0xFF1C3A6B),
                        ),
                        const Text('Kirim Notifikasi ke Satpam Lain'),
                      ],
                    ),
                  ],
                ),
              ),

              if (_isKecelakaan || _isPencurian) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isKecelakaan
                            ? 'Detail Korban Kecelakaan'
                            : 'Detail Korban Pencurian',
                        style: const TextStyle(
                          color: Color(0xFF1C3A6B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaKorbanController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Korban',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((_isKecelakaan || _isPencurian) &&
                              (value == null || value.isEmpty)) {
                            return 'Harap masukkan nama korban';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alamatKorbanController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Korban',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if ((_isKecelakaan || _isPencurian) &&
                              (value == null || value.isEmpty)) {
                            return 'Harap masukkan alamat korban';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _keteranganKorbanController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan Korban',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if ((_isKecelakaan || _isPencurian) &&
                              (value == null || value.isEmpty)) {
                            return 'Harap masukkan keterangan korban';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3A6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Laporan Kejadian',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

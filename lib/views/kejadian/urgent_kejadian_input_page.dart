import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/viewModel/kejadian_viewModel.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:ciputra_patroli/services/api_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class UrgentKejadianInputPage extends StatefulWidget {
  const UrgentKejadianInputPage({super.key});

  @override
  State<UrgentKejadianInputPage> createState() =>
      _UrgentKejadianInputPageState();
}

class _UrgentKejadianInputPageState extends State<UrgentKejadianInputPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _namaKejadianController = TextEditingController();
  final TextEditingController _lokasiKejadianController =
      TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  File? _selectedPhoto;
  String? _selectedKategoriId;
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _kategoriList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _fetchKategori() async {
    try {
      final kategori = await _apiService.fetchKategoriKejadian();
      setState(() {
        _kategoriList = kategori;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading categories')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _selectedPhoto = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final loginVM = Provider.of<LoginViewModel>(context, listen: false);
        final kejadianVM =
            Provider.of<KejadianViewModel>(context, listen: false);

        final kejadianId = DateTime.now().millisecondsSinceEpoch.toString();
        List<String> photoUrls = [];

        if (_selectedPhoto != null) {
          final url =
              await _apiService.uploadPhoto(kejadianId, _selectedPhoto!);
          if (url != null) photoUrls.add(url);
        }

        final kejadian = Kejadian(
            id: kejadianId,
            namaKejadian: _namaKejadianController.text,
            tanggalKejadian: DateTime.now(),
            lokasiKejadian: _lokasiKejadianController.text,
            tipeKejadian: 'Urgent',
            keterangan: _keteranganController.text,
            fotoBuktiUrls: photoUrls,
            isKecelakaan: false,
            isPencurian: false,
            isNotifikasi:
                true, // Always send notifications for urgent incidents
            satpamId: loginVM.satpamId ?? '',
            satpamNama: loginVM.satpam?.nama ?? 'Satpam',
            waktuLaporan: DateTime.now(),
            waktuSelesai: null,
            status: "Urgent",
            latitude: _currentLocation?.latitude,
            longitude: _currentLocation?.longitude,
            kategoriId: _selectedKategoriId);

        final result = await kejadianVM.saveKejadian(kejadian);

        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Urgent incident reported successfully'),
                backgroundColor: Colors.green,
              ),
            );
            NavigationService.pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to report incident'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Urgent Incident Report"),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick Category Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quick Category Selection",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _kategoriList.map((kategori) {
                              final isSelected =
                                  _selectedKategoriId == kategori['id'];
                              return ChoiceChip(
                                label: Text(kategori['nama_kategori']),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedKategoriId =
                                        selected ? kategori['id'] : null;
                                  });
                                },
                                selectedColor: Colors.red,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Incident Name
                    TextFormField(
                      controller: _namaKejadianController,
                      decoration: InputDecoration(
                        labelText: 'What happened? *',
                        hintText: 'Brief description of the incident',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.warning_amber_rounded),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please describe the incident'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _lokasiKejadianController,
                      decoration: InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Where did it happen?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Location is required'
                          : null,
                    ),
                    if (_currentLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'GPS Location: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Quick Photo
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedPhoto == null
                          ? InkWell(
                              onTap: _takePhoto,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Take a Photo'),
                                ],
                              ),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedPhoto!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _takePhoto,
                                    color: Colors.white,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Details
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Details',
                        hintText: 'Any other important information?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'REPORT URGENT INCIDENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

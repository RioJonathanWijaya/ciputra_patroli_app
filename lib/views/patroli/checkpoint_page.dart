import 'dart:developer';

import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:ciputra_patroli/viewModel/patroli_viewModel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:uuid/uuid.dart';

class CheckpointPage extends StatefulWidget {
  const CheckpointPage({
    Key? key,
  }) : super(key: key);

  @override
  State<CheckpointPage> createState() => _CheckpointPageState();
}

class _CheckpointPageState extends State<CheckpointPage> {
  File? _selectedImage;
  final TextEditingController _keteranganController = TextEditingController();
  bool _isLoading = false;
  DateTime? _captureTime;
  final Color _primaryColor = const Color(0xFF1C3A6B);
  final Color _accentColor = const Color(0xFF4CAF50);

  late Patroli patroli;
  late Penugasan penugasan;
  late int currentIndex;
  late PatroliViewModel patroliViewModel;

  List<Map<String, dynamic>> checkpoints = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    patroli = args['patroli'];
    penugasan = args['penugasan'];
    currentIndex = args['currentIndex'];
    patroliViewModel = args['patroliVM'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _captureTime = DateTime.now();
      });
    }
  }

  void _submitCheckpoint() async {
    if (_selectedImage == null) {
      _showErrorDialog('Foto Wajib', 'Ambil foto untuk bukti patroli.');
      return;
    }

    // Validate file size
    final fileSize = await _selectedImage!.length();
    if (fileSize > 10 * 1024 * 1024) {
      // 5MB limit
      _showErrorDialog(
          'Ukuran File Terlalu Besar', 'Ukuran foto maksimal 5MB.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final checkpoint = penugasan.titikPatroli[currentIndex];
      final checkpointName =
          checkpoint['nama'] ?? 'Checkpoint ${currentIndex + 1}';
      final latitude = (checkpoint['lat'] as num).toDouble();
      final longitude = (checkpoint['lng'] as num).toDouble();

      // Generate a unique checkpoint ID
      final checkpointId = const Uuid().v4();

      // Upload the photo first
      String? photoUrl;
      try {
        photoUrl = await patroliViewModel.apiService.uploadCheckpointPhoto(
          photoFile: _selectedImage!,
          patroliId: patroli.id,
          checkpointId: checkpointId,
        );
      } catch (e) {
        log('[ERROR] Failed to upload photo: $e');
        _showErrorDialog('Upload Foto Gagal', e.toString());
        return;
      }

      if (photoUrl == null) {
        throw Exception('Gagal mendapatkan URL foto');
      }

      try {
        await patroliViewModel.submitCheckpoint(
          patroli: patroli,
          penugasan: penugasan,
          currentIndex: currentIndex,
          checkpointName: checkpointName,
          latitude: latitude,
          longitude: longitude,
          buktiImage: photoUrl,
          catatan: _keteranganController.text,
        );

        _showSuccessDialog();
      } catch (e) {
        log('[ERROR] Failed to submit checkpoint: $e');
        _showErrorDialog('Simpan Checkpoint Gagal', e.toString());
      }
    } catch (e) {
      log('[ERROR] Error in _submitCheckpoint: $e');
      _showErrorDialog('Error', 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil', style: TextStyle(color: Colors.green)),
        content: const Text('Checkpoint berhasil disimpan!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, currentIndex);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkpoint = penugasan.titikPatroli[currentIndex];
    final progress = (currentIndex + 1) / penugasan.titikPatroli.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkpoint ${currentIndex + 1}/${penugasan.titikPatroli.length}',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: _accentColor,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkpoint Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Lat: ${checkpoint['lat']}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Lng: ${checkpoint['lng']}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Patrol Evidence Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImage == null
                        ? Colors.grey[400]!
                        : _accentColor,
                    width: 1.5,
                  ),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to take photo',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Photo taken: ${_captureTime?.toString() ?? 'Unknown time'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keteranganController,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelText: 'Enter notes (optional)',
                alignLabelWithHint: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCheckpoint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE CHECKPOINT',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/viewModel/patroli_viewModel.dart';
import 'package:ciputra_patroli/viewModel/penugasan_viewModel.dart';
import 'package:ciputra_patroli/widgets/appbar/appbar.dart';
import 'package:ciputra_patroli/widgets/maps/openstreetmaps_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';

class StartPatroli extends StatefulWidget {
  const StartPatroli({super.key});

  @override
  _StartPatroliState createState() => _StartPatroliState();
}

class _StartPatroliState extends State<StartPatroli> {
  late PatroliViewModel patroliVM;
  late PenugasanPatroliViewModel penugasanVM;
  late Patroli patroli;
  late LoginViewModel loginVM;
  late Penugasan penugasan;

  LatLng _currentLocation = const LatLng(0, 0);
  final MapController _mapController = MapController();
  final TextEditingController _textController = TextEditingController();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  late String tanggalPatroli =
      DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
  String? jamMulaiPatroli;
  late DateTime startTime;
  String durationString = "00:00";
  Timer? timer;
  File? buktiImage;
  File? kejadianImage;
  StreamSubscription<Position>? _positionStream;
  bool isMapReady = false;

  Set<int> _submittedCheckpoints = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isMapReady = true;
      });
      _showConfirmationDialog();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      NavigationService.pop();
      return;
    }

    penugasanVM = args['penugasanVM'] as PenugasanPatroliViewModel;
    penugasan = args['penugasan'] as Penugasan;
    patroli = args['patroli'] as Patroli;
    loginVM = args['loginVM'] as LoginViewModel;
    patroliVM = args['patroliVM'] as PatroliViewModel;

    log('[DEBUG] PatroliMulaiPage: Using existing PatroliViewModel');
    log('[DEBUG] PatroliMulaiPage: Current patroli: ${patroliVM.currentPatroli?.toMap()}');
  }

  Future<void> _showConfirmationDialog() async {
    bool startPatroli = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Konfirmasi",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah Anda ingin memulai patroli?"),
          actions: [
            TextButton(
              onPressed: () => NavigationService.pop(false),
              child: const Text("Tidak", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => NavigationService.pop(true),
              child: const Text("Ya", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (!startPatroli) {
      await NavigationService.pop();
    } else {
      log('[DEBUG] PatroliMulaiPage: Starting patroli process');
      final satpamId = loginVM.satpamId;
      if (satpamId == null) {
        log('[ERROR] PatroliMulaiPage: satpamId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error: Data satpam tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        await NavigationService.pop();
        return;
      }

      log('[DEBUG] PatroliMulaiPage: loginVM.satpamId: $satpamId');
      log('[DEBUG] PatroliMulaiPage: penugasan details - id: ${penugasan.id}, lokasiId: ${penugasan.lokasiId}, jadwalPatroliId: ${penugasan.jadwalPatroliId}');

      startTime = DateTime.now();
      jamMulaiPatroli = DateFormat('HH:mm:ss').format(startTime);
      startTimer();
      startPatrolTracking();

      try {
        patroliVM.createPatroli(
            satpamId: satpamId,
            lokasiId: penugasan.lokasiId,
            penugasanId: penugasan.id,
            jadwalPatroliId: penugasan.jadwalPatroliId);
        log('[DEBUG] PatroliMulaiPage: Patroli creation initiated successfully');
      } catch (e, stackTrace) {
        log('[ERROR] PatroliMulaiPage: Failed to create patroli');
        log('[ERROR] PatroliMulaiPage: Error details: $e');
        log('[STACKTRACE] $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai patroli: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        Duration diff = DateTime.now().difference(startTime);
        durationString = _formatDuration(diff);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> pickImage(bool isBukti) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (isBukti) {
          buktiImage = File(pickedFile.path);
        } else {
          kejadianImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> startPatrolTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      try {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (isMapReady) {
          _mapController.move(_currentLocation, 15.0);
        }
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _mapController.move(_currentLocation, 15.0);
          });
        });
      } catch (e) {
        print("Error Loading the Map");
      }
    });
  }

  void stopPatrolTracking() {
    _positionStream?.cancel();
  }

  void submitForm() async {
    log("[DEBUG] Submitting Form - Checking if _currentPatroli is null");

    if (patroliVM.currentPatroli == null) {
      log("[ERROR] _currentPatroli is still null before saving.");
    } else {
      log("[DEBUG] _currentPatroli exists before saving: ${patroliVM.currentPatroli!.toMap().toString()}");

      patroliVM.endPatroli(
        catatanPatroli: _textController.text,
        penugasan: penugasan,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(titleName: "Mulai Patroli"),
      body: Stack(
        children: [
          OpenStreetMapWidget(penugasan: penugasan),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.7,
              snapSizes: const [0.3, 0.5, 0.7],
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          children: [
                            _buildHeaderSection(),
                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 24),
                            _buildTimeSection(),
                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 24),
                            _buildCheckpointsList(),
                            const SizedBox(height: 24),
                            _buildEvidenceSection(
                              title: "Foto Kejadian",
                              description: "Foto kejadian (bila ada)",
                              image: kejadianImage,
                              onPressed: () => pickImage(false),
                            ),
                            const SizedBox(height: 24),
                            _buildNotesSection(),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final satpam = patroliVM.satpam;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patroli ${penugasan.namaLokasi}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C3A6B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    penugasan.namaLokasi,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Tanggal Patroli",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                tanggalPatroli,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://cdn0-production-images-kly.akamaized.net/DsG497R5kke55KW1OyLrBiyczh0=/1200x1200/smart/filters:quality(75):strip_icc():format(webp)/kly-media-production/medias/5043699/original/091518500_1733818957-1733755152199_fungsi-satpam.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              satpam?.nama ?? 'Nama tidak tersedia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              satpam?.nip ?? 'NIP tidak tersedia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckpointsList() {
    final checkpoints = penugasan.titikPatroli;
    if (checkpoints.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Tidak ada checkpoint tersedia',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Checkpoint",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C3A6B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Lengkapi semua checkpoint patroli",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        ...checkpoints.asMap().entries.map((entry) {
          final index = entry.key;
          final checkpoint = entry.value;

          final checkpointName =
              checkpoint['nama'] ?? 'Checkpoint ${index + 1}';
          final checkpointDesc = checkpoint['deskripsi'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1C3A6B),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                checkpointName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: checkpointDesc.isNotEmpty
                  ? Text(
                      checkpointDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
              trailing: ElevatedButton(
                onPressed: _submittedCheckpoints.contains(index)
                    ? null
                    : () async {
                        if (patroliVM.currentPatroli == null) {
                          log('[ERROR] Cannot submit checkpoint: currentPatroli is null');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Error: Data patroli tidak ditemukan. Silakan mulai patroli ulang.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        log('[DEBUG] Navigating to checkpoint with patroli: ${patroliVM.currentPatroli!.toMap()}');
                        final result = await Navigator.pushNamed(
                          context,
                          '/checkpoint',
                          arguments: {
                            'patroli': patroliVM.currentPatroli,
                            'penugasan': penugasan,
                            'currentIndex': index,
                            'checkpointName': checkpointName,
                            'totalCheckpoints': checkpoints.length,
                            'patroliVM': patroliVM,
                          },
                        );

                        if (result != null && result is int) {
                          setState(() {
                            _submittedCheckpoints.add(result);
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _submittedCheckpoints.contains(index)
                      ? Colors.grey
                      : const Color(0xFF1C3A6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lengkapi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeItem(
          title: "Jam Mulai",
          value: jamMulaiPatroli ?? "Belum Dimulai",
          icon: Icons.access_time,
        ),
        _buildTimeItem(
          title: "Jam Selesai",
          value: "-",
          icon: Icons.access_time,
        ),
        _buildTimeItem(
          title: "Durasi",
          value: durationString,
          icon: Icons.timer,
        ),
      ],
    );
  }

  Widget _buildTimeItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1C3A6B)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvidenceSection({
    required String title,
    required String description,
    required File? image,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C3A6B),
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: image != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onPressed,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: const Color(0xFFF5F7FA),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 32, color: Color(0xFF1C3A6B)),
                ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Keterangan Kejadian",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C3A6B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Masukkan keterangan kejadian...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1C3A6B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          submitForm();
          stopPatrolTracking();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1C3A6B),
        ),
        child: const Text(
          "Selesai Patroli",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

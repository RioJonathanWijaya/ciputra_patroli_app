import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/patroli_checkpoint.dart';
import 'package:ciputra_patroli/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatroliDetailSheet extends StatefulWidget {
  final Patroli patroli;

  const PatroliDetailSheet({
    Key? key,
    required this.patroli,
  }) : super(key: key);

  @override
  State<PatroliDetailSheet> createState() => _PatroliDetailSheetState();
}

class _PatroliDetailSheetState extends State<PatroliDetailSheet> {
  final ApiService _apiService = ApiService();
  List<PatroliCheckpoint> _checkpoints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
  }

  Future<void> _loadCheckpoints() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final checkpoints =
          await _apiService.getCheckpointsByPatroliId(widget.patroli.id);
      setState(() {
        _checkpoints = checkpoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    String startTime = widget.patroli.jamMulai != null
        ? timeFormat.format(widget.patroli.jamMulai!)
        : '-';
    String endTime = widget.patroli.jamSelesai != null
        ? timeFormat.format(widget.patroli.jamSelesai!)
        : '-';
    String duration = widget.patroli.durasiPatroli != null
        ? _formatDuration(widget.patroli.durasiPatroli!)
        : '-';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    color: Color(0xFF1C3A6B), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Detail Patroli',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C3A6B),
                        letterSpacing: 0.2,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close,
                        color: Color(0xFF1C3A6B), size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE0E6ED),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C3A6B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today,
                                  color: Color(0xFF1C3A6B), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              dateFormat.format(widget.patroli.tanggal),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C3A6B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.patroli.isTerlambat
                                    ? const Color(0xFFFDEDED)
                                    : const Color(0xFFEDF7ED),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.patroli.isTerlambat
                                    ? 'Terlambat'
                                    : 'Tepat Waktu',
                                style: TextStyle(
                                  color: widget.patroli.isTerlambat
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF2E7D32),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                            Icons.access_time, 'Jam Mulai', startTime),
                        _buildInfoTile(
                            Icons.access_time, 'Jam Selesai', endTime),
                        _buildInfoTile(Icons.timer, 'Durasi Patroli', duration),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Checkpoints Section
                  _buildSectionHeader(
                    title: 'Checkpoints',
                    icon: Icons.place,
                    count: _checkpoints.length,
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? _buildLoadingIndicator()
                      : _error != null
                          ? _buildErrorIndicator()
                          : _checkpoints.isEmpty
                              ? _buildEmptyCheckpoints()
                              : Column(
                                  children: _checkpoints
                                      .map((checkpoint) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: _buildCheckpointCard(
                                                checkpoint),
                                          ))
                                      .toList(),
                                ),
                  // Notes Section if available
                  if (widget.patroli.catatanPatroli.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Catatan Patroli',
                      icon: Icons.notes,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.patroli.catatanPatroli,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C3A6B),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    int? count,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1C3A6B), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C3A6B),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1C3A6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C3A6B),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1C3A6B).withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C3A6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointCard(PatroliCheckpoint checkpoint) {
    final timeFormat = DateFormat('HH:mm');
    String time = timeFormat.format(DateTime.parse(checkpoint.timestamp));

    return Container(
      width: double.infinity,
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
        border: Border.all(
          color: const Color(0xFFE0E6ED),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C3A6B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.place,
                      color: const Color(0xFF1C3A6B), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    checkpoint.checkpointName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C3A6B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: checkpoint.status == 'Late'
                        ? const Color(0xFFFDEDED)
                        : const Color(0xFFEDF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    checkpoint.status == 'Late' ? 'Terlambat' : 'Tepat Waktu',
                    style: TextStyle(
                      color: checkpoint.status == 'Late'
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Waktu', time),
                const SizedBox(height: 12),
                _buildDetailRow('Koordinat',
                    '${checkpoint.latitude}, ${checkpoint.longitude}'),
                if (checkpoint.keterangan != null &&
                    checkpoint.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Keterangan', checkpoint.keterangan!),
                ],
                if (checkpoint.imagePath != null &&
                    checkpoint.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Foto Checkpoint',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      checkpoint.imagePath!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF1C3A6B),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.grey, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1C3A6B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1C3A6B),
        ),
      ),
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 32),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat data checkpoint',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Terjadi kesalahan',
            style: const TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadCheckpoints,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD32F2F)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCheckpoints() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.place, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada checkpoint',
            style: TextStyle(
              color: Color(0xFF1C3A6B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ditemukan data checkpoint untuk patroli ini',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours jam $minutes menit';
  }
}

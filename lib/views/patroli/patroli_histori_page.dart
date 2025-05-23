import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/services/firebase_service.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/views/patroli/patroli_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PatroliHistori extends StatefulWidget {
  const PatroliHistori({Key? key}) : super(key: key);

  @override
  State<PatroliHistori> createState() => _PatroliHistoriPageState();
}

class _PatroliHistoriPageState extends State<PatroliHistori> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Patroli> _patroliList = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatroliData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatroliData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = await _firebaseService.dbRef.child('patroli').get();
      if (snapshot.value == null) {
        setState(() {
          _patroliList = [];
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      _patroliList = [];

      data.forEach((key, value) {
        if (value is Map) {
          final Map<String, dynamic> patrolData = {};
          value.forEach((k, v) {
            patrolData[k.toString()] = v;
          });
          patrolData['id'] = key.toString();

          try {
            final patroli = Patroli.fromMap(patrolData);
            _patroliList.add(patroli);
          } catch (e) {
            debugPrint('Error parsing patrol data: $e');
          }
        }
      });

      _patroliList.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patroli data: $e');
      setState(() {
        _error = 'Gagal memuat data patroli';
        _isLoading = false;
      });
    }
  }

  List<Patroli> get _filteredPatroliList {
    if (_searchQuery.isEmpty) return _patroliList;
    return _patroliList.where((patroli) {
      final date = DateFormat('dd MMMM yyyy', 'id_ID').format(patroli.tanggal);
      return date.toLowerCase().contains(_searchQuery) ||
          (patroli.isTerlambat ? 'terlambat' : 'tepat waktu')
              .contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Riwayat Patroli"),
        backgroundColor: const Color(0xFF1C3A6B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _patroliList.isEmpty
                    ? _buildEmptyState()
                    : _buildPatroliList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPatroliData,
        backgroundColor: const Color(0xFF1C3A6B),
        child: const Icon(Icons.refresh, color: Colors.white),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildPatroliCard(Patroli patroli) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    String startTime =
        patroli.jamMulai != null ? timeFormat.format(patroli.jamMulai!) : '-';
    String endTime = patroli.jamSelesai != null
        ? timeFormat.format(patroli.jamSelesai!)
        : '-';
    String duration = patroli.durasiPatroli != null
        ? _formatDuration(patroli.durasiPatroli!)
        : '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showPatroliDetail(patroli),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and status
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(patroli.tanggal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C3A6B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: patroli.isTerlambat
                            ? const LinearGradient(
                                colors: [Color(0xFFFFCDD2), Color(0xFFEF9A9A)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        patroli.isTerlambat ? 'Terlambat' : 'Tepat Waktu',
                        style: TextStyle(
                          color: patroli.isTerlambat
                              ? const Color(0xFFC62828)
                              : const Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Info rows
              _buildInfoRow(Icons.schedule, 'Jam Mulai', startTime),
              _buildInfoRow(Icons.schedule, 'Jam Selesai', endTime),
              _buildInfoRow(Icons.timer, 'Durasi Patroli', duration),
              _buildInfoRow(Icons.place, 'Checkpoint',
                  '${patroli.checkpoints.length} titik'),
              const SizedBox(height: 8),
              // Footer
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C3A6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lihat detail →',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1C3A6B).withOpacity(0.8),
                      fontWeight: FontWeight.w500,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1C3A6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF1C3A6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari berdasarkan tanggal...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF1C3A6B)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C3A6B)),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat patroli',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lakukan patroli pertama Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPatroliData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C3A6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatroliList() {
    final filteredList = _filteredPatroliList;

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba dengan kata kunci lain',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatroliData,
      color: const Color(0xFF1C3A6B),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final patroli = filteredList[index];
          return _buildPatroliCard(patroli);
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours jam $minutes menit';
  }

  void _showPatroliDetail(Patroli patroli) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatroliDetailSheet(patroli: patroli),
    );
  }
}

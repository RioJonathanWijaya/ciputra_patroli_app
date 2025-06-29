import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/viewModel/kejadian_viewModel.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';

class KejadianListPage extends StatefulWidget {
  const KejadianListPage({super.key});

  @override
  State<KejadianListPage> createState() => _KejadianListPageState();
}

class _KejadianListPageState extends State<KejadianListPage> {
  bool _initialLoadComplete = false;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedTipe = 'all';
  bool _isFilterExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Kejadian> _getFilteredKejadianList(KejadianViewModel kejadianVM) {
    return kejadianVM.kejadianList.where((kejadian) {
      // Search filter
      final searchMatch = _searchQuery.isEmpty ||
          kejadian.namaKejadian
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          kejadian.lokasiKejadian
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          kejadian.keterangan
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Status filter
      final statusMatch = _selectedStatus == 'all' ||
          kejadian.status.toLowerCase() == _selectedStatus.toLowerCase();

      // Tipe filter
      final tipeMatch = _selectedTipe == 'all' ||
          kejadian.tipeKejadian.toLowerCase() == _selectedTipe.toLowerCase();

      return searchMatch && statusMatch && tipeMatch;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari kejadian...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1C3A6B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF1C3A6B)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterSection(KejadianViewModel kejadianVM) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: const Color(0xFF1C3A6B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C3A6B),
                      ),
                    ),
                    if (_selectedStatus != 'all' || _selectedTipe != 'all')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C3A6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedStatus != 'all' ? '1' : '0'}${_selectedTipe != 'all' ? ' + 1' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C3A6B),
                          ),
                        ),
                      ),
                  ],
                ),
                Icon(
                  _isFilterExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF1C3A6B),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: _buildFilterChips(kejadianVM),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isFilterExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildFilterChips(KejadianViewModel kejadianVM) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C3A6B),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Baru', 'baru', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Proses', 'proses', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Selesai', 'selesai', _selectedStatus,
                    (value) {
                  setState(() => _selectedStatus = value);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Filter Tipe',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C3A6B),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all', _selectedTipe, (value) {
                  setState(() => _selectedTipe = value);
                }),
                _buildFilterChip('Ringan', 'ringan', _selectedTipe, (value) {
                  setState(() => _selectedTipe = value);
                }),
                _buildFilterChip('Sedang', 'sedang', _selectedTipe, (value) {
                  setState(() => _selectedTipe = value);
                }),
                _buildFilterChip('Berat', 'berat', _selectedTipe, (value) {
                  setState(() => _selectedTipe = value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue,
      Function(String) onSelected) {
    final isSelected = value == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          onSelected(selected ? value : 'all');
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1C3A6B).withOpacity(0.1),
        checkmarkColor: const Color(0xFF1C3A6B),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1C3A6B) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1C3A6B) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, loginViewModel, child) {
        return ChangeNotifierProvider<KejadianViewModel>(
            create: (_) => KejadianViewModel(),
            child: Scaffold(
              backgroundColor: const Color(0xFFF8FAFD),
              body: Consumer<KejadianViewModel>(
                builder: (context, kejadianVM, child) {
                  if (!_initialLoadComplete && !kejadianVM.isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      kejadianVM.getAllKejadianData().then((_) {
                        setState(() {
                          _initialLoadComplete = true;
                        });
                      });
                    });
                  }

                  if (kejadianVM.isLoading && !_initialLoadComplete) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1C3A6B)),
                          ),
                          SizedBox(height: 16),
                          Text('Memuat data kejadian...',
                              style: TextStyle(color: Color(0xFF1C3A6B))),
                        ],
                      ),
                    );
                  }

                  final filteredList = _getFilteredKejadianList(kejadianVM);

                  return Column(
                    children: [
                      _buildSearchBar(),
                      _buildFilterSection(kejadianVM),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: RefreshIndicator(
                            color: const Color(0xFF1C3A6B),
                            onRefresh: () => kejadianVM.getAllKejadianData(),
                            child: filteredList.isEmpty && _initialLoadComplete
                                ? _buildEmptyState(context)
                                : ListView.separated(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final kejadian = filteredList[index];
                                      return _buildKejadianCard(
                                          kejadian,
                                          () => _showKejadianDetail(
                                              context, kejadian));
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: "urgentBtn",
                    onPressed: () {
                      NavigationService.navigateTo('/urgentKejadianInput');
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "regularBtn",
                    onPressed: () {
                      NavigationService.navigateTo('/kejadianInput');
                    },
                    backgroundColor: const Color(0xFF1C3A6B),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tidak Ada Laporan Kejadian',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada kejadian yang dilaporkan.\nTekan tombol + untuk membuat laporan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                NavigationService.navigateTo('/kejadianInput');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C3A6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Buat Laporan Baru',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKejadianCard(Kejadian kejadian, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      kejadian.namaKejadian,
                      style: const TextStyle(
                        color: Color(0xFF1C3A6B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getColorForTipeKejadian(kejadian.tipeKejadian)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getColorForTipeKejadian(kejadian.tipeKejadian),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      kejadian.tipeKejadian,
                      style: TextStyle(
                        color: _getColorForTipeKejadian(kejadian.tipeKejadian),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      kejadian.lokasiKejadian,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm')
                        .format(kejadian.tanggalKejadian),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(kejadian.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      kejadian.status,
                      style: TextStyle(
                        color: _getStatusColor(kejadian.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (kejadian.isKecelakaan || kejadian.isPencurian) ...[
                const Divider(height: 20, thickness: 1),
                Row(
                  children: [
                    Icon(
                      kejadian.isKecelakaan ? Icons.car_crash : Icons.security,
                      size: 18,
                      color: const Color(0xFF1C3A6B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kejadian.isKecelakaan ? 'Kecelakaan' : 'Pencurian',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C3A6B),
                      ),
                    ),
                    if (kejadian.namaKorban != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${kejadian.namaKorban}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showKejadianDetail(BuildContext context, Kejadian kejadian) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1C3A6B),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Detail Kejadian",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      icon: Icons.event,
                      title: "Informasi Kejadian",
                      children: [
                        _buildDetailItem(
                            "Nama Kejadian", kejadian.namaKejadian),
                        _buildDetailItem("Lokasi", kejadian.lokasiKejadian),
                        _buildDetailItem(
                          "Tanggal & Waktu",
                          "${DateFormat('dd MMMM yyyy').format(kejadian.tanggalKejadian)} • ${DateFormat('HH:mm').format(kejadian.tanggalKejadian)}",
                        ),
                        _buildDetailItem(
                            "Tipe Kejadian", kejadian.tipeKejadian),
                        _buildDetailItem(
                          "Status",
                          kejadian.status,
                          statusColor: _getStatusColor(kejadian.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      icon: Icons.description,
                      title: "Keterangan",
                      children: [
                        Text(
                          kejadian.keterangan,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    if (kejadian.namaKorban != null &&
                        kejadian.namaKorban!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildDetailCard(
                            icon: Icons.person,
                            title: "Informasi Korban",
                            children: [
                              _buildDetailItem(
                                  "Nama Korban", kejadian.namaKorban!),
                              if (kejadian.alamatKorban != null &&
                                  kejadian.alamatKorban!.isNotEmpty)
                                _buildDetailItem(
                                    "Alamat Korban", kejadian.alamatKorban!),
                              if (kejadian.keteranganKorban != null &&
                                  kejadian.keteranganKorban!.isNotEmpty)
                                _buildDetailItem(
                                    "Keterangan", kejadian.keteranganKorban!),
                            ],
                          ),
                        ],
                      ),
                    if (kejadian.fotoBuktiUrls != null &&
                        kejadian.fotoBuktiUrls!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildDetailCard(
                            icon: Icons.photo_camera,
                            title: "Bukti Foto",
                            children: [
                              const SizedBox(height: 8),
                              ...kejadian.fotoBuktiUrls!
                                  .map((url) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Image.network(
                                              url,
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  height: 200,
                                                  alignment: Alignment.center,
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                height: 200,
                                                color: Colors.grey.shade200,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      icon: Icons.assignment_ind,
                      title: "Pelaporan",
                      children: [
                        _buildDetailItem("Satpam", kejadian.satpamNama),
                        _buildDetailItem(
                          "Waktu Laporan",
                          DateFormat('dd MMMM yyyy HH:mm')
                              .format(kejadian.waktuLaporan),
                        ),
                        if (kejadian.waktuSelesai != null)
                          _buildDetailItem(
                            "Waktu Selesai",
                            DateFormat('dd MMMM yyyy HH:mm')
                                .format(kejadian.waktuSelesai!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailCard(
                      icon: Icons.assignment_ind,
                      title: "Tindakan",
                      children: [
                        _buildDetailItem(
                          "Tindakan",
                          kejadian.tindakan != null &&
                                  kejadian.tindakan!.isNotEmpty
                              ? kejadian.tindakan!
                                  .map((t) => "- ${t.tindakan}")
                                  .join("\n")
                              : "Tidak ada tindakan",
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green.shade600;
      case 'dalam proses':
        return Colors.orange.shade600;
      case 'darurat':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: statusColor ?? Colors.black87,
              fontWeight:
                  statusColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForTipeKejadian(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'ringan':
        return Colors.green;
      case 'sedang':
        return Colors.orange;
      case 'berat':
        return Colors.red;
      case 'kritis':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/viewModel/kejadian_viewModel.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';

class NotifikasiListPage extends StatefulWidget {
  const NotifikasiListPage({super.key});

  @override
  State<NotifikasiListPage> createState() => _NotifikasiListPageState();
}

class _NotifikasiListPageState extends State<NotifikasiListPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _initialLoadComplete = false;
  List<Kejadian> _notifikasiList = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedTipe = 'all';
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final kejadianVM = Provider.of<KejadianViewModel>(context, listen: false);
    await kejadianVM.getAllKejadianDataNotifikasi();
    _updateNotifikasiList(kejadianVM);
    setState(() => _initialLoadComplete = true);
  }

  void _updateNotifikasiList(KejadianViewModel kejadianVM) {
    _notifikasiList = kejadianVM.kejadianList
        .where((kejadian) => kejadian.isNotifikasi)
        .toList();
  }

  void _handleNotificationTap(RemoteMessage message) {
    final kejadianId = message.data['kejadian_id'];
    if (kejadianId != null) {
      final kejadianVM = Provider.of<KejadianViewModel>(context, listen: false);
      final kejadian = kejadianVM.kejadianList.firstWhere(
        (k) => k.id == kejadianId,
        orElse: () => Kejadian.empty(),
      );
      if (kejadian.id.isNotEmpty) {
        _showNotifikasiDetail(context, kejadian);
      }
    }
  }

  List<Kejadian> _getFilteredNotifikasiList() {
    return _notifikasiList.where((kejadian) {
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
          hintText: 'Cari notifikasi...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4E6AFF)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF4E6AFF)),
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

  Widget _buildFilterSection() {
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
                      color: const Color(0xFF4E6AFF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4E6AFF),
                      ),
                    ),
                    if (_selectedStatus != 'all' || _selectedTipe != 'all')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E6AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedStatus != 'all' ? '1' : '0'}${_selectedTipe != 'all' ? ' + 1' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E6AFF),
                          ),
                        ),
                      ),
                  ],
                ),
                Icon(
                  _isFilterExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF4E6AFF),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: _buildFilterChips(),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isFilterExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
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
              color: Color(0xFF4E6AFF),
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
              color: Color(0xFF4E6AFF),
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
        selectedColor: const Color(0xFF4E6AFF).withOpacity(0.1),
        checkmarkColor: const Color(0xFF4E6AFF),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF4E6AFF) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4E6AFF) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KejadianViewModel>(
      builder: (context, kejadianVM, child) {
        if (_initialLoadComplete) {
          _updateNotifikasiList(kejadianVM);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildContent(kejadianVM),
        );
      },
    );
  }

  Widget _buildContent(KejadianViewModel kejadianVM) {
    if (!_initialLoadComplete && !kejadianVM.isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E6AFF)),
      ));
    }

    if (kejadianVM.isLoading && !_initialLoadComplete) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E6AFF)),
      ));
    }

    final filteredList = _getFilteredNotifikasiList();

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterSection(),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF4E6AFF),
            onRefresh: () => kejadianVM.getAllKejadianDataNotifikasi(),
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final kejadian = filteredList[index];
                      return _buildNotifikasiCard(context, kejadian);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Belum ada notifikasi kejadian yang perlu ditindaklanjuti',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifikasiCard(BuildContext context, Kejadian kejadian) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNotifikasiDetail(context, kejadian),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(kejadian.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(kejadian.status),
                      color: _getStatusColor(kejadian.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kejadian.namaKejadian,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm')
                              .format(kejadian.tanggalKejadian),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(kejadian.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusText(kejadian.status),
                      style: TextStyle(
                          color: _getStatusColor(kejadian.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kejadian.lokasiKejadian,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (kejadian.isKecelakaan || kejadian.isPencurian) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kejadian.isKecelakaan
                            ? Icons.car_crash
                            : Icons.warning_amber_outlined,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kejadian.isKecelakaan ? 'KECELAKAAN' : 'PENCURIAN',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifikasiDetail(BuildContext context, Kejadian kejadian) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Kejadian',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(kejadian.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusText(kejadian.status),
                      style: TextStyle(
                          color: _getStatusColor(kejadian.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailCard(
                        icon: Icons.info_outline,
                        title: "Informasi Kejadian",
                        children: [
                          _buildDetailRow(
                            icon: Icons.title_outlined,
                            title: 'Nama Kejadian',
                            value: kejadian.namaKejadian,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            title: 'Lokasi',
                            value: kejadian.lokasiKejadian,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.access_time_outlined,
                            title: 'Waktu Kejadian',
                            value: DateFormat('EEEE, dd MMMM yyyy, HH:mm')
                                .format(kejadian.tanggalKejadian),
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.description_outlined,
                            title: 'Keterangan',
                            value: kejadian.keterangan,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                      if (kejadian.isKecelakaan || kejadian.isPencurian) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          icon: Icons.description,
                          title: "Detail Kejadian",
                          children: [
                            _buildDetailItem(
                                "Tipe Kejadian", kejadian.tipeKejadian),
                            if (kejadian.keterangan.isNotEmpty)
                              _buildDetailItem(
                                  "Keterangan", kejadian.keterangan),
                          ],
                        ),
                      ],
                      if (kejadian.namaKorban != null &&
                          kejadian.namaKorban!.isNotEmpty) ...[
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
                      if (kejadian.keterangan != null &&
                          kejadian.keterangan!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          icon: Icons.info,
                          title: "Keterangan",
                          children: [
                            _buildDetailItem(
                                "Keterangan", kejadian.keterangan!),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        icon: Icons.person_outline,
                        title: "Informasi Pelapor",
                        children: [
                          _buildDetailRow(
                            icon: Icons.person_outline,
                            title: 'Pelapor',
                            value: kejadian.satpamNama,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.access_time_outlined,
                            title: 'Waktu Laporan',
                            value: DateFormat('EEEE, dd MMMM yyyy, HH:mm')
                                .format(kejadian.waktuLaporan),
                          ),
                          if (kejadian.waktuSelesai != null) ...[
                            const Divider(height: 16),
                            _buildDetailRow(
                              icon: Icons.check_circle_outline,
                              title: 'Waktu Selesai',
                              value: DateFormat('EEEE, dd MMMM yyyy, HH:mm')
                                  .format(kejadian.waktuSelesai!),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => NavigationService.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF4E6AFF)),
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(color: Color(0xFF4E6AFF))),
                    ),
                  ),
                  if (kejadian.status != 'selesai') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          NavigationService.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E6AFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tindak Lanjut',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    IconData? icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF2D3748), fontSize: 15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    IconData? icon,
    required String title,
    required String value,
    bool isMultiLine = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style:
                        const TextStyle(color: Color(0xFF2D3748), fontSize: 15),
                    maxLines: isMultiLine ? null : 2,
                    overflow: isMultiLine ? null : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return const Color(0xFFF59E0B);
      case 'diproses':
        return const Color(0xFF3B82F6);
      case 'selesai':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return Icons.notifications_none_outlined;
      case 'diproses':
        return Icons.autorenew_outlined;
      case 'selesai':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return 'BARU';
      case 'diproses':
        return 'DIPROSES';
      case 'selesai':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }
}

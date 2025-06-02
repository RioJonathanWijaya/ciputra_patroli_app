import 'dart:developer';

import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/viewModel/penugasan_viewModel.dart';
import 'package:ciputra_patroli/widgets/cards/jadwal_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:ciputra_patroli/viewModel/patroli_viewModel.dart';

class JadwalPatrolPage extends StatelessWidget {
  const JadwalPatrolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, loginViewModel, child) {
        return ChangeNotifierProvider<PenugasanPatroliViewModel>(
          create: (_) => PenugasanPatroliViewModel(loginViewModel),
          child: const _JadwalPatrolContent(),
        );
      },
    );
  }
}

class _JadwalPatrolContent extends StatefulWidget {
  const _JadwalPatrolContent();

  @override
  State<_JadwalPatrolContent> createState() => _JadwalPatrolContentState();
}

class _JadwalPatrolContentState extends State<_JadwalPatrolContent> {
  @override
  void initState() {
    super.initState();
    // Load data when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final penugasanVM =
            Provider.of<PenugasanPatroliViewModel>(context, listen: false);
        penugasanVM.loadPenugasanData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, loginViewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text("Jadwal Patroli"),
            backgroundColor: const Color(0xFF1C3A6B),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
            ],
          ),
          body: Consumer<PenugasanPatroliViewModel>(
            builder: (context, penugasanVM, child) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C3A6B),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Selamat bertugas,",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  loginViewModel.satpam?.nama ??
                                      "Tidak ada nama",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM yyyy')
                                    .format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  DateFormat('HH:mm').format(DateTime.now()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildStatCard(
                                  context,
                                  "Total Patroli",
                                  penugasanVM.stats.isNotEmpty
                                      ? "${penugasanVM.stats[0]}"
                                      : "0",
                                  Icons.assignment_outlined,
                                  const Color(0xFF1C3A6B),
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  context,
                                  "Selesai",
                                  penugasanVM.stats.isNotEmpty
                                      ? "${penugasanVM.stats[1]}"
                                      : "0",
                                  Icons.check_circle_outline,
                                  const Color(0xFF0D7C5D),
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  context,
                                  "Terlambat",
                                  penugasanVM.stats.isNotEmpty
                                      ? "${penugasanVM.stats[2]}"
                                      : "0",
                                  Icons.watch_later_outlined,
                                  const Color(0xFFE53935),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search,
                                        color: Color(0xFF9E9E9E)),
                                    hintText: 'Cari jadwal patroli...',
                                    hintStyle: const TextStyle(
                                        color: Color(0xFF9E9E9E)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.filter_list,
                                      color: Color(0xFF1C3A6B)),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Daftar Patroli Hari Ini",
                                style: TextStyle(
                                  color: Color(0xFF1C3A6B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      "Terbaru",
                                      style: TextStyle(
                                        color: Color(0xFF1C3A6B),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.sort,
                                      color: Color(0xFF1C3A6B),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: penugasanVM.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF1C3A6B)),
                                    ),
                                  )
                                : penugasanVM.penugasanList.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Tidak ada jadwal patroli hari ini',
                                              style: TextStyle(
                                                color: Color(0xFF9E9E9E),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: const Color(0xFF1C3A6B),
                                        onRefresh: () async {
                                          if (mounted) {
                                            await penugasanVM
                                                .loadPenugasanData();
                                          }
                                        },
                                        child: ListView.separated(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          itemCount:
                                              penugasanVM.penugasanList.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final penugasan = Penugasan.fromMap(
                                                penugasanVM
                                                    .penugasanList[index]);
                                            return JadwalCard(
                                              penugasan: penugasan,
                                              onTap: () async {
                                                final penugasan = Penugasan
                                                    .fromMap(penugasanVM
                                                        .penugasanList[index]);
                                                log("tes ${penugasan.satpamId}");

                                                // Create PatroliViewModel first
                                                final patroliVM =
                                                    PatroliViewModel(
                                                        loginViewModel);

                                                // Create patroli object
                                                final patroli = Patroli(
                                                  id: "",
                                                  jamMulai: DateTime.now(),
                                                  jamSelesai: null,
                                                  catatanPatroli: "",
                                                  durasiPatroli: null,
                                                  rutePatroli: "",
                                                  satpamId:
                                                      loginViewModel.satpamId ??
                                                          "",
                                                  lokasiId: penugasan.lokasiId,
                                                  jadwalPatroliId:
                                                      penugasan.jadwalPatroliId,
                                                  penugasanId: penugasan.id,
                                                  isTerlambat: false,
                                                  tanggal: DateTime.now(),
                                                );

                                                await NavigationService
                                                    .navigateTo(
                                                  '/patroliMulai',
                                                  arguments: {
                                                    'penugasanVM': penugasanVM,
                                                    'patroli': patroli,
                                                    'loginVM': loginViewModel,
                                                    'penugasan': penugasan,
                                                    'patroliVM':
                                                        patroliVM, // Pass the PatroliViewModel
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      width: 160,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

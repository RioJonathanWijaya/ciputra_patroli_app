import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:ciputra_patroli/services/notification_service.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/viewModel/patroli_viewModel.dart';
import 'package:ciputra_patroli/views/patroli/patroli_histori_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PatroliPage extends StatelessWidget {
  const PatroliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<LoginViewModel>(
        builder: (context, loginViewModel, child) {
          return ChangeNotifierProvider(
            create: (_) => PatroliViewModel(loginViewModel),
            child: Consumer<PatroliViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1C3A6B)),
                    ),
                  );
                }

                if (viewModel.satpam == null) {
                  return _buildErrorState(context, viewModel);
                }

                return _buildContent(context, viewModel.satpam!);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PatroliViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Data Tidak Ditemukan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat data satpam. Silakan coba lagi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic satpam) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildHeaderSection(satpam),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _buildActionSection(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          sliver: SliverToBoxAdapter(
            child: _buildStatsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(dynamic satpam) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          satpam.nama,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C3A6B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ID: ${satpam.nip}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final NotificationService _notificationService = NotificationService();
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.directions_walk_rounded,
          label: "Mulai Patroli",
          description: "Lakukan patroli sesuai jadwal",
          color: const Color(0xFF1C3A6B),
          onPressed: () {
            NavigationService.navigateTo('/jadwalPatroli');
          },
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          icon: Icons.history_rounded,
          label: "Riwayat Patroli",
          description: "Lihat history patroli sebelumnya",
          color: const Color(0xFF0D7C5D),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoriPatroli(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Patroli',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C3A6B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatItem(
              value: '0',
              label: 'Selesai',
              color: const Color(0xFF0D7C5D),
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              value: '0',
              label: 'Pending',
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              value: '0',
              label: 'Terlambat',
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

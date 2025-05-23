import 'package:ciputra_patroli/models/satpam.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewModel>(context);
    final satpam = loginViewModel.satpam;

    if (satpam == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(satpam),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(satpam),
            const SizedBox(height: 16),
            _buildWorkInfoSection(satpam),
            const SizedBox(height: 16),
            _buildActionsSection(context, loginViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Satpam satpam) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Hero(
              tag: 'profile-picture',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: satpam.fotoProfile.isNotEmpty
                    ? NetworkImage(satpam.fotoProfile)
                    : const AssetImage('assets/profile_placeholder.png')
                        as ImageProvider,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getStatusColor(satpam.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.circle, size: 12, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          satpam.nama,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          satpam.email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          backgroundColor: _getShiftColor(satpam.shift),
          label: Text(
            _getShiftText(satpam.shift),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(Satpam satpam) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pribadi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('NIP', satpam.nip),
            _buildInfoRow('Nomor Telepon', satpam.nomorTelepon),
            _buildInfoRow('Alamat', satpam.alamat),
            _buildInfoRow('Tempat/Tanggal Lahir',
                '${satpam.tempatLahir}, ${_formatDate(satpam.tanggalLahir)}'),
            _buildInfoRow('Jenis Kelamin', _getGenderText(satpam.jenisKelamin)),
            _buildInfoRow('Status Pernikahan',
                _getMaritalStatusText(satpam.statusPernikahan)),
            _buildInfoRow('Pendidikan Terakhir', satpam.pendidikanTerakhir),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoSection(Satpam satpam) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pekerjaan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Jabatan', _getPositionText(satpam.jabatan)),
            _buildInfoRow('Status', _getStatusText(satpam.status)),
            _buildInfoRow(
                'Tanggal Bergabung', _formatDate(satpam.tanggalBergabung)),
            _buildInfoRow('Lokasi Penugasan', satpam.namaLokasi),
            _buildInfoRow('Supervisor ID', satpam.supervisorId.toString()),
            _buildInfoRow('Penugasan ID', satpam.penugasanId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, LoginViewModel loginViewModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.lock,
            title: 'Ubah Kata Sandi',
            onTap: () => _showChangePasswordDialog(context, loginViewModel),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.notifications,
            title: 'Pengaturan Notifikasi',
            onTap: () => NavigationService.navigateTo('/notification-settings'),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.help,
            title: 'Bantuan & Dukungan',
            onTap: () => NavigationService.navigateTo('/help'),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.logout,
            title: 'Keluar',
            color: Colors.red,
            onTap: () => _confirmLogout(context, loginViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, LoginViewModel loginViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: const Text('Apakah Anda yakin ingin mengubah kata sandi?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              NavigationService.pop();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, LoginViewModel loginViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              NavigationService.pop(); // Close dialog first
              await loginViewModel.logout(); // Then logout
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getGenderText(int satpam) {
    switch (satpam) {
      case 0:
        return 'Laki-laki';
      case 1:
        return 'Perempuan';
      default:
        return 'Tidak diketahui';
    }
  }

  String _getMaritalStatusText(int satpamStatus) {
    switch (satpamStatus) {
      case 0:
        return 'Belum menikah';
      case 1:
        return 'Menikah';
      default:
        return 'Belum Menikah';
    }
  }

  String _getPositionText(int satpamJabatan) {
    switch (satpamJabatan) {
      case 0:
        return 'Satpam';
      case 1:
        return 'Kepala Satpam';
      default:
        return 'Satpam';
    }
  }

  String _getStatusText(int satpamStatus) {
    switch (satpamStatus) {
      case 0:
        return 'Aktif';
      case 1:
        return 'Tidak Aktif';
      default:
        return 'Aktif';
    }
  }

  Color _getStatusColor(int satpamStatus) {
    switch (satpamStatus) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getShiftText(int satpamShift) {
    switch (satpamShift) {
      case 0:
        return 'Shift Pagi (07:00 - 19:00)';
      case 1:
        return 'Shift Sore (19:00 - 07:00)';
      default:
        return 'Shift Tidak Diketahui';
    }
  }

  Color _getShiftColor(int satpamShiftColor) {
    switch (satpamShiftColor) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

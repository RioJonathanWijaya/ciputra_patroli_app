import 'dart:developer';

import 'package:ciputra_patroli/models/patroli.dart';
import 'package:ciputra_patroli/models/penugasan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JadwalCard extends StatelessWidget {
  final Penugasan penugasan;
  final VoidCallback onTap;
  final bool isActive;

  const JadwalCard({
    required this.penugasan,
    required this.onTap,
    this.isActive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentDate =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
    final now = DateTime.now();
    final patrolTime = DateFormat('HH:mm').parse(penugasan.jamPatroli);
    final isUpcoming = patrolTime.isAfter(now);
    final completedCount = 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
            border: isActive
                ? Border.all(color: const Color(0xFF0D7C5D), width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Patroli ${penugasan.jamPatroli}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C3A6B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Aktif",
                        style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),

                _buildCheckpointsSection(completedCount),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendanceColumn('Masuk', '-', Icons.login),
                      _buildVerticalDivider(),
                      _buildAttendanceColumn('Keluar', '-', Icons.logout),
                      _buildVerticalDivider(),
                      _buildAttendanceColumn('Durasi', '-', Icons.access_time),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C3A6B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF1C3A6B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Patroli',
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            penugasan.namaLokasi,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C3A6B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointsSection(int completedCount) {
    final checkpoints = penugasan.titikPatroli;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Titik Patroli',
          style: TextStyle(
            color: Color(0xFF1C3A6B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (checkpoints.isEmpty)
          const Text(
            'Belum ada titik patroli',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12,
            ),
          )
        else
          Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: checkpoints.map((checkpoint) {
                  final index = checkpoints.indexOf(checkpoint);
                  final isCompleted = index < completedCount;

                  final latitude = checkpoint['lat'].toString();
                  final longitude = checkpoint['lng'].toString();

                  return Chip(
                    backgroundColor: const Color(0xFFE8F5E9),
                    label: Text(
                      'Lat: $latitude, Long: $longitude',
                      style: TextStyle(
                        color: const Color(0xFF424242),
                      ),
                    ),
                    avatar: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0D47A1),
                            size: 18,
                          )
                        : CircleAvatar(
                            backgroundColor: const Color(0xFFE0E0E0),
                            radius: 10,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF424242),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Color(0xFF0D47A1)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
      ],
    );
  }

  Widget _buildAttendanceColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF757575),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE0E0E0),
    );
  }
}

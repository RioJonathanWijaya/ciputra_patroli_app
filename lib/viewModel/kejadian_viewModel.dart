import 'dart:convert';
import 'dart:developer';
import 'package:ciputra_patroli/models/kejadian.dart';
import 'package:ciputra_patroli/services/api_service.dart';
import 'package:ciputra_patroli/services/notification_service.dart';
import 'package:flutter/material.dart';

class KejadianViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<Kejadian> _kejadianList = [];
  bool _isLoading = false;

  List<Kejadian> get kejadianList => _kejadianList;
  bool get isLoading => _isLoading;

  KejadianViewModel();

  Future<void> getAllKejadianData() async {
    _isLoading = true;
    notifyListeners();
    log("[INFO] Fetching all kejadian data...");

    try {
      _kejadianList = await _apiService.fetchAllKejadian();
      log("[INFO] Data successfully fetched. Data length: ${_kejadianList.length}");

      // Sort kejadian by date and time
      _kejadianList.sort((a, b) {
        // First compare by date
        final dateComparison =
            b.waktuLaporan.year.compareTo(a.waktuLaporan.year);
        if (dateComparison != 0) return dateComparison;

        final monthComparison =
            b.waktuLaporan.month.compareTo(a.waktuLaporan.month);
        if (monthComparison != 0) return monthComparison;

        final dayComparison = b.waktuLaporan.day.compareTo(a.waktuLaporan.day);
        if (dayComparison != 0) return dayComparison;

        // If same date, compare by time
        final timeA = a.waktuLaporan.hour * 3600 +
            a.waktuLaporan.minute * 60 +
            a.waktuLaporan.second;
        final timeB = b.waktuLaporan.hour * 3600 +
            b.waktuLaporan.minute * 60 +
            b.waktuLaporan.second;
        return timeB
            .compareTo(timeA); // Sort in descending order (newest first)
      });

      for (var data in _kejadianList) {
        log("[INFO] Checking data for null values...");

        if (data is Kejadian) {
          if (data.namaKorban == null) {
            log("[ERROR] 'namaKorban' is null");
          }
          if (data.alamatKorban == null) {
            log("[ERROR] 'alamatKorban' is null");
          }
          if (data.keteranganKorban == null) {
            log("[ERROR] 'keteranganKorban' is null");
          }
          if (data.waktuSelesai == null) {
            log("[ERROR] 'waktuSelesai' is null");
          }

          log("[DATA] ${jsonEncode(data.toMap())}");
        } else {
          log("[ERROR] Data is not of type 'Kejadian'. Type is: ${data.runtimeType}");
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      _isLoading = false;
      log("[ERROR] Failed to load Kejadian: $e");
      log("[STACKTRACE] $stacktrace");
      notifyListeners();
    }
  }

  Future<void> getAllKejadianDataNotifikasi() async {
    _isLoading = true;
    notifyListeners();
    log("[INFO] Fetching all kejadian data...");

    try {
      _kejadianList = await _apiService.fetchKejadianWithNotification();
      log("[INFO] Data successfully fetched. Data length: ${_kejadianList.length}");

      // Sort kejadian by date and time
      _kejadianList.sort((a, b) {
        // First compare by date
        final dateComparison =
            b.waktuLaporan.year.compareTo(a.waktuLaporan.year);
        if (dateComparison != 0) return dateComparison;

        final monthComparison =
            b.waktuLaporan.month.compareTo(a.waktuLaporan.month);
        if (monthComparison != 0) return monthComparison;

        final dayComparison = b.waktuLaporan.day.compareTo(a.waktuLaporan.day);
        if (dayComparison != 0) return dayComparison;

        // If same date, compare by time
        final timeA = a.waktuLaporan.hour * 3600 +
            a.waktuLaporan.minute * 60 +
            a.waktuLaporan.second;
        final timeB = b.waktuLaporan.hour * 3600 +
            b.waktuLaporan.minute * 60 +
            b.waktuLaporan.second;
        return timeB
            .compareTo(timeA); // Sort in descending order (newest first)
      });

      for (var data in _kejadianList) {
        log("[INFO] Checking data for null values...");

        if (data is Kejadian) {
          if (data.namaKorban == null) {
            log("[ERROR] 'namaKorban' is null");
          }
          if (data.alamatKorban == null) {
            log("[ERROR] 'alamatKorban' is null");
          }
          if (data.keteranganKorban == null) {
            log("[ERROR] 'keteranganKorban' is null");
          }
          if (data.waktuSelesai == null) {
            log("[ERROR] 'waktuSelesai' is null");
          }

          log("[DATA] ${jsonEncode(data.toMap())}");
        } else {
          log("[ERROR] Data is not of type 'Kejadian'. Type is: ${data.runtimeType}");
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      _isLoading = false;
      log("[ERROR] Failed to load Kejadian: $e");
      log("[STACKTRACE] $stacktrace");
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> saveKejadian(Kejadian kejadian) async {
    _isLoading = true;
    notifyListeners();
    log("[INFO] Saving kejadian data...");

    try {
      log('yeyayayya: ${kejadian.id}');
      final response = await _apiService.saveKejadian(kejadian.toMap());
      final success = response != null;

      if (success) {
        log("[INFO] Kejadian data successfully saved.");
        await getAllKejadianData();

        if (kejadian.isNotifikasi) {
          try {
            await _notificationService.sendNotificationToAll(
                kejadian.namaKejadian, kejadian.lokasiKejadian);
            log("[INFO] Notification sent successfully");
          } catch (e) {
            log("[WARNING] Failed to send notification: $e");
          }
        }

        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': 'Kejadian berhasil disimpan',
        };
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Gagal menyimpan kejadian',
        };
      }
    } catch (e) {
      _isLoading = false;
      log("[ERROR] Failed to save Kejadian: $e");
      notifyListeners();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

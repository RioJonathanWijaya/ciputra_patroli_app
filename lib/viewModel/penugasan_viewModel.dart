import 'dart:developer';
import 'package:ciputra_patroli/services/api_service.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:flutter/material.dart';

class PenugasanPatroliViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LoginViewModel _loginViewModel;

  List<Map<String, dynamic>> _penugasanList = [];
  bool _isLoading = false;
  bool _isDisposed = false;
  DateTime? _lastFetchTime;
  static const Duration _refreshInterval = Duration(minutes: 5);

  List<int> _stats = [];
  List<int> get stats => _stats;

  List<Map<String, dynamic>> get penugasanList => _penugasanList;
  bool get isLoading => _isLoading;

  PenugasanPatroliViewModel(this._loginViewModel);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool _shouldRefresh() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _refreshInterval;
  }

  Future<void> getPenugasanData() async {
    if (_isDisposed) return;

    final satpamId = _loginViewModel.satpamId;
    if (satpamId == null) {
      log("[ERROR] satpamId is null.");
      return;
    }

    // Only fetch if we haven't fetched recently
    if (!_shouldRefresh() && _penugasanList.isNotEmpty) {
      log("[INFO] Using cached penugasan data");
      return;
    }

    if (!_isDisposed) {
      _isLoading = true;
      notifyListeners();
    }

    log("[INFO] Fetching data for satpamId: $satpamId");

    try {
      final data = await _apiService.fetchPenugasanById(satpamId);
      if (!_isDisposed) {
        _penugasanList = data;
        _lastFetchTime = DateTime.now();
        log("[INFO] Data successfully fetched. Data length: ${_penugasanList.length}");

        for (var item in _penugasanList) {
          log("[DATA] ${item.toString()}");
        }
      }
    } catch (e) {
      log("[ERROR] Failed to load Penugasan: $e");
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> getStatsPatroliSatpam() async {
    if (_isDisposed) return;

    final satpamId = _loginViewModel.satpamId;
    if (satpamId == null) return;

    if (!_isDisposed) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final statsData = await _apiService.fetchStatsPatroliSatpam(satpamId);
      if (!_isDisposed) {
        _stats = statsData;
        log("[INFO] Stats successfully fetched. Stats: ${_stats.toString()}");
      }
    } catch (e) {
      log("[ERROR] Failed to load stats: $e");
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadPenugasanData() async {
    if (_isDisposed) return;

    if (!_isDisposed) {
      _setLoading(true);
    }

    try {
      await getPenugasanData();
      if (!_isDisposed) {
        await getStatsPatroliSatpam();
      }
    } catch (e) {
      log('[ERROR] Error loading penugasan data: $e');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
      notifyListeners();
    }
  }
}

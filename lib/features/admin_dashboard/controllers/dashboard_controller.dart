import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardSummary {
  final int? totalSiswa;
  final int? totalSiswaLunas;
  final int? totalBelumBayar;
  final int? totalJatuhTempo;

  const DashboardSummary({
    this.totalSiswa,
    this.totalSiswaLunas,
    this.totalBelumBayar,
    this.totalJatuhTempo,
  });

  String get totalSiswaDisplay => totalSiswa != null ? totalSiswa.toString() : '-';
  String get totalLunasDisplay => totalSiswaLunas != null ? totalSiswaLunas.toString() : '-';
  String get totalBelumBayarDisplay => totalBelumBayar != null ? totalBelumBayar.toString() : '-';
  String get totalJatuhTempoDisplay => totalJatuhTempo != null ? totalJatuhTempo.toString() : '-';

  Map<String, dynamic> toMap() {
    return {
      'totalSiswa': totalSiswa,
      'totalSiswaLunas': totalSiswaLunas,
      'totalBelumBayar': totalBelumBayar,
      'totalJatuhTempo': totalJatuhTempo,
    };
  }

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      totalSiswa: map['totalSiswa'] as int?,
      totalSiswaLunas: map['totalSiswaLunas'] as int?,
      totalBelumBayar: map['totalBelumBayar'] as int?,
      totalJatuhTempo: map['totalJatuhTempo'] as int?,
    );
  }
}

class RiwayatPembayaranItem {
  final String id;
  final String namaSiswa;
  final int nominal;
  final String status;
  final String tanggal;

  RiwayatPembayaranItem({
    required this.id,
    required this.namaSiswa,
    required this.nominal,
    required this.status,
    required this.tanggal,
  });

  factory RiwayatPembayaranItem.fromMap(Map<String, dynamic> map) {
    return RiwayatPembayaranItem(
      id: map['id']?.toString() ?? '',
      namaSiswa: map['nama_siswa']?.toString() ?? map['siswa']?['nama']?.toString() ?? 'Siswa',
      nominal: (map['nominal'] ?? map['jumlah'] ?? 0) is int
          ? (map['nominal'] ?? map['jumlah'] ?? 0) as int
          : int.tryParse((map['nominal'] ?? map['jumlah'] ?? 0).toString()) ?? 0,
      status: map['status']?.toString() ?? 'Lunas',
      tanggal: map['tanggal']?.toString() ?? map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_siswa': namaSiswa,
      'nominal': nominal,
      'status': status,
      'tanggal': tanggal,
    };
  }
}

class DashboardState {
  final bool isLoading;
  final DashboardSummary summary;
  final List<RiwayatPembayaranItem> riwayat;
  final String? error;
  final String searchQuery;

  const DashboardState({
    this.isLoading = false,
    this.summary = const DashboardSummary(),
    this.riwayat = const [],
    this.error,
    this.searchQuery = '',
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    List<RiwayatPembayaranItem>? riwayat,
    String? error,
    String? searchQuery,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      riwayat: riwayat ?? this.riwayat,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController();
});

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController() : super(const DashboardState()) {
    loadData();
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> loadData() async {
    // 0. Muat cache offline terlebih dahulu jika riwayat masih kosong
    if (state.riwayat.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_dashboard_data');
        if (cached != null && cached.isNotEmpty) {
          final map = jsonDecode(cached) as Map<String, dynamic>;
          final cachedSummary = map['summary'] != null
              ? DashboardSummary.fromMap(map['summary'] as Map<String, dynamic>)
              : state.summary;
          List<RiwayatPembayaranItem> cachedRiwayat = [];
          if (map['riwayat'] is List) {
            cachedRiwayat = (map['riwayat'] as List)
                .map((item) => RiwayatPembayaranItem.fromMap(item as Map<String, dynamic>))
                .toList();
          }
          state = state.copyWith(
            summary: cachedSummary,
            riwayat: cachedRiwayat.isNotEmpty ? cachedRiwayat : state.riwayat,
          );
        }
      } catch (_) {}
    }

    state = state.copyWith(isLoading: state.riwayat.isEmpty, error: null);

    int? totalSiswa = state.summary.totalSiswa;
    int? totalLunas = state.summary.totalSiswaLunas;
    int? totalBelumBayar = state.summary.totalBelumBayar;
    int? totalJatuhTempo = state.summary.totalJatuhTempo;
    List<RiwayatPembayaranItem> riwayatList = state.riwayat;

    // 1. Ambil summary total siswa
    try {
      final int count = await _client.from('siswa').count(CountOption.exact);
      if (count > 0) {
        totalSiswa = count;
      }
    } catch (_) {
      // Pertahankan nilai lama
    }

    // 2. Ambil summary status transaksi
    try {
      final int lunasCount = await _client
          .from('transaksi')
          .count(CountOption.exact)
          .eq('status', 'Lunas');
      if (lunasCount > 0) totalLunas = lunasCount;

      final int belumBayarCount = await _client
          .from('transaksi')
          .count(CountOption.exact)
          .eq('status', 'Belum Bayar');
      if (belumBayarCount > 0) totalBelumBayar = belumBayarCount;

      final int jatuhTempoCount = await _client
          .from('transaksi')
          .count(CountOption.exact)
          .eq('status', 'Jatuh Tempo');
      if (jatuhTempoCount > 0) totalJatuhTempo = jatuhTempoCount;
    } catch (_) {
      // Pertahankan nilai lama
    }

    // 3. Ambil riwayat pembayaran
    try {
      var query = _client.from('transaksi').select('id, nama_siswa, nominal, status, tanggal, created_at');

      if (state.searchQuery.isNotEmpty) {
        query = query.ilike('nama_siswa', '%${state.searchQuery}%');
      }

      final res = await query.order('created_at', ascending: false).limit(20);
      riwayatList = (res as List)
          .map((item) => RiwayatPembayaranItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Saat lost connection / offline, pertahankan data terakhir
    }

    final newSummary = DashboardSummary(
      totalSiswa: totalSiswa,
      totalSiswaLunas: totalLunas,
      totalBelumBayar: totalBelumBayar,
      totalJatuhTempo: totalJatuhTempo,
    );

    state = state.copyWith(
      isLoading: false,
      summary: newSummary,
      riwayat: riwayatList,
    );

    // Simpan ke cache offline
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = {
        'summary': newSummary.toMap(),
        'riwayat': riwayatList.map((r) => r.toMap()).toList(),
      };
      await prefs.setString('cache_dashboard_data', jsonEncode(cacheMap));
    } catch (_) {}
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin_dashboard/controllers/dashboard_controller.dart';
import '../../admin_paket/models/paket_model.dart';
import '../models/transaksi_model.dart';

class TransaksiState {
  final bool isLoading;
  final List<TransaksiModel> daftarTransaksi;
  final List<Map<String, String>> daftarSiswa; // [{'id': ..., 'nama': ...}]
  final String selectedFilter; // 'All' atau nama paket
  final String searchQuery;
  final String? error;

  const TransaksiState({
    this.isLoading = false,
    this.daftarTransaksi = const [],
    this.daftarSiswa = const [],
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.error,
  });

  List<TransaksiModel> get filteredTransaksi {
    var list = daftarTransaksi;
    if (selectedFilter != 'All') {
      list = list.where((t) {
        final kat = t.kategori ?? '';
        return kat.toLowerCase() == selectedFilter.toLowerCase();
      }).toList();
    }
    if (searchQuery.isNotEmpty) {
      list = list.where((t) {
        return t.namaSiswa.toLowerCase().contains(searchQuery.toLowerCase()) ||
            t.status.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    return list;
  }

  TransaksiState copyWith({
    bool? isLoading,
    List<TransaksiModel>? daftarTransaksi,
    List<Map<String, String>>? daftarSiswa,
    String? selectedFilter,
    String? searchQuery,
    String? error,
  }) {
    return TransaksiState(
      isLoading: isLoading ?? this.isLoading,
      daftarTransaksi: daftarTransaksi ?? this.daftarTransaksi,
      daftarSiswa: daftarSiswa ?? this.daftarSiswa,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

final transaksiControllerProvider =
    StateNotifierProvider<TransaksiController, TransaksiState>((ref) {
  return TransaksiController(ref);
});

class TransaksiController extends StateNotifier<TransaksiState> {
  final Ref _ref;
  TransaksiController(this._ref) : super(const TransaksiState()) {
    loadData();
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> loadData() async {
    await Future.wait([
      loadTransaksi(),
      loadSiswa(),
    ]);
  }

  Future<void> loadTransaksi() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      dynamic res;
      try {
        res = await _client
            .from('transaksi')
            .select('id, siswa_id, paket_id, nama_siswa, nominal, status, tanggal, metode, catatan, kategori, created_at')
            .order('created_at', ascending: false);
      } catch (_) {
        res = await _client
            .from('transaksi')
            .select('id, siswa_id, nama_siswa, nominal, status, tanggal, metode, catatan, created_at')
            .order('created_at', ascending: false);
      }

      final list = (res as List)
          .map((item) => TransaksiModel.fromMap(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, daftarTransaksi: list);
    } catch (_) {
      // Jika tabel belum dibuat / belum ada data, biarkan kosong []
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadSiswa() async {
    try {
      final res = await _client
          .from('siswa')
          .select('id, nama')
          .order('nama', ascending: true);

      final list = (res as List)
          .map((item) => {
                'id': item['id']?.toString() ?? '',
                'nama': item['nama']?.toString() ?? '',
              })
          .toList();

      state = state.copyWith(daftarSiswa: list);
    } catch (_) {
      // Abaikan jika tabel siswa belum ada
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<bool> tambahTransaksi({
    required String namaSiswa,
    String? siswaId,
    String? paketId,
    required int nominal,
    required String metode,
    required String tanggal,
    String? catatan,
    String status = 'Lunas',
    String? kategori,
  }) async {
    state = state.copyWith(isLoading: true);

    final localItem = TransaksiModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      namaSiswa: namaSiswa,
      siswaId: siswaId,
      paketId: paketId,
      nominal: nominal,
      metode: metode,
      tanggal: tanggal,
      catatan: catatan,
      status: status,
      kategori: kategori ?? 'Paket Bimbel',
    );

    try {
      // Normalisasi metode agar sesuai constraint check database Supabase ('Cash' / 'Transfer')
      String dbMetode = 'Cash';
      if (metode.toLowerCase().contains('transfer')) {
        dbMetode = 'Transfer';
      } else {
        dbMetode = 'Cash';
      }

      final insertData = {
        'nama_siswa': namaSiswa,
        'nominal': nominal,
        'metode': dbMetode,
        'tanggal': tanggal,
        'tgl_bayar': DateTime.now().toIso8601String(),
        'status': status,
        if (siswaId != null) 'siswa_id': siswaId,
        if (paketId != null) 'paket_id': paketId,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        if (kategori != null) 'kategori': kategori,
      };

      dynamic res;
      try {
        res = await _client.from('transaksi').insert(insertData).select().maybeSingle();
      } catch (insertError) {
        // Jika kolom paket_id belum ada di tabel Supabase, coba insert tanpa paket_id
        final fallbackData = Map<String, dynamic>.from(insertData)..remove('paket_id');
        res = await _client.from('transaksi').insert(fallbackData).select().maybeSingle();
      }

      if (res != null) {
        final serverItem = TransaksiModel.fromMap(res);
        final mergedItem = serverItem.copyWith(
          paketId: serverItem.paketId ?? paketId,
          kategori: serverItem.kategori ?? (kategori ?? 'Paket Bimbel'),
        );
        state = state.copyWith(
          isLoading: false,
          daftarTransaksi: [mergedItem, ...state.daftarTransaksi],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          daftarTransaksi: [localItem, ...state.daftarTransaksi],
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('ERROR SUPABASE INSERT TRANSAKSI: $e');
      // Simpan di local state jika Supabase belum siap
      state = state.copyWith(
        isLoading: false,
        daftarTransaksi: [localItem, ...state.daftarTransaksi],
      );
    }

    // Refresh ringkasan dasbor agar sinkron
    try {
      _ref.read(dashboardControllerProvider.notifier).loadData();
    } catch (_) {}

    return true;
  }

  static String resolveKategori(TransaksiModel t, List<PaketModel> daftarPaket) {
    // 1. Cocokkan berdasarkan paketId jika ada
    if (t.paketId != null && t.paketId!.isNotEmpty) {
      for (final p in daftarPaket) {
        if (p.id == t.paketId) {
          return p.namaPaket;
        }
      }
    }

    // 2. Cocokkan berdasarkan nama kategori yang sudah ada jika masih terdaftar
    final kat = t.kategori?.trim();
    if (kat != null && kat.isNotEmpty) {
      for (final p in daftarPaket) {
        if (p.namaPaket.trim().toLowerCase() == kat.toLowerCase()) {
          return p.namaPaket;
        }
      }
    }

    // 3. Jika nama kategori lama (misal: "abogoboga") sudah tidak ada di daftar paket aktif
    // karena diubah namanya, cocokkan dengan paket yang memiliki nominal yang sama!
    for (final p in daftarPaket) {
      if (p.nominal == t.nominal) {
        return p.namaPaket;
      }
    }

    // 4. Cek catatan jika ada format "Paket: [Nama]"
    if (t.catatan != null) {
      final match = RegExp(r'Paket:\s*([^\s\-\(\)]+)').firstMatch(t.catatan!);
      if (match != null && match.group(1) != null) {
        final ext = match.group(1)!.trim();
        for (final p in daftarPaket) {
          if (p.namaPaket.trim().toLowerCase() == ext.toLowerCase()) {
            return p.namaPaket;
          }
        }
      }
    }

    return kat ?? 'All';
  }

  List<TransaksiModel> getFilteredTransaksi(List<PaketModel> daftarPaket) {
    var list = state.daftarTransaksi;
    if (state.selectedFilter != 'All') {
      list = list.where((t) {
        final eff = resolveKategori(t, daftarPaket);
        return eff.toLowerCase() == state.selectedFilter.toLowerCase();
      }).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      list = list.where((t) {
        return t.namaSiswa.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
            t.status.toLowerCase().contains(state.searchQuery.toLowerCase());
      }).toList();
    }
    return list;
  }

  void syncUpdatedPaket({
    required String paketId,
    required String oldNama,
    required String newNama,
    int? oldNominal,
    int? newNominal,
  }) {
    final updatedList = state.daftarTransaksi.map((t) {
      final isMatchId = t.paketId != null && t.paketId == paketId;
      final isMatchName = t.kategori != null &&
          t.kategori!.trim().toLowerCase() == oldNama.trim().toLowerCase();
      final isMatchNominal = oldNominal != null && t.nominal == oldNominal;

      if (isMatchId || isMatchName || (t.kategori == null && isMatchNominal)) {
        String? newCatatan = t.catatan;
        if (newCatatan != null && newCatatan.contains(oldNama)) {
          newCatatan = newCatatan.replaceAll(oldNama, newNama);
        }
        return t.copyWith(
          kategori: newNama,
          paketId: paketId,
          catatan: newCatatan,
        );
      }
      return t;
    }).toList();

    String updatedFilter = state.selectedFilter;
    if (state.selectedFilter.toLowerCase() == oldNama.toLowerCase()) {
      updatedFilter = newNama;
    }

    state = state.copyWith(
      daftarTransaksi: updatedList,
      selectedFilter: updatedFilter,
    );

    // Coba update di Supabase jika terhubung
    try {
      _client
          .from('transaksi')
          .update({'kategori': newNama})
          .eq('kategori', oldNama);
    } catch (_) {}
  }

  void syncDeletedPaket({
    required String paketId,
    required String namaPaket,
  }) {
    if (state.selectedFilter.toLowerCase() == namaPaket.toLowerCase()) {
      state = state.copyWith(selectedFilter: 'All');
    }
  }

  Future<bool> hapusTransaksi(String id) async {
    try {
      await _client.from('transaksi').delete().eq('id', id);
    } catch (_) {}

    final filtered = state.daftarTransaksi.where((t) => t.id != id).toList();
    state = state.copyWith(daftarTransaksi: filtered);

    try {
      _ref.read(dashboardControllerProvider.notifier).loadData();
    } catch (_) {}

    return true;
  }
}

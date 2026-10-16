import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin_transaksi/controllers/transaksi_controller.dart';
import '../models/user_wali_model.dart';

class UserWaliState {
  final bool isLoading;
  final List<UserWaliModel> daftarWali;
  final String searchQuery;
  final String filterStatus; // 'Semua', 'Lunas', 'Belum Lunas', 'Baru Login'
  final String? error;

  const UserWaliState({
    this.isLoading = false,
    this.daftarWali = const [],
    this.searchQuery = '',
    this.filterStatus = 'Semua',
    this.error,
  });

  List<UserWaliModel> get filteredWali {
    var list = daftarWali;

    // Filter Status
    if (filterStatus == 'Lunas') {
      list = list.where((w) => w.statusSpp.toLowerCase() == 'lunas').toList();
    } else if (filterStatus == 'Belum Lunas') {
      list = list.where((w) => w.statusSpp.toLowerCase() != 'lunas').toList();
    } else if (filterStatus == 'Baru Login') {
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
      list = list.where((w) => w.lastLogin != null && w.lastLogin!.isAfter(oneDayAgo)).toList();
    }

    // Filter Search Query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((w) {
        return w.nama.toLowerCase().contains(q) ||
            w.namaSiswa.toLowerCase().contains(q) ||
            w.email.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  int get totalWaliLogin => daftarWali.length;
  int get totalLunas => daftarWali.where((w) => w.statusSpp.toLowerCase() == 'lunas').length;
  int get totalBelumLunas => daftarWali.where((w) => w.statusSpp.toLowerCase() != 'lunas').length;

  UserWaliState copyWith({
    bool? isLoading,
    List<UserWaliModel>? daftarWali,
    String? searchQuery,
    String? filterStatus,
    String? error,
  }) {
    return UserWaliState(
      isLoading: isLoading ?? this.isLoading,
      daftarWali: daftarWali ?? this.daftarWali,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      error: error,
    );
  }
}

final userWaliControllerProvider =
    StateNotifierProvider<UserWaliController, UserWaliState>((ref) {
  return UserWaliController(ref);
});

class UserWaliController extends StateNotifier<UserWaliState> {
  final Ref _ref;

  UserWaliController(this._ref) : super(const UserWaliState()) {
    loadUserWali();
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Memuat data langsung dari tabel 'users' di Supabase
  Future<void> loadUserWali() async {
    // 0. Muat cache offline lokal terlebih dahulu jika data masih kosong
    if (state.daftarWali.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_user_wali_data');
        if (cached != null && cached.isNotEmpty) {
          final list = (jsonDecode(cached) as List)
              .map((item) => UserWaliModel.fromMap(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            state = state.copyWith(daftarWali: list);
          }
        }
      } catch (_) {}
    }

    state = state.copyWith(isLoading: state.daftarWali.isEmpty, error: null);

    try {
      List<UserWaliModel> loadedWali = [];

      // Query langsung ke Supabase tanpa mock seed
      final res = await _client
          .from('users')
          .select('id, nama, role, email');

      if (res.isNotEmpty) {
        final transState = _ref.read(transaksiControllerProvider);

        for (final item in res) {
          final map = Map<String, dynamic>.from(item as Map);
          final role = map['role']?.toString().toLowerCase() ?? '';
          
          // Hanya ambil role Wali atau umum yang bukan Admin
          if (role == 'admin') continue;

          final nama = map['nama']?.toString() ?? 'Wali Murid';
          final email = map['email']?.toString() ?? '';
          final id = map['id']?.toString() ?? '';

          // Cek apakah ada riwayat transaksi yang cocok dengan nama siswa/wali
          final matchedTrans = transState.daftarTransaksi.where((t) {
            return t.namaSiswa.toLowerCase().contains(nama.toLowerCase()) ||
                (t.catatan != null && t.catatan!.toLowerCase().contains(nama.toLowerCase()));
          }).toList();

          final statusSpp = matchedTrans.isNotEmpty
              ? matchedTrans.first.status
              : 'Belum Ada Transaksi';
          final nominal = matchedTrans.isNotEmpty
              ? matchedTrans.first.nominal
              : 0;

          loadedWali.add(UserWaliModel(
            id: id,
            nama: nama,
            email: email,
            noHp: '-',
            namaSiswa: matchedTrans.isNotEmpty ? matchedTrans.first.namaSiswa : nama,
            role: 'Wali',
            lastLogin: DateTime.now(),
            statusSpp: statusSpp,
            totalTagihan: nominal,
            totalRiwayat: matchedTrans.length,
          ));
        }
      }

      state = state.copyWith(isLoading: false, daftarWali: loadedWali);

      // Simpan ke cache offline
      try {
        final prefs = await SharedPreferences.getInstance();
        final data = loadedWali.map((w) => w.toMap()).toList();
        await prefs.setString('cache_user_wali_data', jsonEncode(data));
      } catch (_) {}
    } catch (e) {
      // Saat offline / lost connection, pertahankan daftar yang sudah ada
      state = state.copyWith(
        isLoading: false,
      );
    }
  }

  /// Dipanggil saat user berhasil login untuk memastikan data user langsung tampil
  void recordLogin({
    required String email,
    required String nama,
    String? userId,
  }) {
    final now = DateTime.now();
    final currentList = List<UserWaliModel>.from(state.daftarWali);

    final existingIndex = currentList.indexWhere(
      (w) => (userId != null && w.id == userId) || w.email.toLowerCase() == email.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = currentList[existingIndex];
      currentList[existingIndex] = existing.copyWith(
        lastLogin: now,
        nama: nama.isNotEmpty ? nama : existing.nama,
      );
    } else {
      final newWali = UserWaliModel(
        id: userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nama: nama.isNotEmpty ? nama : email.split('@').first,
        email: email,
        noHp: '0812-0000-0000',
        namaSiswa: nama.isNotEmpty ? nama : 'Siswa',
        role: 'Wali',
        lastLogin: now,
        createdAt: now,
        statusSpp: 'Lunas',
        totalTagihan: 250000,
        totalRiwayat: 1,
      );
      currentList.insert(0, newWali);
    }

    state = state.copyWith(daftarWali: currentList);

    // Simpan ke cache offline
    try {
      SharedPreferences.getInstance().then((prefs) {
        final data = currentList.map((w) => w.toMap()).toList();
        prefs.setString('cache_user_wali_data', jsonEncode(data));
      });
    } catch (_) {}

    // Refresh dari Supabase di background
    loadUserWali();
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateFilter(String filter) {
    state = state.copyWith(filterStatus: filter);
  }
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin_dashboard/controllers/dashboard_controller.dart';
import '../../admin_paket/controllers/paket_controller.dart';
import '../../admin_paket/models/paket_model.dart';
import '../../admin_transaksi/controllers/transaksi_controller.dart';
import '../../admin_transaksi/models/transaksi_model.dart';

class WaliHomeState {
  final bool isLoading;
  final bool isSubmitting;
  final String namaWali;
  final String emailWali;
  final String namaSiswa;
  final String paketBimbel;
  final int nominalTagihan;
  final String statusTagihan; // 'Lunas', 'Belum Lunas'
  final DateTime? jatuhTempo;
  final List<TransaksiModel> daftarRiwayat;
  final String? error;

  const WaliHomeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.namaWali = '',
    this.emailWali = '',
    this.namaSiswa = '',
    this.paketBimbel = '',
    this.nominalTagihan = 0,
    this.statusTagihan = '',
    this.jatuhTempo,
    this.daftarRiwayat = const [],
    this.error,
  });

  bool get hasTagihan => nominalTagihan > 0 && paketBimbel.isNotEmpty;
  bool get hasRiwayat => daftarRiwayat.isNotEmpty;
  bool get isEmptyState => !hasTagihan && !hasRiwayat;

  String get jatuhTempoFormatted {
    if (jatuhTempo == null) return '-';
    final target = jatuhTempo!;
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${target.day} ${bulan[target.month - 1]} ${target.year}';
  }

  int get sisaHariJatuhTempo {
    if (jatuhTempo == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = jatuhTempo!;
    final due = DateTime(target.year, target.month, target.day);
    return due.difference(today).inDays;
  }

  /// Notifikasi jatuh tempo: H-7, H-3, H-1, Hari-H, atau Lewat Jatuh Tempo
  String? get notifikasiJatuhTempo {
    if (statusTagihan.toLowerCase() == 'lunas' || !hasTagihan || jatuhTempo == null) return null;
    final sisa = sisaHariJatuhTempo;
    if (sisa < 0) {
      final lewat = sisa.abs();
      return '🚨 Jatuh Tempo Terlewat! Tagihan SPP telah melewati batas waktu $lewat hari ($jatuhTempoFormatted). Mohon segera lakukan pembayaran.';
    } else if (sisa == 0) {
      return '🚨 HARI INI JATUH TEMPO! Hari ini ($jatuhTempoFormatted) adalah batas akhir pembayaran SPP. Mohon segera selesaikan transaksi.';
    } else if (sisa == 1) {
      return '🚨 Notifikasi H-1: Batas pembayaran SPP jatuh tempo BESOK ($jatuhTempoFormatted)! Harap segera lakukan pembayaran.';
    } else if (sisa <= 3) {
      return '⏰ Notifikasi H-3: Pengingat pembayaran SPP tinggal $sisa hari lagi ($jatuhTempoFormatted). Segera lakukan pembayaran.';
    } else if (sisa <= 7) {
      return '⚠️ Notifikasi H-7: Tagihan SPP bulan ini akan jatuh tempo dalam $sisa hari ($jatuhTempoFormatted).';
    }
    return null;
  }

  /// Label badge notifikasi untuk chip/icon (misal: H-1, H-3, H-7)
  String? get badgeNotifikasi {
    if (statusTagihan.toLowerCase() == 'lunas' || !hasTagihan || jatuhTempo == null) return null;
    final sisa = sisaHariJatuhTempo;
    if (sisa < 0) return 'LEWAT';
    if (sisa == 0) return 'HARI INI';
    if (sisa == 1) return 'H-1';
    if (sisa <= 3) return 'H-3';
    if (sisa <= 7) return 'H-7';
    return null;
  }

  WaliHomeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? namaWali,
    String? emailWali,
    String? namaSiswa,
    String? paketBimbel,
    int? nominalTagihan,
    String? statusTagihan,
    DateTime? jatuhTempo,
    List<TransaksiModel>? daftarRiwayat,
    String? error,
  }) {
    return WaliHomeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      namaWali: namaWali ?? this.namaWali,
      emailWali: emailWali ?? this.emailWali,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      paketBimbel: paketBimbel ?? this.paketBimbel,
      nominalTagihan: nominalTagihan ?? this.nominalTagihan,
      statusTagihan: statusTagihan ?? this.statusTagihan,
      jatuhTempo: jatuhTempo ?? this.jatuhTempo,
      daftarRiwayat: daftarRiwayat ?? this.daftarRiwayat,
      error: error,
    );
  }
}

final waliHomeControllerProvider =
    StateNotifierProvider<WaliHomeController, WaliHomeState>((ref) {
  return WaliHomeController(ref);
});

class WaliHomeController extends StateNotifier<WaliHomeState> {
  final Ref _ref;

  WaliHomeController(this._ref) : super(const WaliHomeState()) {
    loadData();
  }

  SupabaseClient get _client => Supabase.instance.client;

  String _formatDate(DateTime date) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  Future<void> loadData() async {
    // 0. Muat cache offline lokal jika ada dan bersihkan sisa dummy data lama
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentEmail = prefs.getString('user_email') ?? '';
      final currentNama = prefs.getString('user_nama') ?? '';

      final cachedJson = prefs.getString('cache_wali_data');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        final cachedSiswa = map['namaSiswa'] as String? ?? '';
        final cachedWali = map['namaWali'] as String? ?? '';
        final cachedEmail = map['emailWali'] as String? ?? '';

        final isDifferentUser = (currentEmail.isNotEmpty && cachedEmail.isNotEmpty && cachedEmail.toLowerCase() != currentEmail.toLowerCase()) ||
            (currentNama.isNotEmpty && cachedWali.isNotEmpty && cachedWali.toLowerCase() != currentNama.toLowerCase());
        final isOldDummy = cachedSiswa == 'Aisyah Putri' || cachedWali == 'Bunda Siswa' || (cachedSiswa.isEmpty && (map['nominalTagihan'] ?? 0) > 0);

        if (isDifferentUser || isOldDummy) {
          await prefs.remove('cache_wali_data');
        } else {
          List<TransaksiModel> cachedRiwayat = [];
          if (map['riwayat'] is List) {
            cachedRiwayat = (map['riwayat'] as List)
                .map((item) => TransaksiModel.fromMap(item as Map<String, dynamic>))
                .toList();
          }
          DateTime? cachedJatuhTempo;
          if (map['jatuhTempo'] != null) {
            cachedJatuhTempo = DateTime.tryParse(map['jatuhTempo'].toString());
          }

          state = state.copyWith(
            namaWali: cachedWali.isNotEmpty ? cachedWali : state.namaWali,
            emailWali: map['emailWali'] as String? ?? state.emailWali,
            namaSiswa: cachedSiswa,
            paketBimbel: map['paketBimbel'] as String? ?? '',
            nominalTagihan: map['nominalTagihan'] as int? ?? 0,
            statusTagihan: map['statusTagihan'] as String? ?? '',
            jatuhTempo: cachedJatuhTempo,
            daftarRiwayat: cachedRiwayat,
          );
        }
      }
    } catch (_) {}

    state = state.copyWith(isLoading: state.daftarRiwayat.isEmpty, error: null);

    try {
      // 1. Ambil data profil Wali dari SharedPreferences dan Supabase
      final prefs = await SharedPreferences.getInstance();
      String nama = prefs.getString('user_nama') ?? state.namaWali;
      String email = prefs.getString('user_email') ?? state.emailWali;

      final user = _client.auth.currentUser;
      if (user != null) {
        if (email.isEmpty && user.email != null) email = user.email!;
        try {
          final profile = await _client
              .from('users')
              .select('nama, role')
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            if (profile['nama'] != null && profile['nama'].toString().isNotEmpty) {
              nama = profile['nama'].toString();
            }
          }
        } catch (_) {}
      }

      if (nama.isEmpty) {
        nama = email.isNotEmpty ? email.split('@').first : 'Wali Murid';
      }

      // 2. Ambil riwayat transaksi pembayaran dari Supabase
      List<TransaksiModel> riwayat = [];
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

        if (res is List) {
          final allTrans = res
              .map((item) => TransaksiModel.fromMap(item as Map<String, dynamic>))
              .toList();

          // Saring transaksi yang BENAR-BENAR terkait dengan akun wali murid ini
          final filtered = allTrans.where((t) {
            final matchWaliCatatan = t.catatan != null &&
                ((nama.isNotEmpty && t.catatan!.toLowerCase().contains(nama.toLowerCase())) ||
                 (email.isNotEmpty && t.catatan!.toLowerCase().contains(email.toLowerCase())));
            final matchNamaWali = nama.isNotEmpty && t.namaSiswa.toLowerCase().contains(nama.toLowerCase());
            return matchWaliCatatan || matchNamaWali;
          }).toList();

          riwayat = filtered;
        }
      } catch (e) {
        riwayat = state.daftarRiwayat;
      }

      // Fallback ke daftar transaksi di state transaksiController jika riwayat Supabase kosong
      if (riwayat.isEmpty) {
        final localTrans = _ref.read(transaksiControllerProvider).daftarTransaksi;
        final filteredLocal = localTrans.where((t) {
          final matchWaliCatatan = t.catatan != null &&
              ((nama.isNotEmpty && t.catatan!.toLowerCase().contains(nama.toLowerCase())) ||
               (email.isNotEmpty && t.catatan!.toLowerCase().contains(email.toLowerCase())));
          final matchNamaWali = nama.isNotEmpty && t.namaSiswa.toLowerCase().contains(nama.toLowerCase());
          return matchWaliCatatan || matchNamaWali;
        }).toList();
        if (filteredLocal.isNotEmpty) {
          riwayat = filteredLocal;
        }
      }

      // 3. Tentukan data tagihan dan siswa berdasarkan transaksi riil
      bool sudahLunas = false;
      int nominalTagihan = 0;
      String namaPaket = '';
      String namaSiswa = '';
      DateTime? jatuhTempo;

      if (riwayat.isNotEmpty) {
        final latest = riwayat.first;
        namaSiswa = latest.namaSiswa;
        sudahLunas = latest.status.toLowerCase() == 'lunas';
        nominalTagihan = latest.nominal;
        namaPaket = latest.kategori ?? 'Paket Bimbel';

        // Cari data Jatuh Tempo & Nominal Paket dari Admin jika tersedia
        try {
          // 1. Coba dari Riverpod paketControllerProvider
          final paketFromProvider = _ref.read(paketControllerProvider).daftarPaket;
          for (final p in paketFromProvider) {
            if ((latest.paketId != null && p.id == latest.paketId) ||
                p.namaPaket.trim().toLowerCase() == namaPaket.trim().toLowerCase()) {
              jatuhTempo = p.jatuhTempo;
              // Pastikan tagihan yang harus dibayar wali selalu sesuai dengan tarif paket
              if (p.nominal > 0 && (!sudahLunas || nominalTagihan <= 0)) {
                nominalTagihan = p.nominal;
              }
              break;
            }
          }

          // 2. Fallback: coba dari cache lokal cache_paket_data
          if (jatuhTempo == null || (!sudahLunas && nominalTagihan <= 0)) {
            final cachedPaketJson = prefs.getString('cache_paket_data');
            if (cachedPaketJson != null && cachedPaketJson.isNotEmpty) {
              final listPaket = (jsonDecode(cachedPaketJson) as List)
                  .map((item) => PaketModel.fromMap(item as Map<String, dynamic>))
                  .toList();

              for (final p in listPaket) {
                if ((latest.paketId != null && p.id == latest.paketId) ||
                    p.namaPaket.trim().toLowerCase() == namaPaket.trim().toLowerCase()) {
                  jatuhTempo ??= p.jatuhTempo;
                  if (p.nominal > 0 && (!sudahLunas || nominalTagihan <= 0)) {
                    nominalTagihan = p.nominal;
                  }
                  break;
                }
              }
            }
          }
        } catch (_) {}

        // 3. Fallback: jika belum ada tanggal di paket, gunakan tanggal 25 bulan berjalan
        if (jatuhTempo == null) {
          final now = DateTime.now();
          jatuhTempo = DateTime(now.year, now.month, 25);
        }
      }

      state = state.copyWith(
        isLoading: false,
        namaWali: nama,
        emailWali: email,
        namaSiswa: namaSiswa,
        paketBimbel: namaPaket,
        nominalTagihan: nominalTagihan,
        statusTagihan: riwayat.isNotEmpty ? (sudahLunas ? 'Lunas' : 'Belum Lunas') : '',
        jatuhTempo: jatuhTempo,
        daftarRiwayat: riwayat,
        error: null,
      );

      // Simpan pembaruan ke cache offline jika terdapat data riil
      if (riwayat.isNotEmpty || nominalTagihan > 0) {
        try {
          final cacheMap = {
            'namaWali': nama,
            'emailWali': email,
            'namaSiswa': namaSiswa,
            'paketBimbel': namaPaket,
            'nominalTagihan': nominalTagihan,
            'statusTagihan': sudahLunas ? 'Lunas' : 'Belum Lunas',
            if (jatuhTempo != null) 'jatuhTempo': jatuhTempo.toIso8601String(),
            'riwayat': riwayat.map((t) => t.toMap()).toList(),
          };
          await prefs.setString('cache_wali_data', jsonEncode(cacheMap));
        } catch (_) {}
      } else {
        // Jika belum ada data riil (seperti akun Adit yang belum diinputkan transaksinya),
        // hapus cache lama agar selalu memicu Empty State murni!
        try {
          await prefs.remove('cache_wali_data');
        } catch (_) {}
      }
    } catch (e) {
      // Saat offline / lost connection, pertahankan data terakhir
      state = state.copyWith(isLoading: false);
    }
  }

  /// Proses Pembayaran Tagihan SPP oleh Wali
  Future<bool> prosesPembayaran({
    required int nominal,
    required String metode,
    required String namaPaket,
    String? catatan,
  }) async {
    state = state.copyWith(isSubmitting: true);

    final tanggal = _formatDate(DateTime.now());
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    // Normalisasi metode pembayaran sesuai format database ('Cash' / 'Transfer')
    String dbMetode = 'Cash';
    if (metode.toLowerCase().contains('transfer') ||
        metode.toLowerCase().contains('bca') ||
        metode.toLowerCase().contains('bri') ||
        metode.toLowerCase().contains('mandiri') ||
        metode.toLowerCase().contains('qris') ||
        metode.toLowerCase().contains('gopay') ||
        metode.toLowerCase().contains('ovo')) {
      dbMetode = 'Transfer';
    }

    final localItem = TransaksiModel(
      id: newId,
      namaSiswa: state.namaSiswa,
      nominal: nominal,
      status: 'Lunas',
      metode: metode,
      tanggal: tanggal,
      catatan: 'Pembayaran oleh Wali: ${state.namaWali}${catatan != null && catatan.isNotEmpty ? " ($catatan)" : ""}',
      kategori: namaPaket,
    );

    // Update state seketika (optimistic UI) dan perbarui cache lokal
    final updatedRiwayat = [localItem, ...state.daftarRiwayat];
    state = state.copyWith(
      isSubmitting: false,
      statusTagihan: 'Lunas',
      daftarRiwayat: updatedRiwayat,
    );

    // Simpan seketika ke cache offline
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = {
        'namaWali': state.namaWali,
        'emailWali': state.emailWali,
        'namaSiswa': state.namaSiswa,
        'paketBimbel': namaPaket,
        'nominalTagihan': nominal,
        'statusTagihan': 'Lunas',
        if (state.jatuhTempo != null) 'jatuhTempo': state.jatuhTempo!.toIso8601String(),
        'riwayat': updatedRiwayat.map((t) => t.toMap()).toList(),
      };
      await prefs.setString('cache_wali_data', jsonEncode(cacheMap));
    } catch (_) {}

    try {
      final insertData = {
        'nama_siswa': state.namaSiswa,
        'nominal': nominal,
        'metode': dbMetode,
        'tanggal': tanggal,
        'tgl_bayar': DateTime.now().toIso8601String(),
        'status': 'Lunas',
        'kategori': namaPaket,
        'catatan': 'Pembayaran oleh Wali: ${state.namaWali}${catatan != null && catatan.isNotEmpty ? " ($catatan)" : ""}',
      };

      try {
        await _client.from('transaksi').insert(insertData);
      } catch (e) {
        // Fallback jika ada kolom yang belum ada di schema
        final fallback = Map<String, dynamic>.from(insertData)..remove('kategori');
        await _client.from('transaksi').insert(fallback);
      }
    } catch (e) {
      // Simpan di local state jika offline / database belum siap
      // ignore: avoid_print
      print('ERROR SUPABASE INSERT TRANSAKSI WALI: $e');
    }

    // Refresh state Admin agar sinkron secara realtime
    try {
      _ref.read(transaksiControllerProvider.notifier).loadTransaksi();
      _ref.read(dashboardControllerProvider.notifier).loadData();
    } catch (_) {}

    return true;
  }
}

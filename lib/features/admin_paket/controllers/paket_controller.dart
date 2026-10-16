import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin_transaksi/controllers/transaksi_controller.dart';
import '../models/paket_model.dart';

class PaketState {
  final bool isLoading;
  final List<PaketModel> daftarPaket;
  final String? error;

  const PaketState({
    this.isLoading = false,
    this.daftarPaket = const [],
    this.error,
  });

  PaketState copyWith({
    bool? isLoading,
    List<PaketModel>? daftarPaket,
    String? error,
  }) {
    return PaketState(
      isLoading: isLoading ?? this.isLoading,
      daftarPaket: daftarPaket ?? this.daftarPaket,
      error: error,
    );
  }
}

final paketControllerProvider =
    StateNotifierProvider<PaketController, PaketState>((ref) {
  return PaketController(ref);
});

class PaketController extends StateNotifier<PaketState> {
  final Ref _ref;
  PaketController(this._ref) : super(const PaketState()) {
    loadPaket();
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _saveCache(List<PaketModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = list.map((p) => p.toMap()).toList();
      await prefs.setString('cache_paket_data', jsonEncode(data));
    } catch (_) {}
  }

  Future<void> loadPaket() async {
    // 0. Muat cache offline lokal jika daftar masih kosong
    if (state.daftarPaket.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cache_paket_data');
        if (cached != null && cached.isNotEmpty) {
          final list = (jsonDecode(cached) as List)
              .map((item) => PaketModel.fromMap(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            state = state.copyWith(daftarPaket: list);
          }
        }
      } catch (_) {}
    }

    state = state.copyWith(isLoading: state.daftarPaket.isEmpty, error: null);
    try {
      dynamic res;
      try {
        res = await _client
            .from('paket')
            .select('id, nama_paket, nominal, jatuh_tempo, created_at')
            .order('created_at', ascending: true);
      } catch (_) {
        res = await _client
            .from('paket')
            .select('id, nama_paket, nominal, created_at')
            .order('created_at', ascending: true);
      }

      final list = (res as List)
          .map((item) => PaketModel.fromMap(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, daftarPaket: list);
      _saveCache(list);
    } catch (_) {
      // Saat offline / lost connection, pertahankan data terakhir
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> tambahPaket({
    required String namaPaket,
    required int nominal,
    DateTime? jatuhTempo,
  }) async {
    state = state.copyWith(isLoading: true);

    final localNewPaket = PaketModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      namaPaket: namaPaket,
      nominal: nominal,
      badgeLetter: 'A',
      createdAt: DateTime.now(),
      jatuhTempo: jatuhTempo,
    );

    List<PaketModel> newList;
    try {
      final insertData = {
        'nama_paket': namaPaket,
        'nominal': nominal,
        if (jatuhTempo != null) 'jatuh_tempo': jatuhTempo.toIso8601String(),
      };
      dynamic res;
      try {
        res = await _client.from('paket').insert(insertData).select().maybeSingle();
      } catch (_) {
        final fallback = Map<String, dynamic>.from(insertData)..remove('jatuh_tempo');
        res = await _client.from('paket').insert(fallback).select().maybeSingle();
      }

      if (res != null) {
        final serverPaket = PaketModel.fromMap(res).copyWith(jatuhTempo: jatuhTempo);
        newList = [...state.daftarPaket, serverPaket];
      } else {
        newList = [...state.daftarPaket, localNewPaket];
      }
    } catch (e) {
      // Simpan di local state jika Supabase belum siap
      newList = [...state.daftarPaket, localNewPaket];
    }

    state = state.copyWith(
      isLoading: false,
      daftarPaket: newList,
    );
    _saveCache(newList);
    return true;
  }

  Future<bool> updatePaket({
    required String id,
    required String namaPaket,
    required int nominal,
    DateTime? jatuhTempo,
  }) async {
    state = state.copyWith(isLoading: true);

    String oldNama = '';
    int oldNominal = 0;
    try {
      final old = state.daftarPaket.firstWhere((p) => p.id == id);
      oldNama = old.namaPaket;
      oldNominal = old.nominal;
    } catch (_) {}

    try {
      final updateData = {
        'nama_paket': namaPaket,
        'nominal': nominal,
        if (jatuhTempo != null) 'jatuh_tempo': jatuhTempo.toIso8601String(),
      };
      try {
        await _client.from('paket').update(updateData).eq('id', id);
      } catch (_) {
        final fallback = Map<String, dynamic>.from(updateData)..remove('jatuh_tempo');
        await _client.from('paket').update(fallback).eq('id', id);
      }
    } catch (_) {
      // Abaikan jika offline / local id
    }

    final updatedList = state.daftarPaket.map((p) {
      if (p.id == id) {
        return p.copyWith(
          namaPaket: namaPaket,
          nominal: nominal,
          jatuhTempo: jatuhTempo ?? p.jatuhTempo,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(isLoading: false, daftarPaket: updatedList);
    _saveCache(updatedList);

    // Sinkronkan nama kategori di data transaksi
    if (oldNama.isNotEmpty) {
      try {
        _ref.read(transaksiControllerProvider.notifier).syncUpdatedPaket(
              paketId: id,
              oldNama: oldNama,
              newNama: namaPaket,
              oldNominal: oldNominal,
              newNominal: nominal,
            );
      } catch (_) {}
    }

    return true;
  }

  Future<bool> hapusPaket(String id) async {
    state = state.copyWith(isLoading: true);

    String oldNama = '';
    try {
      final old = state.daftarPaket.firstWhere((p) => p.id == id);
      oldNama = old.namaPaket;
    } catch (_) {}

    try {
      await _client.from('paket').delete().eq('id', id);
    } catch (_) {
      // Abaikan jika local
    }

    final filtered = state.daftarPaket.where((p) => p.id != id).toList();
    state = state.copyWith(isLoading: false, daftarPaket: filtered);
    _saveCache(filtered);

    // Sinkronkan ke Transaksi jika filter kategori yang dihapus sedang terpilih
    if (oldNama.isNotEmpty) {
      try {
        _ref.read(transaksiControllerProvider.notifier).syncDeletedPaket(
              paketId: id,
              namaPaket: oldNama,
            );
      } catch (_) {}
    }

    return true;
  }
}

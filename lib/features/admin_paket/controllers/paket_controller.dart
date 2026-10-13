import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  Future<void> loadPaket() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client
          .from('paket')
          .select('id, nama_paket, nominal, created_at')
          .order('created_at', ascending: true);

      final list = (res as List)
          .map((item) => PaketModel.fromMap(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, daftarPaket: list);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> tambahPaket({
    required String namaPaket,
    required int nominal,
  }) async {
    state = state.copyWith(isLoading: true);

    final localNewPaket = PaketModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      namaPaket: namaPaket,
      nominal: nominal,
      badgeLetter: 'A',
      createdAt: DateTime.now(),
    );

    try {
      final res = await _client.from('paket').insert({
        'nama_paket': namaPaket,
        'nominal': nominal,
      }).select().maybeSingle();

      if (res != null) {
        final serverPaket = PaketModel.fromMap(res);
        state = state.copyWith(
          isLoading: false,
          daftarPaket: [...state.daftarPaket, serverPaket],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          daftarPaket: [...state.daftarPaket, localNewPaket],
        );
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('ERROR SUPABASE INSERT PAKET: $e');
      // Simpan di local state jika Supabase belum siap
      state = state.copyWith(
        isLoading: false,
        daftarPaket: [...state.daftarPaket, localNewPaket],
      );
      return true;
    }
  }

  Future<bool> updatePaket({
    required String id,
    required String namaPaket,
    required int nominal,
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
      await _client.from('paket').update({
        'nama_paket': namaPaket,
        'nominal': nominal,
      }).eq('id', id);
    } catch (_) {
      // Abaikan jika offline / local id
    }

    final updatedList = state.daftarPaket.map((p) {
      if (p.id == id) {
        return p.copyWith(namaPaket: namaPaket, nominal: nominal);
      }
      return p;
    }).toList();

    state = state.copyWith(isLoading: false, daftarPaket: updatedList);

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

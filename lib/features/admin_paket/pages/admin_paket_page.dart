import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/paket_controller.dart';
import '../models/paket_model.dart';
import '../widgets/tambah_paket_bottom_sheet.dart';

class AdminPaketPage extends ConsumerWidget {
  const AdminPaketPage({super.key});

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paketControllerProvider);
    final daftarPaket = state.daftarPaket;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Paket Bimbel',
          style: TextStyle(
            color: Color(0xFF6200EE),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6200EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        onPressed: () => TambahPaketBottomSheet.show(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6200EE),
          onRefresh: () => ref.read(paketControllerProvider.notifier).loadPaket(),
          child: daftarPaket.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'Belum ada data paket bimbel',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: daftarPaket.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final paket = daftarPaket[index];
                    return _buildPaketCard(context, paket);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPaketCard(BuildContext context, PaketModel paket) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [

          // Nama Paket & Chip Nominal Hijau
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paket.namaPaket,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F5E8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rp. ${_formatCurrency(paket.nominal)}',
                        style: const TextStyle(
                          color: Color(0xFF00A86B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Jatuh tempo: ${paket.jatuhTempoFormatted}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icon Edit Pensil Ungu
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: Color(0xFF6200EE),
              size: 22,
            ),
            onPressed: () => TambahPaketBottomSheet.show(context, existingPaket: paket),
          ),
        ],
      ),
    );
  }
}

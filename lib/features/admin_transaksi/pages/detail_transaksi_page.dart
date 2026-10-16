import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin_paket/controllers/paket_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../widgets/tambah_transaksi_bottom_sheet.dart';

class DetailTransaksiPage extends ConsumerWidget {
  final TransaksiModel? transaksi;

  const DetailTransaksiPage({
    super.key,
    this.transaksi,
  });

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
    final state = ref.watch(transaksiControllerProvider);
    final paketState = ref.watch(paketControllerProvider);

    final initialItem = transaksi ??
        (state.daftarTransaksi.isNotEmpty
            ? state.daftarTransaksi.first
            : const TransaksiModel(
                id: '',
                namaSiswa: 'Siswa Bimbel',
                nominal: 0,
                status: 'Belum Lunas',
                metode: 'Tunai (Cash)',
                tanggal: '-',
                kategori: 'Paket Bimbel',
              ));

    // Ambil data transaksi terkini dari state jika ada pembaruan
    final item = state.daftarTransaksi.firstWhere(
      (t) => t.id == initialItem.id,
      orElse: () => initialItem,
    );

    final isLunas = item.status.toLowerCase() == 'lunas';

    // Dapatkan nama paket terkini dari daftar paket aktif
    String namaPaket = TransaksiController.resolveKategori(item, paketState.daftarPaket);
    if (namaPaket == 'All' || namaPaket.isEmpty) {
      namaPaket = item.kategori?.trim() ?? 'Paket Bimbel';
    }

    // Ambil riwayat pembayaran siswa ini dari database / state
    final riwayatSiswa = state.daftarTransaksi
        .where((t) => t.namaSiswa.toLowerCase() == item.namaSiswa.toLowerCase())
        .toList();

    // Jika riwayat kosong, buat tampilan riwayat item saat ini
    final displayRiwayat = riwayatSiswa.isNotEmpty ? riwayatSiswa : [item];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF6200EE),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Detail Transaksi SPP',
          style: TextStyle(
            color: Color(0xFF6200EE),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Card Siswa & Total Tagihan Aktif
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaSiswa,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E2E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              namaPaket,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3A3A3C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'TOTAL TAGIHAN AKTIF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Rp.${_formatCurrency(item.nominal)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6200EE),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLunas ? 'LUNAS' : 'BELUM LUNAS',
                                  style: TextStyle(
                                    color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE53935),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Rincian Tagihan Bulan ini
                    const Text(
                      'Rincian Tagihan Bulan ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF6200EE),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'SPP Bulan ini',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        Text(
                          'Rp.${_formatCurrency(item.nominal)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp.${_formatCurrency(item.nominal)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6200EE),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // 3. Section Riwayat Pembayaran
                    const Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // List Riwayat Pembayaran Siswa
                    ...displayRiwayat.map((hist) {
                      final histLunas = hist.status.toLowerCase() == 'lunas';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      hist.namaSiswa,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1C1E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: histLunas
                                          ? const Color(0xFFD6F5E8)
                                          : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hist.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: histLunas
                                            ? const Color(0xFF00A86B)
                                            : const Color(0xFFE53935),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${_formatCurrency(hist.nominal)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hist.tanggal,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 4. Tombol Fixed Bawah: "Kelola Tagihan"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    TambahTransaksiBottomSheet.show(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kelola Tagihan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

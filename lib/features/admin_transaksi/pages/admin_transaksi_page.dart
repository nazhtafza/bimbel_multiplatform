import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin_paket/controllers/paket_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../widgets/tambah_transaksi_bottom_sheet.dart';

class AdminTransaksiPage extends ConsumerStatefulWidget {
  const AdminTransaksiPage({super.key});

  @override
  ConsumerState<AdminTransaksiPage> createState() => _AdminTransaksiPageState();
}

class _AdminTransaksiPageState extends ConsumerState<AdminTransaksiPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final state = ref.watch(transaksiControllerProvider);
    final controller = ref.read(transaksiControllerProvider.notifier);
    final paketState = ref.watch(paketControllerProvider);
    final daftarPaket = paketState.daftarPaket;
    final items = controller.getFilteredTransaksi(daftarPaket);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Transaksi SPP',
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
        onPressed: () => TambahTransaksiBottomSheet.show(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6200EE),
          onRefresh: () => controller.loadData(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar: "Cari Transaksi"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F2FD),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF6200EE), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => controller.updateSearch(val.trim()),
                          style: const TextStyle(
                            color: Color(0xFF6200EE),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari Transaksi',
                            hintStyle: TextStyle(
                              color: Color(0xFF6200EE),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6200EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Filter Chips Dinamis dari Daftar Paket Bimbel (Kategori Transaksi)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', state.selectedFilter, controller),
                    ...daftarPaket.map((pkt) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _buildFilterChip(pkt.namaPaket, state.selectedFilter, controller),
                      );
                    }),
                  ],
                ),
              ),

              // 3. List Data Transaksi atau Tampilan Kosong
              Expanded(
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Color(0xFFC4C4C4),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Belum ada transaksi pembayaran',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tekan tombol + di bawah untuk mencatat transaksi baru',
                                  style: TextStyle(
                                    color: Color(0xFFAAAAAA),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Hari ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                          ...items.map((item) => _buildTransaksiCard(context, item)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentFilter,
    TransaksiController controller,
  ) {
    final isSelected = label.toLowerCase() == currentFilter.toLowerCase();
    return InkWell(
      onTap: () => controller.updateFilter(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6200EE) : const Color(0xFFF4F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6200EE),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(BuildContext context, TransaksiModel item) {
    final isLunas = item.status.toLowerCase() == 'lunas';
    final isJatuhTempo = item.status.toLowerCase() == 'jatuh tempo';

    final Color badgeBg = isLunas
        ? const Color(0xFFD6F5E8)
        : (isJatuhTempo ? const Color(0xFFFFE8D6) : const Color(0xFFFFEBEE));

    final Color badgeText = isLunas
        ? const Color(0xFF00A86B)
        : (isJatuhTempo ? const Color(0xFFE67E22) : const Color(0xFFE53935));

    return InkWell(
      onTap: () {
        context.push('/admin/transaksi/detail', extra: item);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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

          // Nama Siswa & Badge Status
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.namaSiswa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nominal & Tanggal di Kanan
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${_formatCurrency(item.nominal)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.tanggal,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
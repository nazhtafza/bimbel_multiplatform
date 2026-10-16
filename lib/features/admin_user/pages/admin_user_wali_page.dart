import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin_transaksi/controllers/transaksi_controller.dart';
import '../../admin_transaksi/models/transaksi_model.dart';
import '../controllers/user_wali_controller.dart';
import '../models/user_wali_model.dart';

class AdminUserWaliPage extends ConsumerStatefulWidget {
  const AdminUserWaliPage({super.key});

  @override
  ConsumerState<AdminUserWaliPage> createState() => _AdminUserWaliPageState();
}

class _AdminUserWaliPageState extends ConsumerState<AdminUserWaliPage> {
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

  void _onWaliTap(BuildContext context, UserWaliModel wali) {
    final transState = ref.read(transaksiControllerProvider);

    // Cari transaksi yang cocok berdasarkan nama siswa
    TransaksiModel? targetTrans;
    try {
      targetTrans = transState.daftarTransaksi.firstWhere(
        (t) => t.namaSiswa.trim().toLowerCase() == wali.namaSiswa.trim().toLowerCase(),
      );
    } catch (_) {
      targetTrans = null;
    }

    // Jika belum ada di list transaksi, buat model representasi siswa/wali tersebut
    targetTrans ??= TransaksiModel(
      id: 'wali-trans-${wali.id}',
      namaSiswa: wali.namaSiswa,
      nominal: wali.totalTagihan,
      status: wali.statusSpp,
      metode: 'Tunai (Cash)',
      tanggal: '-',
      kategori: 'Paket Bimbel',
      catatan: 'Wali: ${wali.nama} (${wali.email})',
    );

    // Navigasi ke Detail Transaksi SPP
    context.push('/admin/transaksi/detail', extra: targetTrans);
  }

  @override
  Widget build(BuildContext context) {
    final waliState = ref.watch(userWaliControllerProvider);
    final controller = ref.read(userWaliControllerProvider.notifier);
    final items = waliState.filteredWali;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6200EE),
          onRefresh: () async {
            await controller.loadUserWali();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Data User Wali',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Wali murid yang telah login ke aplikasi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Metric / Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Login',
                        value: '${waliState.totalWaliLogin}',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF6200EE),
                        bgColor: const Color(0xFFEDE7F6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'SPP Lunas',
                        value: '${waliState.totalLunas}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF00A86B),
                        bgColor: const Color(0xFFE0F7EF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Belum Lunas',
                        value: '${waliState.totalBelumLunas}',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFE65100),
                        bgColor: const Color(0xFFFFF3E0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => controller.updateSearch(val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama wali, siswa, atau email...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6200EE), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                controller.updateSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('Semua', waliState.filterStatus, controller),
                    const SizedBox(width: 8),
                    _buildFilterChip('Lunas', waliState.filterStatus, controller),
                    const SizedBox(width: 8),
                    _buildFilterChip('Belum Lunas', waliState.filterStatus, controller),
                    const SizedBox(width: 8),
                    _buildFilterChip('Baru Login', waliState.filterStatus, controller),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. List of User Wali Cards
              Expanded(
                child: waliState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6200EE)),
                      )
                    : items.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDE7F6),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF6200EE).withValues(alpha: 0.12),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.group_outlined,
                                              size: 42,
                                              color: Color(0xFF6200EE),
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          const Text(
                                            'Belum Ada User Wali Login',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1C1C1E),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Data akun wali murid yang telah login ke dalam aplikasi akan otomatis muncul di sini.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF8E8E93),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF6200EE),
                                              side: const BorderSide(color: Color(0xFF6200EE)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            ),
                                            onPressed: () => controller.loadUserWali(),
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            label: const Text(
                                              'Muat Ulang',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildWaliCard(context, item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentFilter,
    UserWaliController controller,
  ) {
    final isSelected = label.toLowerCase() == currentFilter.toLowerCase();
    return InkWell(
      onTap: () => controller.updateFilter(label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6200EE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6200EE) : const Color(0xFFE5E5EA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWaliCard(BuildContext context, UserWaliModel item) {
    final isLunas = item.statusSpp.toLowerCase() == 'lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onWaliTap(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Wali Name + Status SPP Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: item.avatarColor.withValues(alpha: 0.15),
                      child: Text(
                        item.nama.isNotEmpty ? item.nama[0].toUpperCase() : 'W',
                        style: TextStyle(
                          color: item.avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.nama,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Wali',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF6200EE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLunas ? 'LUNAS' : 'BELUM LUNAS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F0F3)),
                const SizedBox(height: 10),

                // Middle Info: Siswa & Waktu Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, size: 15, color: Color(0xFF6200EE)),
                        const SizedBox(width: 6),
                        Text(
                          'Siswa: ${item.namaSiswa}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2E),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 14, color: Color(0xFF8E8E93)),
                        const SizedBox(width: 4),
                        Text(
                          'Login: ${item.lastLoginFormatted}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom CTA: Action to detail transaksi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9FD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEDE7F6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: Color(0xFF6200EE),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tagihan: Rp.${_formatCurrency(item.totalTagihan)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text(
                            'Detail Transaksi SPP',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6200EE),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF6200EE),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

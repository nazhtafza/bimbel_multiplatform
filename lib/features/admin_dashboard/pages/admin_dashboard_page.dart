import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final summary = state.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6200EE),
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Logo + Judul + Icon Profil/Pengaturan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo_bimbel.png',
                          width: 34,
                          height: 34,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: Color(0xFF6200EE), size: 34),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Bimbel Bunda',
                          style: TextStyle(
                            color: Color(0xFF6200EE),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildCircleIconButton(
                          icon: Icons.settings,
                          onTap: () {
                            context.go('/admin/paket');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCircleIconButton(
                          icon: Icons.person,
                          onTap: _showLogoutDialog,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Search Bar: "Cari siswa"
                Container(
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
                          onChanged: (val) {
                            ref.read(dashboardControllerProvider.notifier).updateSearch(val.trim());
                          },
                          style: const TextStyle(
                            color: Color(0xFF6200EE),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari siswa',
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
                const SizedBox(height: 18),

                // 3. Grid Statistik (2 Kolom x 2 Baris)
                Row(
                  children: [
                    // Card 1: Total Siswa (Ungu Aktif)
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Siswa',
                        value: summary.totalSiswaDisplay,
                        icon: Icons.people_rounded,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2: Total Siswa Lunas (Putih)
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Siswa Lunas',
                        value: summary.totalLunasDisplay,
                        icon: Icons.verified_rounded,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Card 3: Total Belum Bayar (Putih)
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Belum Bayar',
                        value: summary.totalBelumBayarDisplay,
                        icon: Icons.account_balance_wallet_rounded,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 4: Total Jatuh Tempo (Putih)
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Jatuh Tempo',
                        value: summary.totalJatuhTempoDisplay,
                        icon: Icons.access_time_filled_rounded,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Section: Riwayat Pembayaran + "Lihat semua"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        color: Color(0xFF6200EE),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/admin/transaksi'),
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: Color(0xFF6200EE),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Konten Riwayat (Belum ada data riwayat / List Transaksi)
                if (state.riwayat.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    alignment: Alignment.center,
                    child: const Text(
                      'Belum ada data riwayat',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.riwayat.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.riwayat[index];
                      final isLunas = item.status.toLowerCase() == 'lunas';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isLunas
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              child: Icon(
                                isLunas ? Icons.check : Icons.access_time,
                                color: isLunas ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.namaSiswa,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.tanggal.isNotEmpty ? item.tanggal : 'Tanggal -',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${_formatCurrency(item.nominal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF6200EE),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isLunas ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tombol bulat abu-abu kecil di header kanan (Pengaturan & Profil)
  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF4A4A4A), size: 19),
      ),
    );
  }

  // Card Ringkasan Statistik
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF6200EE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
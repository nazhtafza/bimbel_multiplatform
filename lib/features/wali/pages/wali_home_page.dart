import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../admin_transaksi/models/transaksi_model.dart';
import '../../auth/auth_controller.dart';
import '../controllers/wali_home_controller.dart';
import '../widgets/bukti_pembayaran_dialog.dart';
import '../widgets/proses_pembayaran_bottom_sheet.dart';

class WaliHomePage extends ConsumerStatefulWidget {
  const WaliHomePage({super.key});

  @override
  ConsumerState<WaliHomePage> createState() => _WaliHomePageState();
}

class _WaliHomePageState extends ConsumerState<WaliHomePage> {
  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
  }

  Future<void> _saveCurrentRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', '/wali');
    } catch (_) {}
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun wali murid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
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

  void _showNotifikasiDialog(WaliHomeState state) {
    if (state.isEmptyState) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF6200EE),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pengingat Jatuh Tempo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Saat ini tidak ada notifikasi pengingat jatuh tempo aktif. Akun Anda belum memiliki tagihan berjalan.',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFF6200EE))),
            ),
          ],
        ),
      );
      return;
    }

    final sisa = state.sisaHariJatuhTempo;
    final isLunas = state.statusTagihan.toLowerCase() == 'lunas';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6200EE).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF6200EE),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Pengingat Jatuh Tempo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLunas) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00A86B), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tagihan SPP bulan ini sudah Lunas. Terima kasih atas pembayaran tepat waktu!',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sisa <= 1 ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sisa <= 1 ? const Color(0xFFFFCDD2) : const Color(0xFFFFE082),
                  ),
                ),
                child: Text(
                  state.notifikasiJatuhTempo ??
                      'Batas akhir pembayaran SPP adalah tanggal ${state.jatuhTempoFormatted}.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sisa <= 1 ? const Color(0xFFC62828) : const Color(0xFFE65100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Jadwal Notifikasi Otomatis:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              ),
              const SizedBox(height: 8),
              _buildReminderRow('H-7', 'Pengingat awal seminggu sebelum batas tempo', sisa <= 7 && !isLunas),
              const SizedBox(height: 6),
              _buildReminderRow('H-3', 'Peringatan 3 hari menjelang jatuh tempo', sisa <= 3 && !isLunas),
              const SizedBox(height: 6),
              _buildReminderRow('H-1', 'Pemberitahuan darurat 1 hari sebelum jatuh tempo', sisa <= 1 && !isLunas),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          if (!isLunas)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ProsesPembayaranBottomSheet.show(context);
              },
              child: const Text('Bayar Sekarang', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderRow(String code, String desc, bool isActive) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6200EE) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : const Color(0xFF757575),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isActive)
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00A86B), size: 16),
      ],
    );
  }

  Widget _buildNotifikasiBanner(BuildContext context, WaliHomeState state) {
    final sisa = state.sisaHariJatuhTempo;
    final isUrgent = sisa <= 1;
    final isMedium = sisa <= 3;

    final bgColor = isUrgent
        ? const Color(0xFFFFF1F0)
        : isMedium
            ? const Color(0xFFFFF7E6)
            : const Color(0xFFFEFFE6);
    final borderColor = isUrgent
        ? const Color(0xFFFFA39E)
        : isMedium
            ? const Color(0xFFFFD591)
            : const Color(0xFFFFF566);
    final textColor = isUrgent
        ? const Color(0xFFCF1322)
        : isMedium
            ? const Color(0xFFD46B08)
            : const Color(0xFF856404);
    final icon = isUrgent
        ? Icons.error_outline_rounded
        : isMedium
            ? Icons.alarm_rounded
            : Icons.info_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.badgeNotifikasi != null
                          ? 'PENGINGAT ${state.badgeNotifikasi}'
                          : 'PENGINGAT SPP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Batas: ${state.jatuhTempoFormatted}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.notifikasiJatuhTempo ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waliState = ref.watch(waliHomeControllerProvider);
    final controller = ref.read(waliHomeControllerProvider.notifier);
    final isLunas = waliState.statusTagihan.toLowerCase() == 'lunas';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6200EE),
          onRefresh: () async {
            await controller.loadData();
          },
          child: waliState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6200EE)),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Top App Bar / Greeting
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF6200EE).withValues(alpha: 0.15),
                                  child: Text(
                                    waliState.namaWali.isNotEmpty
                                        ? waliState.namaWali[0].toUpperCase()
                                        : 'W',
                                    style: const TextStyle(
                                      color: Color(0xFF6200EE),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, ${waliState.namaWali.isNotEmpty ? waliState.namaWali : "Wali Murid"}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1C1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Wali Murid • Bimbel Bunda',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Notification Bell with Animated Badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showNotifikasiDialog(waliState),
                                      icon: Icon(
                                        waliState.badgeNotifikasi != null
                                            ? Icons.notifications_active_rounded
                                            : Icons.notifications_none_rounded,
                                        color: waliState.badgeNotifikasi != null
                                            ? (waliState.badgeNotifikasi == 'H-1' || waliState.badgeNotifikasi == 'LEWAT'
                                                ? const Color(0xFFE53935)
                                                : const Color(0xFFF57C00))
                                            : const Color(0xFF8E8E93),
                                        size: 24,
                                      ),
                                      tooltip: 'Notifikasi Jatuh Tempo',
                                    ),
                                    if (waliState.badgeNotifikasi != null)
                                      Positioned(
                                        right: 4,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: waliState.badgeNotifikasi == 'H-1' || waliState.badgeNotifikasi == 'LEWAT'
                                                ? const Color(0xFFE53935)
                                                : const Color(0xFFF57C00),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            waliState.badgeNotifikasi!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: _showLogoutDialog,
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFF8E8E93),
                                    size: 22,
                                  ),
                                  tooltip: 'Keluar Akun',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Notifikasi Banner Jatuh Tempo H-7, H-3, H-1
                    if (waliState.notifikasiJatuhTempo != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _buildNotifikasiBanner(context, waliState),
                        ),
                      ),

                    if (waliState.isEmptyState)
                      _buildEmptyStateView(context, controller)
                    else ...[
                      // 2. Hero Card: Tagihan SPP Aktif
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                if (isLunas && waliState.daftarRiwayat.isNotEmpty) {
                                  BuktiPembayaranDialog.show(context, waliState.daftarRiwayat.first);
                                } else {
                                  ProsesPembayaranBottomSheet.show(context);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5A189A), Color(0xFF7B2CBF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A189A).withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(22.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.school_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                waliState.namaSiswa,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLunas
                                                  ? const Color(0xFF00A86B)
                                                  : const Color(0xFFE65100),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isLunas ? 'LUNAS' : 'BELUM BAYAR',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            waliState.paketBimbel,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.calendar_month_rounded,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Jatuh tempo: ${waliState.jatuhTempoFormatted}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'TOTAL TAGIHAN BULAN INI',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.16),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Sesuai Tarif: ${waliState.paketBimbel}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${_formatCurrency(waliState.nominalTagihan)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!isLunas) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          waliState.sisaHariJatuhTempo >= 0
                                              ? '⏳ Sisa waktu: ${waliState.sisaHariJatuhTempo} hari lagi'
                                              : '⚠️ Telah lewat batas waktu jatuh tempo',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),

                                      // Tombol Aksi: Bayar Sekarang / Sudah Lunas
                                      SizedBox(
                                        width: double.infinity,
                                        height: 46,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isLunas ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                                            foregroundColor: isLunas ? Colors.white : const Color(0xFF5A189A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            if (isLunas && waliState.daftarRiwayat.isNotEmpty) {
                                              BuktiPembayaranDialog.show(
                                                context,
                                                waliState.daftarRiwayat.first,
                                              );
                                            } else {
                                              ProsesPembayaranBottomSheet.show(context);
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isLunas
                                                    ? Icons.receipt_long_rounded
                                                    : Icons.payment_rounded,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isLunas
                                                    ? 'Lihat Bukti Pembayaran'
                                                    : 'Bayar Sekarang',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 3. Info Metode Pembayaran
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetodeInfo(Icons.account_balance_rounded, 'Transfer Bank'),
                              Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                              _buildMetodeInfo(Icons.qr_code_scanner_rounded, 'QRIS Instant'),
                              Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                              _buildMetodeInfo(Icons.receipt_rounded, 'Kuitansi Digital'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Section Title: Riwayat Pembayaran
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Riwayat Pembayaran',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${waliState.daftarRiwayat.length} Transaksi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6200EE),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. Daftar Riwayat Pembayaran
                    if (waliState.daftarRiwayat.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Color(0xFFCCCCCC),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Belum Ada Riwayat Pembayaran',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Transaksi yang telah diselesaikan akan tercatat di sini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = waliState.daftarRiwayat[index];
                              return _buildRiwayatCard(context, item);
                            },
                            childCount: waliState.daftarRiwayat.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, WaliHomeController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Empty State Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6200EE).withValues(alpha: 0.12),
                          const Color(0xFF7B2CBF).withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 46,
                      color: Color(0xFF6200EE),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum Ada Tagihan & Transaksi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Akun Anda saat ini belum memiliki tagihan SPP aktif atau riwayat pembayaran yang tercatat.\n\nData tagihan siswa dan paket bimbingan belajar akan otomatis muncul setelah didaftarkan oleh admin Bimbel Bunda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => controller.loadData(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Perbarui Halaman',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Bantuan & Layanan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF6200EE),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butuh Bantuan Administrasi?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Silakan hubungi pihak administrasi Bimbel Bunda untuk pendaftaran nama siswa dan pemilihan paket bimbingan belajar.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodeInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6200EE), size: 17),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatCard(BuildContext context, TransaksiModel item) {
    final isLunas = item.status.toLowerCase() == 'lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Tampilkan popup bukti pembayaran
            BuktiPembayaranDialog.show(context, item);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.metode.toLowerCase().contains('transfer') ||
                            item.metode.toLowerCase().contains('bca') ||
                            item.metode.toLowerCase().contains('bri')
                        ? Icons.account_balance_rounded
                        : Icons.payments_rounded,
                    color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE65100),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kategori ?? 'SPP Bimbel Bulanan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.tanggal} • ${item.metode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatCurrency(item.nominal)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLunas ? 'LUNAS' : 'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

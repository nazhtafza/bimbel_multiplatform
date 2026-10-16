import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin_transaksi/models/transaksi_model.dart';
import '../controllers/wali_home_controller.dart';
import 'bukti_pembayaran_dialog.dart';

class ProsesPembayaranBottomSheet extends ConsumerStatefulWidget {
  const ProsesPembayaranBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProsesPembayaranBottomSheet(),
    );
  }

  @override
  ConsumerState<ProsesPembayaranBottomSheet> createState() =>
      _ProsesPembayaranBottomSheetState();
}

class _ProsesPembayaranBottomSheetState
    extends ConsumerState<ProsesPembayaranBottomSheet> {
  // Kategori Utama: 'Transfer', 'QRIS', 'Cash'
  String _selectedCategory = 'Transfer';
  String _selectedBank = 'BCA';
  final _catatanController = TextEditingController();

  final List<Map<String, String>> _bankList = [
    {
      'id': 'BCA',
      'name': 'Bank BCA',
      'norek': '8271-9921-0021',
      'an': 'Bimbel Bunda Official',
    },
    {
      'id': 'Mandiri',
      'name': 'Bank Mandiri',
      'norek': '132-00-1928374-1',
      'an': 'Bimbel Bunda Official',
    },
    {
      'id': 'BRI',
      'name': 'Bank BRI',
      'norek': '0123-0100-2938-501',
      'an': 'Bimbel Bunda Official',
    },
  ];

  @override
  void dispose() {
    _catatanController.dispose();
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF6200EE),
      ),
    );
  }

  Future<void> _handleBayar() async {
    final state = ref.read(waliHomeControllerProvider);
    final controller = ref.read(waliHomeControllerProvider.notifier);

    String metodeName;
    if (_selectedCategory == 'Transfer') {
      final bank = _bankList.firstWhere(
        (b) => b['id'] == _selectedBank,
        orElse: () => _bankList[0],
      );
      metodeName = 'Transfer (${bank['name']})';
    } else if (_selectedCategory == 'QRIS') {
      metodeName = 'QRIS Instant';
    } else {
      metodeName = 'Tunai (Cash)';
    }

    final success = await controller.prosesPembayaran(
      nominal: state.nominalTagihan,
      metode: metodeName,
      namaPaket: state.paketBimbel,
      catatan: _catatanController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context); // Tutup bottom sheet

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran via $metodeName berhasil diproses!'),
            backgroundColor: const Color(0xFF00A86B),
          ),
        );

        // Tampilkan Bukti Pembayaran
        final newTrans = TransaksiModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          namaSiswa: state.namaSiswa,
          nominal: state.nominalTagihan,
          status: 'Lunas',
          metode: metodeName,
          tanggal: 'Hari ini',
          kategori: state.paketBimbel,
          catatan: 'Pembayaran oleh Wali: ${state.namaWali}',
        );

        BuktiPembayaranDialog.show(context, newTrans);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waliHomeControllerProvider);
    final isSubmitting = state.isSubmitting;

    final currentBank = _bankList.firstWhere(
      (b) => b['id'] == _selectedBank,
      orElse: () => _bankList[0],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilihan Pembayaran SPP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pilih metode: Transfer, QRIS, atau Cash',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Card Rincian Tagihan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.namaSiswa,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.paketBimbel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6200EE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF8E8E93)),
                            SizedBox(width: 5),
                            Text(
                              'Batas Jatuh Tempo',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state.jatuhTempoFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE5E5EA)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total yang Harus Dibayar',
                              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sesuai Tarif: ${state.paketBimbel}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6200EE),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${_formatCurrency(state.nominalTagihan)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6200EE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Pilihan 3 Kategori Metode Pembayaran: Transfer, QRIS, Cash
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Opsi 1: Transfer Bank
                  Expanded(
                    child: _buildCategoryOption(
                      category: 'Transfer',
                      icon: Icons.account_balance_rounded,
                      title: 'Transfer',
                      subtitle: 'Bank BCA / Lain',
                      isSelected: _selectedCategory == 'Transfer',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Opsi 2: QRIS
                  Expanded(
                    child: _buildCategoryOption(
                      category: 'QRIS',
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'QRIS',
                      subtitle: 'Scan Instant',
                      isSelected: _selectedCategory == 'QRIS',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Opsi 3: Cash (Tunai)
                  Expanded(
                    child: _buildCategoryOption(
                      category: 'Cash',
                      icon: Icons.payments_rounded,
                      title: 'Cash',
                      subtitle: 'Bayar di Kasir',
                      isSelected: _selectedCategory == 'Cash',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail Area Sesuai Kategori yang Dipilih
              if (_selectedCategory == 'Transfer') ...[
                // Sub-pilihan Bank
                Row(
                  children: _bankList.map((bank) {
                    final isBankSelected = _selectedBank == bank['id'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedBank = bank['id']!),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isBankSelected ? const Color(0xFF6200EE) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                bank['id']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isBankSelected ? Colors.white : const Color(0xFF1C1C1E),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Detail Rekening Transfer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE7F6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentBank['name']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(currentBank['norek']!, 'Nomor Rekening'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 13, color: Color(0xFF6200EE)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Salin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6200EE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentBank['norek']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Color(0xFF6200EE),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'a.n ${currentBank['an']!}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedCategory == 'QRIS') ...[
                // Detail Card QRIS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE7F6)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 110,
                              color: Color(0xFF1C1C1E),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'QRIS • Standar Pembayaran Nasional',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6200EE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NMID: ID10200382910',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mendukung: GoPay, OVO, DANA, ShopeePay, BCA Mobile, Livin, BRImo & Semua E-Wallet',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Detail Card Pembayaran Cash (Tunai)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront_rounded, color: Color(0xFF2E7D32), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Loket Kasir Bimbel Bunda',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan datang langsung ke loket kasir Bimbel Bunda di Lantai 1 dengan menyebutkan nama siswa dan membawa uang tunai pas.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32), height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Text(
                              'Jam Kasir: Senin - Sabtu (08.00 - 17.00 WIB)',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 3. Catatan Pembayaran
              const Text(
                'Catatan Tambahan (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _catatanController,
                decoration: InputDecoration(
                  hintText: 'Misal: Pembayaran SPP Bulan Ini...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: const Color(0xFFF7F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Tombol Submit Pembayaran
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSubmitting ? null : _handleBayar,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategory == 'Transfer'
                                  ? 'Bayar via Transfer Bank'
                                  : (_selectedCategory == 'QRIS'
                                      ? 'Bayar via QRIS Instant'
                                      : 'Konfirmasi Bayar Tunai di Kasir'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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
    );
  }

  Widget _buildCategoryOption({
    required String category,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE7F6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6200EE) : const Color(0xFFE5E5EA),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6200EE).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6200EE) : const Color(0xFF8E8E93),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF6200EE) : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF6200EE) : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

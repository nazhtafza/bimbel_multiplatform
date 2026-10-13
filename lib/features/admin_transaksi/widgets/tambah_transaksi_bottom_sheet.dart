import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin_paket/controllers/paket_controller.dart';
import '../../admin_paket/models/paket_model.dart';
import '../controllers/transaksi_controller.dart';

class TambahTransaksiBottomSheet extends ConsumerStatefulWidget {
  const TambahTransaksiBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TambahTransaksiBottomSheet(),
    );
  }

  @override
  ConsumerState<TambahTransaksiBottomSheet> createState() => _TambahTransaksiBottomSheetState();
}

class _TambahTransaksiBottomSheetState extends ConsumerState<TambahTransaksiBottomSheet> {
  String? _selectedSiswaId;
  String _namaSiswa = '';
  PaketModel? _selectedPaket;

  final _namaManualController = TextEditingController();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();

  String _metodePembayaran = 'Tunai (Cash)';
  DateTime _tanggalPembayaran = DateTime.now();
  bool _isSubmitting = false;
  bool _isManualInput = false;

  @override
  void dispose() {
    _namaManualController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String _formatNumber(String s) {
    final clean = s.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
    if (clean.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  int _parseNominal(String text) {
    final clean = text.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
    return int.tryParse(clean) ?? 0;
  }

  String _formatDateDisplay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateInput(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m/$d/${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPembayaran,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6200EE),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _tanggalPembayaran = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final nama = _isManualInput ? _namaManualController.text.trim() : _namaSiswa.trim();
    final nominal = _parseNominal(_nominalController.text);

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau masukkan nama siswa'), backgroundColor: Colors.red),
      );
      return;
    }

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pembayaran harus lebih dari 0'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String statusFinal = 'Lunas';
    String catatanFinal = _catatanController.text.trim();
    String? kategori = _selectedPaket?.namaPaket;

    if (_selectedPaket != null) {
      final harga = _selectedPaket!.nominal;
      if (nominal < harga) {
        statusFinal = 'Belum Bayar';
        final kurang = harga - nominal;
        final noteKurang = 'Uang kurang Rp ${_formatNumber(kurang.toString())} (Paket: ${_selectedPaket!.namaPaket})';
        catatanFinal = catatanFinal.isEmpty ? noteKurang : '$catatanFinal - $noteKurang';
      } else if (nominal > harga) {
        final kembalian = nominal - harga;
        final noteKembalian = 'Kembalian Rp ${_formatNumber(kembalian.toString())} (Paket: ${_selectedPaket!.namaPaket})';
        catatanFinal = catatanFinal.isEmpty ? noteKembalian : '$catatanFinal - $noteKembalian';
      } else {
        final notePas = 'Paket: ${_selectedPaket!.namaPaket}';
        catatanFinal = catatanFinal.isEmpty ? notePas : '$catatanFinal - $notePas';
      }
    }

    await ref.read(transaksiControllerProvider.notifier).tambahTransaksi(
          namaSiswa: nama,
          siswaId: _selectedSiswaId,
          paketId: _selectedPaket?.id,
          nominal: nominal,
          metode: _metodePembayaran,
          tanggal: _formatDateDisplay(_tanggalPembayaran),
          catatan: catatanFinal,
          status: statusFinal,
          kategori: kategori,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi pembayaran berhasil dicatat!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transaksiControllerProvider);
    final daftarSiswa = state.daftarSiswa;
    final paketState = ref.watch(paketControllerProvider);
    final daftarPaket = paketState.daftarPaket;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle abu-abu
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC4C4C4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul Bottom Sheet
            const Text(
              'Catatan Transaksi Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 20),

            // Field 1: Pilih Siswa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Siswa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isManualInput = !_isManualInput;
                    });
                  },
                  child: Text(
                    _isManualInput ? 'Pilih dari daftar' : '+ Ketik nama manual',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6200EE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!_isManualInput && daftarSiswa.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSiswaId,
                    hint: const Text(
                      'Pilih siswa dari daftar',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A4A4A)),
                    items: daftarSiswa.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(
                          item['nama'] ?? '',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSiswaId = val;
                        final found = daftarSiswa.firstWhere((s) => s['id'] == val, orElse: () => {});
                        _namaSiswa = found['nama'] ?? '';
                      });
                    },
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _namaManualController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                  decoration: const InputDecoration(
                    hintText: 'Pilih siswa dari daftar atau ketik nama',
                    hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // Field 2: Dropdown Pilih Paket Bimbel (dari Paket)
            const Text(
              'Pilih Paket Bimbel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PaketModel>(
                  isExpanded: true,
                  value: _selectedPaket,
                  hint: const Text(
                    'Pilih paket bimbel',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A4A4A)),
                  items: daftarPaket.map((paket) {
                    return DropdownMenuItem<PaketModel>(
                      value: paket,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            paket.namaPaket,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                          ),
                          Text(
                            'Rp ${_formatNumber(paket.nominal.toString())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6200EE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPaket = val;
                      if (val != null) {
                        _nominalController.text = _formatNumber(val.nominal.toString());
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 3: Nominal Pembayaran
            const Text(
              'Nominal Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'Rp ',
                    style: TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final formatted = _formatNumber(val);
                        if (formatted != val) {
                          _nominalController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                        setState(() {}); // Update note kembalian / kurang secara realtime
                      },
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                      decoration: const InputDecoration(
                        hintText: '35.000',
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Note Dinamis: Kurang Bayar / Kembalian / Pas
            if (_selectedPaket != null && _nominalController.text.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final uangDibayar = _parseNominal(_nominalController.text);
                  final hargaPaket = _selectedPaket!.nominal;

                  if (uangDibayar < hargaPaket) {
                    final kurang = hargaPaket - uangDibayar;
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Uang yang dibayarkan kurang: Rp ${_formatNumber(kurang.toString())}',
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (uangDibayar > hargaPaket) {
                    final kembalian = uangDibayar - hargaPaket;
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00A86B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kembalian: Rp ${_formatNumber(kembalian.toString())}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00A86B), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Pembayaran Pas (Lunas)',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 18),

            // Field 4: Metode Pembayaran
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _metodePembayaran,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A4A4A)),
                  items: const [
                    DropdownMenuItem(value: 'Tunai (Cash)', child: Text('Tunai (Cash)')),
                    DropdownMenuItem(value: 'Transfer Bank', child: Text('Transfer Bank')),
                    DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _metodePembayaran = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 5: Tanggal Pembayaran
            const Text(
              'Tanggal Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDateInput(_tanggalPembayaran),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF555555), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 6: Catatan Pembayaran
            const Text(
              'Catatan Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                controller: _catatanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan apabila diperlukan',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Verifikasi Pembayaran
            SizedBox(
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
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Verifikasi Pembayaran',
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
          ],
        ),
      ),
    );
  }
}

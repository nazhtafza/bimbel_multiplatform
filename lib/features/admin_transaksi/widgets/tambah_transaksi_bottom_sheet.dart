import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin_paket/controllers/paket_controller.dart';
import '../../admin_paket/models/paket_model.dart';
import '../../wali/controllers/wali_home_controller.dart';
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
  String _selectedWaliEmail = '';
  PaketModel? _selectedPaket;

  final _namaManualController = TextEditingController();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();

  String _metodePembayaran = 'Tunai (Cash)';
  String _statusPembayaran = 'Belum Bayar';
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

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau masukkan nama siswa / wali murid'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_statusPembayaran == 'Belum Bayar' && _selectedPaket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih paket bimbel terlebih dahulu agar tagihan wali sesuai tarif paket!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int nominal = _statusPembayaran == 'Belum Bayar'
        ? (_selectedPaket?.nominal ?? 0)
        : _parseNominal(_nominalController.text);

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pembayaran harus lebih dari 0. Pilih paket bimbel terlebih dahulu.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String statusFinal = _statusPembayaran;
    String catatanFinal = _catatanController.text.trim();
    String? kategori = _selectedPaket?.namaPaket;

    if (_selectedPaket != null && statusFinal == 'Lunas') {
      final harga = _selectedPaket!.nominal;
      if (nominal < harga) {
        statusFinal = 'Belum Bayar';
        final kurang = harga - nominal;
        final noteKurang = 'Kurang Rp ${_formatNumber(kurang.toString())} (Paket: ${_selectedPaket!.namaPaket})';
        catatanFinal = catatanFinal.isEmpty ? noteKurang : '$catatanFinal - $noteKurang';
      } else if (nominal > harga) {
        final kembalian = nominal - harga;
        final noteKembalian = 'Kembalian Rp ${_formatNumber(kembalian.toString())} (Paket: ${_selectedPaket!.namaPaket})';
        catatanFinal = catatanFinal.isEmpty ? noteKembalian : '$catatanFinal - $noteKembalian';
      }
    }

    // Sertakan identitas Wali dalam catatan untuk sinkronisasi otomatis ke portal wali
    final waliNote = _selectedWaliEmail.isNotEmpty
        ? 'Wali: $nama ($_selectedWaliEmail)'
        : 'Wali: $nama';
    catatanFinal = catatanFinal.isEmpty ? waliNote : '$catatanFinal ($waliNote)';

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

    // Refresh data wali agar langsung sinkron di portal wali murid
    try {
      ref.read(waliHomeControllerProvider.notifier).loadData();
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusFinal == 'Lunas'
              ? 'Transaksi pembayaran lunas berhasil dicatat!'
              : 'Tagihan SPP berhasil dibuat untuk $nama!'),
          backgroundColor: const Color(0xFF00A86B),
        ),
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

            // Field 1: Pilih Siswa / Wali Murid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Siswa / Wali Murid',
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
                      'Pilih siswa / wali murid dari daftar',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13.5),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A4A4A)),
                    items: daftarSiswa.map((item) {
                      final nama = item['nama'] ?? '';
                      final email = item['email'] ?? '';
                      return DropdownMenuItem<String>(
                        value: item['id'],
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, color: Color(0xFF6200EE), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email.isNotEmpty ? '$nama • Wali ($email)' : '$nama • Wali',
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSiswaId = val;
                        final found = daftarSiswa.firstWhere((s) => s['id'] == val, orElse: () => {});
                        _namaSiswa = found['nama'] ?? '';
                        _selectedWaliEmail = found['email'] ?? '';
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
                    hintText: 'Pilih wali dari daftar atau ketik nama',
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
            if (_selectedPaket != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1C4E9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF6200EE), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Batas Jatuh Tempo Paket:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6200EE),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedPaket!.jatuhTempoFormatted,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF311B92),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6200EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Sinkron ke Wali',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Field: Status Transaksi SPP
            const Text(
              'Status Transaksi SPP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _statusPembayaran = 'Belum Bayar';
                        if (_selectedPaket != null) {
                          _nominalController.text = _formatNumber(_selectedPaket!.nominal.toString());
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFFFF3E0) : const Color(0xFFF4F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFE65100) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pending_actions_rounded,
                            size: 16,
                            color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFE65100) : const Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Belum Bayar (Tagihan)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFE65100) : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _statusPembayaran = 'Lunas';
                        if (_selectedPaket != null && _nominalController.text.isEmpty) {
                          _nominalController.text = _formatNumber(_selectedPaket!.nominal.toString());
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _statusPembayaran == 'Lunas' ? const Color(0xFFE8F5E9) : const Color(0xFFF4F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _statusPembayaran == 'Lunas' ? const Color(0xFF2E7D32) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: _statusPembayaran == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lunas (Terbayar)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _statusPembayaran == 'Lunas' ? const Color(0xFF2E7D32) : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Field 3: Nominal Pembayaran (Disabled jika Belum Bayar / Tagihan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nominal Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (_statusPembayaran == 'Belum Bayar')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFFE65100)),
                        SizedBox(width: 4),
                        Text(
                          'Terkunci sesuai paket',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFEAEAEF) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(10),
                border: _statusPembayaran == 'Belum Bayar' ? Border.all(color: const Color(0xFFD6D6E0)) : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    'Rp ',
                    style: TextStyle(
                      color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFF757575) : const Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _nominalController,
                      enabled: _statusPembayaran != 'Belum Bayar',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final formatted = _formatNumber(val);
                        if (formatted != val) {
                          _nominalController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _statusPembayaran == 'Belum Bayar' ? FontWeight.bold : FontWeight.normal,
                        color: _statusPembayaran == 'Belum Bayar' ? const Color(0xFF424242) : const Color(0xFF1C1C1E),
                      ),
                      decoration: InputDecoration(
                        hintText: _statusPembayaran == 'Belum Bayar'
                            ? (_selectedPaket != null
                                ? _formatNumber(_selectedPaket!.nominal.toString())
                                : 'Pilih paket bimbel di atas')
                            : '35.000',
                        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_statusPembayaran == 'Belum Bayar')
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock_rounded, size: 16, color: Color(0xFF8E8E93)),
                    ),
                ],
              ),
            ),

            if (_statusPembayaran == 'Belum Bayar') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFE65100)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _selectedPaket != null
                          ? 'Tagihan wali terkunci otomatis sebesar Rp ${_formatNumber(_selectedPaket!.nominal.toString())} sesuai paket ${_selectedPaket!.namaPaket}.'
                          : 'Nominal otomatis terkunci dan terisi saat Anda memilih paket bimbel di atas.',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ] else if (_selectedPaket != null && _nominalController.text.isNotEmpty) ...[
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

            // Tombol Submit Transaksi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusPembayaran == 'Belum Bayar' ? const Color(0xFFE65100) : const Color(0xFF6200EE),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _statusPembayaran == 'Belum Bayar'
                                ? Icons.send_rounded
                                : Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusPembayaran == 'Belum Bayar'
                                ? 'Buat & Kirim Tagihan ke Wali'
                                : 'Verifikasi Pembayaran Lunas',
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
    );
  }
}

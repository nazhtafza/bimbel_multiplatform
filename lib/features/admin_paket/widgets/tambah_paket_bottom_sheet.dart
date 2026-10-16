import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/paket_controller.dart';
import '../models/paket_model.dart';

class TambahPaketBottomSheet extends ConsumerStatefulWidget {
  final PaketModel? existingPaket;

  const TambahPaketBottomSheet({
    super.key,
    this.existingPaket,
  });

  static Future<void> show(BuildContext context, {PaketModel? existingPaket}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TambahPaketBottomSheet(existingPaket: existingPaket),
    );
  }

  @override
  ConsumerState<TambahPaketBottomSheet> createState() => _TambahPaketBottomSheetState();
}

class _TambahPaketBottomSheetState extends ConsumerState<TambahPaketBottomSheet> {
  final _namaController = TextEditingController();
  final _nominalController = TextEditingController();
  DateTime? _selectedJatuhTempo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPaket != null) {
      _namaController.text = widget.existingPaket!.namaPaket;
      _nominalController.text = _formatNumber(widget.existingPaket!.nominal.toString());
      _selectedJatuhTempo = widget.existingPaket!.jatuhTempo ?? DateTime(DateTime.now().year, DateTime.now().month, 10);
    } else {
      _selectedJatuhTempo = DateTime(DateTime.now().year, DateTime.now().month, 10);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nominalController.dispose();
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

  String _formatJatuhTempoDisplay(DateTime? date) {
    if (date == null) return 'Pilih Tanggal Jatuh Tempo';
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  Future<void> _pickJatuhTempo() async {
    final now = DateTime.now();
    final initialDate = _selectedJatuhTempo ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
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
      setState(() {
        _selectedJatuhTempo = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final nama = _namaController.text.trim();
    final nominal = _parseNominal(_nominalController.text);

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama paket wajib diisi'), backgroundColor: Colors.red),
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

    if (widget.existingPaket == null) {
      await ref.read(paketControllerProvider.notifier).tambahPaket(
            namaPaket: nama,
            nominal: nominal,
            jatuhTempo: _selectedJatuhTempo,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket bimbel berhasil ditambahkan!')),
        );
      }
    } else {
      await ref.read(paketControllerProvider.notifier).updatePaket(
            id: widget.existingPaket!.id,
            namaPaket: nama,
            nominal: nominal,
            jatuhTempo: _selectedJatuhTempo,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket bimbel berhasil diperbarui!')),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.existingPaket == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Paket'),
        content: Text('Hapus paket "${widget.existingPaket!.namaPaket}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(paketControllerProvider.notifier).hapusPaket(widget.existingPaket!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paket bimbel telah dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingPaket != null;

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

            // Header Judul
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Paket Bimbel' : 'Tambah Paket Bimbel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _handleDelete,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Field 1: Nama Paket
            const Text(
              'Nama Paket',
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
              child: TextField(
                controller: _namaController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                decoration: const InputDecoration(
                  hintText: 'Tambahkan Nama Paket',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Field 2: Nominal Pembayaran
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
            const SizedBox(height: 18),

            // Field 3: Jatuh Tempo Pembayaran (Format Kalender)
            const Text(
              'Jatuh Tempo Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickJatuhTempo,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E2E8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6200EE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF6200EE),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatJatuhTempoDisplay(_selectedJatuhTempo),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Klik untuk memilih tanggal kalender',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: Color(0xFF6200EE),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Verifikasi Pembayaran (Simpan)
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

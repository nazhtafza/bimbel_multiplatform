import 'package:flutter/material.dart';
import '../../admin_transaksi/models/transaksi_model.dart';

class BuktiPembayaranDialog extends StatelessWidget {
  final TransaksiModel transaksi;

  const BuktiPembayaranDialog({super.key, required this.transaksi});

  static void show(BuildContext context, TransaksiModel transaksi) {
    showDialog(
      context: context,
      builder: (ctx) => BuktiPembayaranDialog(transaksi: transaksi),
    );
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
    final isLunas = transaksi.status.toLowerCase() == 'lunas';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Success Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLunas ? Icons.check_circle_rounded : Icons.pending_rounded,
                  color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE65100),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title & Status
              const Text(
                'Bukti Pembayaran SPP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLunas ? 'Transaksi Berhasil & Terverifikasi' : 'Menunggu Konfirmasi Pembayaran',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Nominal Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL DIBAYAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(transaksi.nominal)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Detail Rows
              _buildRow('Nama Siswa', transaksi.namaSiswa),
              _buildRow('Paket Bimbel', transaksi.kategori ?? 'Paket Bimbel Reguler'),
              _buildRow('Tanggal', transaksi.tanggal),
              _buildRow('Metode', transaksi.metode),
              _buildRow('Status', transaksi.status, isStatus: true, isLunas: isLunas),
              if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty)
                _buildRow('Keterangan', transaksi.catatan!),

              const SizedBox(height: 24),

              // 5. Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStatus = false, bool isLunas = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLunas ? const Color(0xFFE0F7EF) : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isLunas ? const Color(0xFF00A86B) : const Color(0xFFE53935),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

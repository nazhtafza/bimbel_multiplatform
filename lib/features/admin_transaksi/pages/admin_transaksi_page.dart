import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTransaksiPage extends ConsumerWidget {
  const AdminTransaksiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Transaksi Pembayaran'),
      ),
      body: const Center(
        child: Text('Menunggu desain UI Transaksi... (Kirim gambar Anda)'),
      ),
    );
  }
}
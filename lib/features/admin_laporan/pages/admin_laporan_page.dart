import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminLaporanPage extends ConsumerWidget {
  const AdminLaporanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Rekapitulasi'),
      ),
      body: const Center(
        child: Text('Menunggu desain UI Laporan... (Kirim gambar Anda)'),
      ),
    );
  }
}
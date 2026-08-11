import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Tagihan Siswa'),
      ),
      body: const Center(
        child: Text('Menunggu desain UI Dasbor... (Kirim gambar Anda)'),
      ),
    );
  }
}
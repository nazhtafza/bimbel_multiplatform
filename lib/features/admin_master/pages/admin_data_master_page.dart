import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDataMasterPage extends ConsumerWidget {
  const AdminDataMasterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Master'),
      ),
      body: const Center(
        child: Text('Menunggu desain UI Data Master... (Kirim gambar Anda)'),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wajib di-import untuk Riverpod

import 'package:education_payment_app/main.dart';

void main() {
  testWidgets('Smoke test: Aplikasi berhasil berjalan', (WidgetTester tester) async {
    // Karena kita menggunakan Riverpod, widget utama harus dibungkus dengan ProviderScope
    // persis seperti yang kita lakukan di main.dart
    await tester.pumpWidget(
      const ProviderScope(
        child: EducationPaymentApp(),
      ),
    );

    // Menunggu seluruh animasi dan proses perpindahan halaman (routing) selesai
    await tester.pumpAndSettle();

    // Memastikan bahwa aplikasi setidaknya berhasil memuat MaterialApp tanpa crash
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Catatan: Kode pengujian 'counter' (0, 1, dan icon +) sudah kita hapus 
    // karena aplikasi kita sekarang menampilkan Dasbor Admin, bukan aplikasi penghitung angka.
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  // 1. Pastikan binding engine Flutter siap sebelum operasi native apa pun
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Muat .env dengan proteksi try-catch
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Peringatan: Gagal memuat file .env: $e");
  }

  // 3. Ambil URL dan Key
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // 4. Inisialisasi Supabase
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
    } catch (e) {
      debugPrint("Gagal inisialisasi Supabase: $e");
    }
  } else {
    debugPrint("Peringatan: SUPABASE_URL atau SUPABASE_ANON_KEY kosong di .env");
  }

  // 5. Jalankan aplikasi utama
  runApp(
    const ProviderScope(
      child: EducationPaymentApp(),
    ),
  );
}

class EducationPaymentApp extends ConsumerWidget {
  const EducationPaymentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Education Payment App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE)),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
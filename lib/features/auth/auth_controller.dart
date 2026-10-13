import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authControllerProvider = Provider<AuthController>((ref) => AuthController(ref));

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  // Registrasi Akun Baru (Default: Wali Murid)
  Future<String?> signUp({
    required String email,
    required String password,
    required String nama,
    String role = 'Wali',
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        // Menyimpan data profil dan role ke tabel users publik
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'nama': nama,
          'role': role,
        });
      }

      ref.read(authLoadingProvider.notifier).state = false;
      return null;
    } on AuthException catch (e) {
      ref.read(authLoadingProvider.notifier).state = false;
      return e.message;
    } catch (e) {
      ref.read(authLoadingProvider.notifier).state = false;
      return 'Terjadi kesalahan sistem: $e';
    }
  }

  // Login dengan Email & Password serta Pengecekan Role
  Future<({String? role, String? error})> signIn({
    required String email,
    required String password,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        // Query membaca kolom role berdasarkan ID user login
        final data = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        ref.read(authLoadingProvider.notifier).state = false;
        return (role: data?['role'] as String?, error: null);
      }

      ref.read(authLoadingProvider.notifier).state = false;
      return (role: null, error: 'Pengguna tidak ditemukan.');
    } on AuthException catch (e) {
      ref.read(authLoadingProvider.notifier).state = false;
      return (role: null, error: e.message);
    } catch (e) {
      ref.read(authLoadingProvider.notifier).state = false;
      return (role: null, error: 'Terjadi kesalahan sistem: $e');
    }
  }

  // Logout Akun
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
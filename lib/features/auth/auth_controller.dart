import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_user/controllers/user_wali_controller.dart';

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
        // Menyimpan data profil dan role ke tabel users publik Supabase
        try {
          await Supabase.instance.client.from('users').insert({
            'id': user.id,
            'nama': nama,
            'email': email,
            'role': role,
          });
        } catch (_) {}

        // Simpan sesi login lokal
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_role', role);
          await prefs.setString('user_email', email);
          await prefs.setString('user_nama', nama);
          await prefs.setString('user_id', user.id);
          await prefs.setString('last_route', role.toLowerCase() == 'wali' ? '/wali' : '/admin/dashboard');
        } catch (_) {}

        if (role.toLowerCase() == 'wali') {
          try {
            ref.read(userWaliControllerProvider.notifier).recordLogin(
                  email: email,
                  nama: nama,
                  userId: user.id,
                );
          } catch (_) {}
        }
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
        // Query membaca kolom role dan nama berdasarkan ID user login
        final data = await Supabase.instance.client
            .from('users')
            .select('role, nama')
            .eq('id', user.id)
            .maybeSingle();

        final userRole = data?['role'] as String? ?? 'Wali';
        final userName = data?['nama'] as String? ?? email.split('@').first;

        // Pastikan akun user tersimpan di tabel users Supabase
        try {
          await Supabase.instance.client.from('users').upsert({
            'id': user.id,
            'nama': userName,
            'email': user.email ?? email,
            'role': userRole,
          });
        } catch (_) {
          try {
            await Supabase.instance.client.from('users').update({
              'email': user.email ?? email,
            }).eq('id', user.id);
          } catch (_) {}
        }

        // Simpan sesi login lokal secara persisten
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_role', userRole);
          await prefs.setString('user_email', user.email ?? email);
          await prefs.setString('user_nama', userName);
          await prefs.setString('user_id', user.id);
          await prefs.setString('last_route', userRole.toLowerCase() == 'wali' ? '/wali' : '/admin/dashboard');
        } catch (_) {}

        // Catat data user wali yang telah login ke controller
        if (userRole.toLowerCase() == 'wali') {
          try {
            ref.read(userWaliControllerProvider.notifier).recordLogin(
                  email: user.email ?? email,
                  nama: userName,
                  userId: user.id,
                );
          } catch (_) {}
        }

        ref.read(authLoadingProvider.notifier).state = false;
        return (role: userRole, error: null);
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

  // Logout Akun & Bersihkan Sesi Lokal
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_route');
      await prefs.remove('is_logged_in');
      await prefs.remove('user_role');
      await prefs.clear();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Tampilan splash screen (1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedRole = prefs.getString('user_role');
      final lastRoute = prefs.getString('last_route');

      // Cek session aktif dari Supabase Auth
      final currentSession = Supabase.instance.client.auth.currentSession;
      final currentUser = Supabase.instance.client.auth.currentUser;

      // 1. Jika ada tampilan rute terakhir yang tersimpan (misal /wali atau menu admin),
      // langsung buka tampilan tersebut agar tidak reset ke tampilan semula setelah lost connection
      if (lastRoute != null &&
          lastRoute.isNotEmpty &&
          lastRoute != '/splash' &&
          lastRoute != '/login') {
        if (mounted) {
          context.go(lastRoute);
          return;
        }
      }

      // 2. Jika sebelumnya sudah login dan belum logout
      if ((isLoggedIn && savedRole != null) || (currentSession != null && currentUser != null)) {
        String role = savedRole ?? 'Admin';

        // Jika session Supabase masih aktif tapi role belum tercatat di prefs, sinkronkan
        if (currentUser != null && savedRole == null) {
          try {
            final data = await Supabase.instance.client
                .from('users')
                .select('role')
                .eq('id', currentUser.id)
                .maybeSingle();

            if (data != null && data['role'] != null) {
              role = data['role'] as String;
              await prefs.setString('user_role', role);
              await prefs.setBool('is_logged_in', true);
            }
          } catch (_) {}
        }

        if (mounted) {
          if (role.toLowerCase() == 'wali') {
            context.go('/wali');
          } else {
            context.go('/admin/dashboard');
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error saat memeriksa sesi login: $e');
    }

    // Jika belum login atau sesi telah berakhir/di-logout
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6200EE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_bimbel.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 54,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
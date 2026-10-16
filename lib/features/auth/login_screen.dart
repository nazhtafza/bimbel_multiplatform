import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authControllerProvider);

    if (_isRegister) {
      final error = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nama: _namaController.text.trim(),
        role: 'Wali',
      );

      if (!mounted) return;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan masuk.')),
        );
        setState(() => _isRegister = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      final res = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      if (res.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error!), backgroundColor: Colors.red),
        );
      } else {
        final roleLower = (res.role ?? '').toLowerCase();
        if (roleLower == 'wali') {
          context.go('/wali');
        } else {
          // Default ke admin dashboard
          context.go('/admin/dashboard');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF5A189A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo_bimbel.png',
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Bimbel Bunda',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isRegister ? 'Daftar Akun Baru' : 'Mulai Catat Tagihan\nBimbel Dengan Mudah',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Daftarkan akun baru wali murid.'
                          : 'Masuk dengan email dan kata sandi yang terdaftar.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRegister) ...[
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (val) =>
                            val == null || !val.contains('@') ? 'Masukkan email valid' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (val) =>
                            val == null || val.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6200EE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: isLoading ? null : _handleSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isRegister ? 'Daftar Akun' : 'Masuk',
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = !_isRegister),
                        child: Text(
                          _isRegister ? 'Sudah punya akun? Masuk di sini' : 'Belum punya akun? Daftar di sini',
                          style: const TextStyle(color: Color(0xFF6200EE)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
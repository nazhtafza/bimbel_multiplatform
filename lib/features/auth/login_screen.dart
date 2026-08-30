import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget{
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>{
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context){
    final isLoading = ref.watch(authLoadingProvider);
    return Scaffold(
      backgroundColor: const Color((0xFF6200EE)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Image.asset('assets/Paydu_logo 1.png', width: 40, height: 40),
                        const SizedBox(width: 12),
                        const Text(
                          'Bimbel Bunda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Image.asset(
                        'assets/login_image.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Judul
                    const Text(
                      'Mulai Catan Pembayaran\nBimbel Dengan Mudah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subjudul
                    const Text(
                      'Tambahkan Nomor WhatsApp untuk mulai melihat laporan keuangan bimbingan belajar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan Nomor Telepon',
                  style: TextStyle(
                    color: Color(0xFF5A189A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Input Field Nomor Telepon
                IntlPhoneField(
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nomor Telepon',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                  ),
                  initialCountryCode: 'ID',
                  showDropdownIcon: true,
                  onChanged: (phone){
                    // menyimpan nomoer lengkap dengan kode negara
                    _phoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 16),

                // send otp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    onPressed: isLoading ? null : () async{
                      if(_phoneNumber.isEmpty || _phoneNumber.length < 10) return;
                      final success = await ref.read(authControllerProvider).signInWithPhone(_phoneNumber);
                      if (success && context.mounted){
                        context.go('/verify-otp', extra: _phoneNumber);
                      }
                    },
                  child: isLoading ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ) : const Text(
                    'Kirim OTP',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ),
            ),
          ],
        ))
    );
  }
}
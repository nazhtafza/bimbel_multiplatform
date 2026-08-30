import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'auth_controller.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget{
  final String phoneNumber;
  const VerifyOtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>{
  String _otpCode = '';

  // buat variable timer
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState(){
    super.initState();
    _startTimer();
  }

  // function countdown
  void _startTimer(){
    setState(() {
      _remainingSeconds = 60;
    });
  
  _timer = Timer.periodic(const Duration(seconds: 1), (timer){
    if(_remainingSeconds > 0){
      setState(() {
        _remainingSeconds--;
      });
    }else{
      _timer?.cancel();
    }
  });
  }

  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    final isLoading = ref.watch(authLoadingProvider);

    final defaultPinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: const TextStyle(fontSize: 20, color: Color(0xFF6200EE), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black)
          ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'assets/otp_img.png',
                height: 180,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 12),

              // Judul
              const Text(
                'Enter Verification Code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6200EE)),
              ),

              const SizedBox(height: 12),

              // Subjudul
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'Masukkan OTP yang kami kirimkan ke nomor Anda\n'),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(color: Color(0xFF6200EE), fontWeight: FontWeight.bold),
                    ),
                ], 
                ),
              ),
              const SizedBox(height: 32),

              // Pinput (kolom auth)
              Pinput(
                length: 4,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: const Color(0xFF6200EE), width: 2),
                ),
                onChanged: (value) => _otpCode = value,
              ),

              const SizedBox(height: 24),

              // kirim ulang dinamis
              _remainingSeconds > 0 ? Text(
                'Kirim ulang kode dalam 00:${_remainingSeconds.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ) : GestureDetector(
                onTap: () async {
                  // recall function kirim otp
                  final success = await ref.read(authControllerProvider).signInWithPhone(widget.phoneNumber);
                  if (success){
                    _startTimer();
                  }
                },
                child: const Text(
                  'Kirim ulang kode',
                  style: TextStyle(
                    color: Color(0xFF6200EE),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),

              // button lanjutkan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isLoading ? null : () async{
                    if(_otpCode.length < 4) return;
                    final success = await ref.read(authControllerProvider).verifyOtp(widget.phoneNumber, _otpCode);

                    if(success && context.mounted){
                      context.go('/admin/dashboard');
                    }
                  },
                  child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) :
                  const Text ('Lanjutkan', style:TextStyle(fontSize: 16, color: Colors.white)),
              ),
              ),
            ],
          ),
          )),
    );
  }
}
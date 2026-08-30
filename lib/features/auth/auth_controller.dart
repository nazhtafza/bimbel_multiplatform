import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authLoadingProvider = StateProvider((ref)=> false);

// provider function auth
final authControllerProvider = Provider((ref){
  return AuthController(ref); 
});

class AuthController {
  final Ref ref;
  AuthController(this.ref);
  Future<bool> signInWithPhone(String phoneNumber) async{
    // send otp
    ref.read(authLoadingProvider.notifier).state = true;
    try{
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phoneNumber,
      );
      ref.read(authLoadingProvider.notifier).state = false;
      return true;
    }catch(e){
      ref.read(authLoadingProvider.notifier).state = false;
      print('Error mengirim kode OTP: $e');
      return false;
    }
  }

  // verification otp
  Future<bool>verifyOtp(String phoneNumber, String otp) async{
    ref.read(authLoadingProvider.notifier).state = true;
    try{
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: phoneNumber,
      );
      ref.read(authLoadingProvider.notifier).state = false;
      return res.session !=null;
    } catch (e){
      ref.read(authLoadingProvider.notifier).state = false;
      print('Error verifying OTP: $e');
      return false;
    }
  }
}
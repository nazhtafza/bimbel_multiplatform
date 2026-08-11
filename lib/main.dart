import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const ProviderScope(child: EducationPaymentApp()));
}
class EducationPaymentApp extends ConsumerWidget{
  const EducationPaymentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Education Payment App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

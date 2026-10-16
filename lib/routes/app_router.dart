import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/admin_dashboard/admin_scaffold.dart';
import '../features/admin_dashboard/pages/admin_dashboard_page.dart';
import '../features/admin_transaksi/pages/admin_transaksi_page.dart';
import '../features/admin_transaksi/pages/detail_transaksi_page.dart';
import '../features/admin_transaksi/models/transaksi_model.dart';
import '../features/admin_paket/pages/admin_paket_page.dart';
import '../features/admin_user/pages/admin_user_wali_page.dart';
import '../features/admin_laporan/pages/admin_laporan_page.dart';
import '../features/wali/pages/wali_home_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/wali',
        name: 'wali',
        builder: (context, state) => const WaliHomePage(),
      ),
      GoRoute(
        path: '/admin/transaksi/detail',
        name: 'detail_transaksi',
        builder: (context, state) {
          final item = state.extra as TransaksiModel?;
          return DetailTransaksiPage(transaksi: item);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const AdminDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/transaksi',
                builder: (context, state) => const AdminTransaksiPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/paket',
                builder: (context, state) => const AdminPaketPage(),
              ),
              GoRoute(
                path: '/admin/data',
                builder: (context, state) => const AdminPaketPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/user',
                builder: (context, state) => const AdminUserWaliPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/laporan',
                builder: (context, state) => const AdminLaporanPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
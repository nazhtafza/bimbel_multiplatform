import 'package:education_payment_app/features/admin_dashboard/pages/admin_dashboard_page.dart';
import 'package:education_payment_app/features/admin_laporan/pages/admin_laporan_page.dart';
import 'package:education_payment_app/features/admin_master/pages/admin_data_master_page.dart';
import 'package:education_payment_app/features/admin_transaksi/pages/admin_transaksi_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/admin_dashboard/admin_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((_ref){
  return GoRouter(
    initialLocation: '/admin/dashboard',

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Login'))),
        ),
      GoRoute(
        path: '/wali',
        name: 'wali',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Portal Wali'))),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell){
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
                path: '/admin/data',
                builder: (context, state) => const AdminDataMasterPage(),
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
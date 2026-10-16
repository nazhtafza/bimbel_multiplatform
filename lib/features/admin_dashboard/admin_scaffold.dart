import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminScaffold({super.key, required this.navigationShell});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _branchRoutes = [
    '/admin/dashboard',
    '/admin/transaksi',
    '/admin/paket',
    '/admin/user',
    '/admin/laporan',
  ];

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute(widget.navigationShell.currentIndex);
  }

  void _saveCurrentRoute(int index) {
    if (index >= 0 && index < _branchRoutes.length) {
      SharedPreferences.getInstance().then((p) {
        p.setString('last_route', _branchRoutes[index]);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index, double itemWidth) {
    _saveCurrentRoute(index);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Scroll otomatis agar item aktif berada di dalam layar
    if (_scrollController.hasClients) {
      if (index >= 3) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else if (index <= 1) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Menampilkan tepat 4 item di layar sekaligus dan dapat discroll
              final itemWidth = constraints.maxWidth / 4;

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildNavItem(
                        index: 0,
                        currentIndex: currentIndex,
                        icon: Icons.home_rounded,
                        label: 'Beranda',
                        itemWidth: itemWidth,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildNavItem(
                        index: 1,
                        currentIndex: currentIndex,
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Transaksi',
                        itemWidth: itemWidth,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildNavItem(
                        index: 2,
                        currentIndex: currentIndex,
                        icon: Icons.inventory_2_rounded,
                        label: 'Paket',
                        itemWidth: itemWidth,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildNavItem(
                        index: 3,
                        currentIndex: currentIndex,
                        icon: Icons.people_alt_rounded,
                        label: 'User',
                        itemWidth: itemWidth,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildNavItem(
                        index: 4,
                        currentIndex: currentIndex,
                        icon: Icons.description_rounded,
                        label: 'Laporan',
                        itemWidth: itemWidth,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required double itemWidth,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () => _onItemTapped(index, itemWidth),
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: isSelected
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: const Color(0xFF6200EE), size: 22),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF6200EE),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: const Color(0xFF1C1C1E), size: 22),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
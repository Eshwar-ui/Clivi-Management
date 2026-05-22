import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clivi_management/features/profile/screens/profile_screen.dart';
import 'package:clivi_management/features/projects/screens/project_list_screen.dart';
import 'package:clivi_management/features/bills/screens/bills_screen.dart';
import 'package:clivi_management/features/dashboard/screens/admin_dashboard.dart';
import 'package:clivi_management/features/dashboard/screens/site_manager_dashboard.dart';
import 'package:clivi_management/core/theme/app_colors.dart';
import 'package:clivi_management/features/auth/providers/auth_provider.dart';
import 'package:clivi_management/features/vendors/screens/vendor_analytics_dashboard.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const DashboardShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  late int _selectedIndex;
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _pageCount(String role) => role == 'admin' ? 5 : 4;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final role = profile?.role ?? 'admin';

    final Widget homeScreen = role == 'site_manager'
        ? const SiteManagerDashboard()
        : const AdminDashboard();

    // Ensure index is valid
    if (_selectedIndex >= _pageCount(role)) {
      _selectedIndex = _pageCount(role) - 1;
    }

    // Wrap home tab in a nested Navigator so screens pushed from home
    // (e.g. Material Master List) preserve the bottom navigation bar.
    final homeNavigator = Navigator(
      key: _homeNavKey,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => homeScreen),
    );

    final List<Widget> pages = [
      homeNavigator,
      const ProjectListScreen(),
      const BillsScreen(),
      if (role == 'admin') const VendorAnalyticsDashboard(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex == 0) {
          _homeNavKey.currentState?.maybePop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: _buildBottomNav(context, _selectedIndex, role),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex, String role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _buildNavItem(
                icon: Icons.business,
                label: 'Projects',
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _buildNavItem(
                icon: Icons.receipt_long,
                label: 'Bills',
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              if (role == 'admin')
                _buildNavItem(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  isSelected: currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: currentIndex == (role == 'admin' ? 4 : 3),
                onTap: () => _onItemTapped(role == 'admin' ? 4 : 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


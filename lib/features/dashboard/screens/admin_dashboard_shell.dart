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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);
    final role = profile?.role ?? authState.role?.value;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget homeScreen = role == 'site_manager'
        ? const SiteManagerDashboard()
        : const AdminDashboard();
    final isAdminRole = role == 'admin' || role == 'super_admin';

    final List<Widget> pages = [
      homeScreen,
      const ProjectListScreen(),
      const BillsScreen(),
      if (isAdminRole) const VendorAnalyticsDashboard(),
      const ProfileScreen(),
    ];

    // Ensure index is valid
    if (_selectedIndex >= pages.length) {
      _selectedIndex = pages.length - 1;
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Projects',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          if (isAdminRole)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

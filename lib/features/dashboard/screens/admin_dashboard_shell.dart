import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clivi_management/features/profile/screens/profile_screen.dart';
import 'package:clivi_management/features/projects/screens/project_list_screen.dart';
import 'package:clivi_management/features/bills/screens/bills_screen.dart';
import 'package:clivi_management/features/dashboard/screens/admin_dashboard.dart';
import 'package:clivi_management/features/dashboard/screens/site_manager_dashboard.dart';
import 'package:clivi_management/core/theme/app_colors.dart';
import 'package:clivi_management/core/ui/responsive.dart';
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

    final homeNavigator = Navigator(
      key: _homeNavKey,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => homeScreen),
    );

    final List<Widget> pages = [
      homeNavigator,
      const ProjectListScreen(),
      const BillsScreen(),
      if (isAdminRole) const VendorAnalyticsDashboard(),
      const ProfileScreen(),
    ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    final destinations = [
      const _ShellDestination(Icons.home_filled, 'Home'),
      const _ShellDestination(Icons.business, 'Projects'),
      const _ShellDestination(Icons.receipt_long, 'Bills'),
      if (isAdminRole) const _ShellDestination(Icons.bar_chart, 'Reports'),
      const _ShellDestination(Icons.person_outline, 'Profile'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && safeIndex == 0) {
          _homeNavKey.currentState?.maybePop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(Size(constraints.maxWidth, constraints.maxHeight));

          if (r.useRail) {
            final isExtended = constraints.maxWidth >= 1180;

            return Scaffold(
              body: Row(
                children: [
                  _DesktopSidebar(
                    destinations: destinations,
                    selectedIndex: safeIndex,
                    extended: isExtended,
                    onSelected: _onItemTapped,
                  ),
                  Expanded(child: pages[safeIndex]),
                ],
              ),
            );
          }

          return Scaffold(
            body: IndexedStack(index: safeIndex, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: safeIndex,
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
              items: destinations
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = extended ? 244.0 : 88.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            extended ? 16 : 12,
            16,
            extended ? 16 : 12,
            16,
          ),
          child: Column(
            crossAxisAlignment: extended
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              _SidebarHeader(extended: extended),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = destinations[index];
                    return _DesktopNavItem(
                      icon: item.icon,
                      label: item.label,
                      selected: index == selectedIndex,
                      extended: extended,
                      onTap: () => onSelected(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/logo.png',
        width: 38,
        height: 38,
        fit: BoxFit.contain,
      ),
    );

    if (!extended) {
      return SizedBox(width: 56, height: 44, child: Center(child: logo));
    }

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          logo,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Clivi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.textSecondary;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: foreground,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    );

    final navItem = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: extended
              ? Row(
                  children: [
                    Icon(icon, size: 21, color: foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ),
                  ],
                )
              : Center(child: Icon(icon, size: 22, color: foreground)),
        ),
      ),
    );

    return extended ? navItem : Tooltip(message: label, child: navItem);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../auth/data/models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../materials/screens/material_master_list_screen.dart';
import '../providers/dashboard_provider.dart';
import '../data/models/dashboard_models.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshAll(ref),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final r = R(Size(constraints.maxWidth, constraints.maxHeight));

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.isDesktop ? 32 : 20,
                        vertical: r.isDesktop ? 28 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer(builder: (context, ref, _) {
                            final profile = ref.watch(userProfileProvider);
                            return _buildHeader(context, ref, profile);
                          }),
                          SizedBox(height: r.isDesktop ? 28 : 20),
                          Consumer(builder: (context, ref, _) {
                            final statsState = ref.watch(dashboardStatsProvider);
                            return _buildStatsRow(context, ref, statsState, r);
                          }),
                          SizedBox(height: r.isDesktop ? 28 : 20),
                          Consumer(builder: (context, ref, _) {
                            final operationsCounts = ref.watch(operationsLiveCountsProvider);
                            return _buildQuickActions(context, operationsCounts, r);
                          }),
                          SizedBox(height: r.isDesktop ? 28 : 20),
                          if (r.isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Consumer(builder: (context, ref, _) {
                                    final projectsState = ref.watch(activeProjectsProvider);
                                    return _buildActiveProjectsSection(context, ref, projectsState);
                                  }),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 2,
                                  child: Consumer(builder: (context, ref, _) {
                                    final activityState = ref.watch(recentActivityProvider);
                                    return _buildRecentOpsSection(context, ref, activityState);
                                  }),
                                ),
                              ],
                            )
                          else ...[
                            Consumer(builder: (context, ref, _) {
                              final projectsState = ref.watch(activeProjectsProvider);
                              return _buildActiveProjectsSection(context, ref, projectsState);
                            }),
                            const SizedBox(height: 20),
                            Consumer(builder: (context, ref, _) {
                              final activityState = ref.watch(recentActivityProvider);
                              return _buildRecentOpsSection(context, ref, activityState);
                            }),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(operationsLiveCountsProvider);
    await Future.wait([
      ref.read(dashboardStatsProvider.notifier).refresh(),
      ref.read(recentActivityProvider.notifier).refresh(),
      ref.read(activeProjectsProvider.notifier).refresh(),
    ]);
  }

  // ── Header ──

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    UserProfileModel? profile,
  ) {
    final name =
        (profile?.fullName ?? '').isNotEmpty ? profile!.fullName! : 'Admin';
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.add_rounded,
          filled: true,
          tooltip: 'New Project',
          onTap: () async {
            await context.push('/projects/create');
            if (context.mounted) {
              ref.invalidate(activeProjectsProvider);
              ref.read(dashboardStatsProvider.notifier).refresh();
            }
          },
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onTap: () => _showNotificationsPanel(context, ref),
        ),
      ],
    );
  }

  // ── Stats Row ──

  Widget _buildStatsRow(
    BuildContext context,
    WidgetRef ref,
    DashboardStatsState state,
    R r,
  ) {
    final stats = state.stats;
    final isLoading = state.isLoading;

    final items = [
      _StatData(
        icon: Icons.folder_outlined,
        label: 'Active Projects',
        value: stats.activeProjects.toString(),
        color: AppColors.primary,
        onTap: () => context.push('/projects'),
      ),
      _StatData(
        icon: Icons.groups_outlined,
        label: 'Total Workers',
        value: stats.totalWorkers.toString(),
        color: AppColors.success,
      ),
      _StatData(
        icon: Icons.inventory_2_outlined,
        label: 'Low Stock Items',
        value: stats.lowStockItems.toString(),
        color: stats.lowStockItems > 0 ? AppColors.warning : AppColors.accent,
      ),
      _StatData(
        icon: Icons.description_outlined,
        label: 'Blueprints',
        value: stats.blueprintsCount.toString(),
        color: AppColors.info,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: r.isDesktop ? 4 : (r.isTablet ? 2 : 2),
        crossAxisSpacing: r.isDesktop ? 20 : 12,
        mainAxisSpacing: r.isDesktop ? 20 : 12,
        mainAxisExtent: 140,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _StatCard(stat: item, isLoading: isLoading);
      },
    );
  }

  // ── Quick Actions ──

  Widget _buildQuickActions(
    BuildContext context,
    AsyncValue<OperationsLiveCounts> operationsCounts,
    R r,
  ) {
    String subtitleFor({
      required int count,
      required String singular,
      required String plural,
    }) {
      return '$count ${count == 1 ? singular : plural}';
    }

    final liveCounts = operationsCounts.valueOrNull;
    final actions = [
      _QuickAction(
        label: 'Vendors',
        subtitle: liveCounts == null
            ? '...'
            : subtitleFor(
                count: liveCounts.vendors,
                singular: 'vendor',
                plural: 'vendors',
              ),
        icon: Icons.storefront_outlined,
        color: AppColors.primary,
        onTap: () => context.push('/master/vendors'),
      ),
      _QuickAction(
        label: 'Machinery',
        subtitle: liveCounts == null
            ? '...'
            : subtitleFor(
                count: liveCounts.machinery,
                singular: 'machine',
                plural: 'machines',
              ),
        icon: Icons.precision_manufacturing_outlined,
        color: AppColors.secondary,
        onTap: () => context.push('/master/machinery'),
      ),
      _QuickAction(
        label: 'Managers',
        subtitle: liveCounts == null
            ? '...'
            : subtitleFor(
                count: liveCounts.siteManagers,
                singular: 'manager',
                plural: 'managers',
              ),
        icon: Icons.badge_outlined,
        color: AppColors.accent,
        onTap: () => context.push('/admin/site-managers'),
      ),
      _QuickAction(
        label: 'Materials',
        subtitle: 'Master list',
        icon: Icons.category_outlined,
        color: AppColors.success,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MaterialMasterListScreen(),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: r.isDesktop ? 4 : 2,
            crossAxisSpacing: r.isDesktop ? 16 : 10,
            mainAxisSpacing: r.isDesktop ? 16 : 10,
            mainAxisExtent: 64,
          ),
          itemBuilder: (context, index) {
            return _QuickActionTile(action: actions[index]);
          },
        ),
      ],
    );
  }

  // ── Active Projects ──

  Widget _buildActiveProjectsSection(
    BuildContext context,
    WidgetRef ref,
    ActiveProjectsState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Active Projects',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/projects'),
                icon: const Text('View All'),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.isLoading)
            _buildProjectsLoading()
          else if (state.error != null)
            _buildSectionError(
              context,
              message: 'Could not load projects',
              onRetry: () =>
                  ref.read(activeProjectsProvider.notifier).refresh(),
            )
          else if (state.projects.isEmpty)
            _buildEmptyState(
              icon: Icons.folder_open_outlined,
              message: 'No active projects yet',
              actionLabel: 'Create Project',
              onAction: () => context.push('/projects/create'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.projects.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildProjectRow(context, state.projects[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, ProjectSummary project) {
    final statusColor = project.status == 'in_progress'
        ? AppColors.success
        : AppColors.warning;

    return InkWell(
      onTap: () => context.push('/projects/${project.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _getTypeColor(project.projectType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.business_rounded,
                color: _getTypeColor(project.projectType),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        project.displayType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (project.location != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            project.location!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${project.progress}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getProgressColor(project.progress)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // ── Recent Operations ──

  Widget _buildRecentOpsSection(
    BuildContext context,
    WidgetRef ref,
    RecentActivityState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Recent Activity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecentOperations(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildRecentOperations(
    BuildContext context,
    WidgetRef ref,
    RecentActivityState state,
  ) {
    if (state.isLoading && state.activities.isEmpty) {
      return _buildOperationsLoading();
    }

    if (state.error != null && state.activities.isEmpty) {
      return _buildSectionError(
        context,
        message: 'Could not load activity',
        onRetry: () => ref.read(recentActivityProvider.notifier).refresh(),
      );
    }

    if (state.activities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        message: 'No recent activity',
      );
    }

    final displayed = state.activities.take(6).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayed.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) =>
          _buildActivityItem(context, displayed[index]),
    );
  }

  Widget _buildActivityItem(BuildContext context, OperationLog activity) {
    final color = _getOperationColor(activity.operationType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getOperationIcon(activity.entityType),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description ?? activity.projectName ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.relativeTime,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ── Shared Helpers ──

  Widget _buildProjectsLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsLoading() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionError(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: AppColors.textHint),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context, WidgetRef ref) {
    final activityState = ref.read(recentActivityProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: activityState.activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: activityState.activities.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final activity =
                              activityState.activities[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                _getOperationIcon(activity.entityType),
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              activity.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              activity.description ??
                                  activity.projectName ??
                                  '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              activity.relativeTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
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

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'residential':
        return AppColors.info;
      case 'commercial':
        return AppColors.warning;
      case 'infrastructure':
        return AppColors.success;
      case 'industrial':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return AppColors.error;
    if (progress < 50) return AppColors.warning;
    if (progress < 75) return AppColors.info;
    return AppColors.success;
  }

  IconData _getOperationIcon(String entityType) {
    switch (entityType) {
      case 'project':
        return Icons.business_rounded;
      case 'stock':
        return Icons.inventory_2_rounded;
      case 'labour':
        return Icons.people_rounded;
      case 'blueprint':
        return Icons.description_rounded;
      case 'machinery':
        return Icons.construction_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getOperationColor(String operationType) {
    switch (operationType) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.info;
      case 'delete':
        return AppColors.error;
      case 'upload':
        return AppColors.primary;
      case 'status_change':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }
}

// ── Private Widgets ──

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: filled ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, this.isLoading = false});

  final _StatData stat;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: stat.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              const Spacer(),
              if (isLoading)
                Container(
                  height: 24,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  stat.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      action.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

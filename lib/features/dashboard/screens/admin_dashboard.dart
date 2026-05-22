import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/data/models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../materials/screens/material_master_list_screen.dart';
import '../providers/dashboard_provider.dart';
import '../data/models/dashboard_models.dart';

/// Admin Dashboard matching the design mockup
/// Features: Blue stats header, operations grid, active projects, recent operations
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final statsState = ref.watch(dashboardStatsProvider);
    final activityState = ref.watch(recentActivityProvider);
    final projectsState = ref.watch(activeProjectsProvider);
    final operationsCounts = ref.watch(operationsLiveCountsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _buildAppBar(context, ref, profile),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () async {
            await context.push('/projects/create');
            if (context.mounted) {
              ref.invalidate(activeProjectsProvider);
              ref.read(dashboardStatsProvider.notifier).refresh();
            }
          },
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshAll(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(context, statsState),
                const SizedBox(height: 20),
                _buildOperationsSection(context, operationsCounts),
                const SizedBox(height: 18),
                _buildActiveProjectsSection(context, ref, projectsState),
                const SizedBox(height: 18),
                _buildRecentOpsSection(context, ref, activityState),
                const SizedBox(height: 24),
              ],
            ),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    UserProfileModel? profile,
  ) {
    return CustomAppBar(
      showLogo: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (profile?.fullName ?? '').isNotEmpty ? profile!.fullName! : 'Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      showBackButton: false,
      actions: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            color: AppColors.textPrimary,
            onPressed: () => _showNotificationsPanel(context, ref),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppColors.primary, size: 20),
        ),
      ],
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
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
                            Icon(Icons.notifications_none,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: activityState.activities.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final activity = activityState.activities[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                _getOperationIcon(activity.entityType),
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              activity.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              activity.description ??
                                  activity.projectName ??
                                  '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              activity.relativeTime,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
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

  Widget _buildStatsRow(BuildContext context, DashboardStatsState state) {
    final stats = state.stats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/projects'),
              child: _statCard(
                background: AppColors.primary,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                icon: Icons.show_chart,
                value: stats.activeProjects.toString().padLeft(2, '0'),
                label: 'Active Projects',
                badgeText: '+12%',
                textColor: Colors.white,
                badgeColor: Colors.white.withValues(alpha: 0.15),
                isLoading: state.isLoading,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              background: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              icon: Icons.groups_rounded,
              value: stats.totalWorkers.toString(),
              label: 'Total Workers',
              textColor: AppColors.textPrimary,
              badgeColor: Colors.transparent,
              isLoading: state.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required Color background,
    required Color shadowColor,
    required IconData icon,
    required String value,
    required String label,
    Color? textColor,
    String? badgeText,
    Color? badgeColor,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (textColor ?? AppColors.textPrimary).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor ?? AppColors.textPrimary),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: textColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            Container(
              height: 28,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: (textColor ?? AppColors.textPrimary).withValues(
                alpha: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required bool isLoading,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsSection(
    BuildContext context,
    AsyncValue<OperationsLiveCounts> operationsCounts,
  ) {
    String subtitleFor({
      required int count,
      required String singular,
      required String plural,
    }) {
      return '$count ${count == 1 ? singular : plural}';
    }

    final liveCounts = operationsCounts.valueOrNull;
    final operations = [
      _OperationTile(
        label: 'Materials',
        subtitle: liveCounts == null
            ? 'Loading...'
            : subtitleFor(
                count: liveCounts.vendors,
                singular: 'Vendor',
                plural: 'Vendors',
              ),
        icon: Icons.inventory_2_outlined,
        bg: Colors.blue[50],
        onTap: () => context.push('/master/vendors'),
      ),
      _OperationTile(
        label: 'Machinery',
        subtitle: liveCounts == null
            ? 'Loading...'
            : subtitleFor(
                count: liveCounts.machinery,
                singular: 'Machine',
                plural: 'Machines',
              ),
        icon: Icons.build_outlined,
        bg: Colors.orange[50],
        onTap: () => context.push('/master/machinery'),
      ),
      _OperationTile(
        label: 'Managers',
        subtitle: liveCounts == null
            ? 'Loading...'
            : subtitleFor(
                count: liveCounts.siteManagers,
                singular: 'Manager',
                plural: 'Managers',
              ),
        icon: Icons.manage_accounts_outlined,
        bg: Colors.indigo[50],
        onTap: () => context.push('/admin/site-managers'),
      ),
      _OperationTile(
        label: 'Material Master List',
        subtitle: 'Manage Materials',
        icon: Icons.list_alt,
        bg: Colors.green[50],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MaterialMasterListScreen(),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 140,
            ),
            itemBuilder: (context, index) {
              final op = operations[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: op.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: op.bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(op.icon, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        op.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        op.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectsSection(
    BuildContext context,
    WidgetRef ref,
    ActiveProjectsState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Projects',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/projects'),
                child: Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No active projects',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildProjectCard(context, state.projects[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOpsSection(
    BuildContext context,
    WidgetRef ref,
    RecentActivityState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Operations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentOperations(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildProjectsLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectSummary project) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(
                      project.projectType,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.displayType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(project.projectType),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: project.status == 'in_progress'
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status == 'in_progress' ? 'Active' : project.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: project.status == 'in_progress'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: project.progress / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${project.progress}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
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

  Widget _buildSectionError(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
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
        message: 'Could not load recent operations',
        onRetry: () => ref.read(recentActivityProvider.notifier).refresh(),
      );
    }

    if (state.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No recent operations',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      itemCount: state.activities.take(5).length,
      itemBuilder: (context, index) {
        final activity = state.activities[index];
        return _buildOperationItem2(context, activity);
      },
    );
  }

  Widget _buildOperationsLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOperationItem2(BuildContext context, OperationLog activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getOperationColor(
                activity.operationType,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getOperationIcon(activity.entityType),
              color: _getOperationColor(activity.operationType),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description ?? activity.projectName ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity.relativeTime,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getOperationIcon(String entityType) {
    switch (entityType) {
      case 'project':
        return Icons.business;
      case 'stock':
        return Icons.inventory_2;
      case 'labour':
        return Icons.people;
      case 'blueprint':
        return Icons.description;
      case 'machinery':
        return Icons.construction;
      default:
        return Icons.info_outline;
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

class _OperationTile {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color? bg;
  final VoidCallback onTap;

  const _OperationTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.bg,
    required this.onTap,
  });
}

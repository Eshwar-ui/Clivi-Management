import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/data/models/user_profile_model.dart';
import '../../../features/auth/providers/auth_repository_provider.dart';
import '../../../features/projects/data/models/project_model.dart';
import '../../../features/projects/providers/project_provider.dart';

class SiteManagerWithProjects {
  final UserProfileModel manager;
  final List<ProjectModel> assignedProjects;

  const SiteManagerWithProjects({
    required this.manager,
    required this.assignedProjects,
  });
}

/// Provider used by both management screen and add screen invalidation.
final siteManagersProvider = FutureProvider<List<SiteManagerWithProjects>>((
  ref,
) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final projectRepository = ref.watch(projectRepositoryProvider);

  final managersFuture = authRepository.getUsersByRole('site_manager');
  final projectsFuture = projectRepository.getProjects(
    page: 0,
    pageSize: 1000,
    forceRefresh: true,
  );

  final results = await Future.wait<Object>([managersFuture, projectsFuture]);
  final managers = results[0] as List<UserProfileModel>;
  final projects = results[1] as List<ProjectModel>;

  final projectsByManagerId = <String, List<ProjectModel>>{};

  for (final project in projects) {
    final assignments = project.assignments ?? const <ProjectAssignmentModel>[];
    for (final assignment in assignments) {
      projectsByManagerId
          .putIfAbsent(assignment.userId, () => <ProjectModel>[])
          .add(project);
    }
  }

  final data =
      managers.map((manager) {
        final assignedProjects = List<ProjectModel>.from(
          projectsByManagerId[manager.id] ?? const <ProjectModel>[],
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return SiteManagerWithProjects(
          manager: manager,
          assignedProjects: assignedProjects,
        );
      }).toList()..sort((a, b) {
        final aName = (a.manager.fullName ?? '').toLowerCase();
        final bName = (b.manager.fullName ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

  return data;
});

/// Site Manager Management Screen for Admins
class SiteManagerManagementScreen extends ConsumerWidget {
  const SiteManagerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteManagersAsync = ref.watch(siteManagersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Site Managers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/site-managers/add'),
        tooltip: 'Add Site Manager',
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: siteManagersAsync.when(
        data: (siteManagers) {
          if (siteManagers.isEmpty) {
            return _EmptyState(
              onAddManager: () => context.push('/admin/site-managers/add'),
            );
          }

          final assignedManagers = siteManagers
              .where((manager) => manager.assignedProjects.isNotEmpty)
              .length;
          final totalAssignedProjects = siteManagers.fold<int>(
            0,
            (sum, manager) => sum + manager.assignedProjects.length,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(siteManagersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                _SummaryCard(
                  totalManagers: siteManagers.length,
                  assignedManagers: assignedManagers,
                  totalAssignedProjects: totalAssignedProjects,
                ),
                const SizedBox(height: 14),
                ...siteManagers.map(
                  (entry) => _ManagerAssignmentCard(entry: entry),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load site managers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(siteManagersProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalManagers;
  final int assignedManagers;
  final int totalAssignedProjects;

  const _SummaryCard({
    required this.totalManagers,
    required this.assignedManagers,
    required this.totalAssignedProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'Managers',
              value: totalManagers.toString(),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Assigned',
              value: assignedManagers.toString(),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Projects',
              value: totalAssignedProjects.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ManagerAssignmentCard extends StatelessWidget {
  final SiteManagerWithProjects entry;

  const _ManagerAssignmentCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final manager = entry.manager;
    final assignedProjects = entry.assignedProjects;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.siteManager.withValues(alpha: 0.12),
          backgroundImage: manager.avatarUrl != null
              ? NetworkImage(manager.avatarUrl!)
              : null,
          child: manager.avatarUrl == null
              ? Text(
                  _avatarText(manager.fullName),
                  style: const TextStyle(
                    color: AppColors.siteManager,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                manager.fullName ?? 'Unknown Manager',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${assignedProjects.length} Projects',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (manager.phone != null && manager.phone!.isNotEmpty)
                Text(
                  manager.phone!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (manager.email != null && manager.email!.isNotEmpty)
                Text(
                  manager.email!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (assignedProjects.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No project assigned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...assignedProjects.map(
              (project) => _AssignedProjectRow(project: project),
            ),
        ],
      ),
    );
  }

  String _avatarText(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '?';
    }
    return fullName.trim()[0].toUpperCase();
  }
}

class _AssignedProjectRow extends StatelessWidget {
  final ProjectModel project;

  const _AssignedProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: project.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  project.status.displayName,
                  style: TextStyle(
                    color: project.status.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.location?.isNotEmpty == true
                ? project.location!
                : 'Location not set',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: (project.progress.clamp(0, 100)) / 100,
              backgroundColor: const Color(0xFFDDE1EE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Progress ${project.progress}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddManager;

  const _EmptyState({required this.onAddManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Site Managers Yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first site manager.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddManager,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Site Manager'),
            ),
          ],
        ),
      ),
    );
  }
}

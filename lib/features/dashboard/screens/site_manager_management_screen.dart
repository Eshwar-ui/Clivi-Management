import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/data/models/user_profile_model.dart';
import '../../../features/auth/providers/auth_repository_provider.dart';
import '../../../features/projects/data/models/project_model.dart';
import '../../../features/projects/providers/project_provider.dart';
import 'add_site_manager_screen.dart';
import 'edit_site_manager_screen.dart';

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
  // We fetch projects to check assignments, though the new UI doesn't explicitly list them in the card
  // It might still be useful for filtering or "View Projects" later.
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
class SiteManagerManagementScreen extends ConsumerStatefulWidget {
  const SiteManagerManagementScreen({super.key});

  @override
  ConsumerState<SiteManagerManagementScreen> createState() =>
      _SiteManagerManagementScreenState();
}

class _SiteManagerManagementScreenState
    extends ConsumerState<SiteManagerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SiteManagerWithProjects> _filtered(List<SiteManagerWithProjects> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((item) {
      final name = (item.manager.fullName ?? '').toLowerCase();
      final email = (item.manager.email ?? '').toLowerCase();
      final phone = (item.manager.phone ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final siteManagersAsync = ref.watch(siteManagersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Site managers',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: siteManagersAsync.when(
        data: (siteManagers) {
          final filtered = _filtered(siteManagers);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(siteManagersProvider);
            },
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone…',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF9CA3AF), size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ),

                // Total Staff Count and Add Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty
                            ? 'Total Staff ${siteManagers.length}'
                            : '${filtered.length} of ${siteManagers.length} staff',
                        style: const TextStyle(
                          color: Color(0xFF1A1C1E),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddSiteManagerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Add Staff',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Empty state when search has no results
                if (filtered.isEmpty && _searchQuery.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 56,
                              color: AppColors.borderDark),
                          const SizedBox(height: 12),
                          Text(
                            'No staff match "$_searchQuery"',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Staff List
                if (filtered.isNotEmpty)
                  Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _StaffCard(
                        data: item,
                        onEditTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditSiteManagerScreen(manager: item.manager),
                            ),
                          );
                        },
                        onDeleteTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Delete Manager',
                                style: TextStyle(color: Colors.red),
                              ),
                              content: const Text(
                                'Are you sure you want to delete this manager? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .deleteUser(item.manager.id);
                            ref.invalidate(siteManagersProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Manager deleted successfully!',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete manager: ${e.toString()}',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }, // end data
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final SiteManagerWithProjects data;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _StaffCard({
    required this.data,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final manager = data.manager;
    final projects = data.assignedProjects;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitials(manager.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.fullName ?? 'Unknown',
                    style: const TextStyle(
                      color: Color(0xFF1A1C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manager.position ?? 'Site Manager',
                    style: const TextStyle(
                      color: Color(0xFF2563EB), // Blue text for position
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (projects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Projects:',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: projects.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'No projects assigned',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF1A1C1E),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDeleteTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

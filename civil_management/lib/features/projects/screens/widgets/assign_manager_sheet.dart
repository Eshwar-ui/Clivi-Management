import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/project_model.dart';
import '../../providers/project_provider.dart';

/// Bottom sheet for assigning/unassigning site managers to a project
class AssignManagerSheet extends ConsumerStatefulWidget {
  final String projectId;

  const AssignManagerSheet({super.key, required this.projectId});

  @override
  ConsumerState<AssignManagerSheet> createState() => _AssignManagerSheetState();
}

class _AssignManagerSheetState extends ConsumerState<AssignManagerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siteManagerSelectionProvider(widget.projectId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Assign Site Managers',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Selected count
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${state.selectedIds.length} selected',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (state.selectedIds.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // Clear all selections
                              for (final id in state.selectedIds.toList()) {
                                ref
                                    .read(
                                      siteManagerSelectionProvider(
                                        widget.projectId,
                                      ).notifier,
                                    )
                                    .toggleManager(id);
                              }
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'You can assign multiple site managers to this project.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search managers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              const Divider(),

              // Content
              Expanded(child: _buildContent(state, scrollController)),

              // Bottom action
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: AppButton(
                    text: 'Save Assignments',
                    onPressed: _handleSave,
                    isLoading: state.isSaving,
                    icon: Icons.save,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    SiteManagerSelectionState state,
    ScrollController scrollController,
  ) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading managers...');
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref
            .read(siteManagerSelectionProvider(widget.projectId).notifier)
            .loadManagers(),
      );
    }

    // Filter managers by search query
    final filteredManagers = state.managers.where((manager) {
      if (_searchQuery.isEmpty) return true;
      final name = manager.fullName?.toLowerCase() ?? '';
      final phone = manager.phone?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || phone.contains(_searchQuery);
    }).toList();

    if (filteredManagers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No site managers found'
                  : 'No managers match your search',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredManagers.length,
      itemBuilder: (context, index) {
        final manager = filteredManagers[index];
        final isSelected = state.selectedIds.contains(manager.id);

        return _ManagerTile(
          manager: manager,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(siteManagerSelectionProvider(widget.projectId).notifier)
                .toggleManager(manager.id);
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final success = await ref
        .read(siteManagerSelectionProvider(widget.projectId).notifier)
        .saveAssignments();

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignments saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Manager tile widget
class _ManagerTile extends StatelessWidget {
  final SiteManagerModel manager;
  final bool isSelected;
  final VoidCallback onTap;

  const _ManagerTile({
    required this.manager,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: isSelected
                    ? AppColors.primary
                    : AppColors.siteManager.withValues(alpha: 0.1),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(
                        (manager.fullName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.siteManager,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (manager.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            manager.phone!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Checkbox indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

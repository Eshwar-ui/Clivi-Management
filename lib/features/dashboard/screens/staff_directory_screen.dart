import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';

import '../../auth/providers/auth_repository_provider.dart';
import '../../auth/data/models/user_profile_model.dart';

/// Staff Directory Screen - Admin only
/// Lists all site managers with phone dial functionality
class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteManagersAsync = ref.watch(siteManagersListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Staff Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add site manager',
            onPressed: () =>
                Navigator.pushNamed(context, '/admin/site-managers/add'),
          ),
        ],
      ),
      body: siteManagersAsync.when(
        loading: () => const LoadingWidget(message: 'Loading staff...'),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(siteManagersListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (managers) => managers.isEmpty
            ? _buildEmptyState(context)
            : _buildStaffList(context, ref, managers),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No site managers yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add site managers from the button above',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(
    BuildContext context,
    WidgetRef ref,
    List<UserProfileModel> managers,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(siteManagersListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: managers.length,
        itemBuilder: (context, index) {
          final manager = managers[index];
          return _StaffCard(manager: manager);
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UserProfileModel manager;

  const _StaffCard({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.siteManager.withValues(alpha: 0.2),
          child: Text(
            (manager.fullName ?? 'U')[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.siteManager,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          manager.fullName ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (manager.phone != null)
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    manager.phone!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.siteManager.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                manager.role.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.siteManager,
                ),
              ),
            ),
          ],
        ),
        trailing: manager.phone != null
            ? IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _makePhoneCall(context, manager.phone!),
              )
            : null,
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Cannot make call to $phone')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

/// Provider for list of site managers
final siteManagersListProvider = FutureProvider<List<UserProfileModel>>((
  ref,
) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getUsersByRole('site_manager');
});

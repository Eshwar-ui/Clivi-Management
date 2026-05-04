import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/current_project_provider.dart';
// Note: You'll likely need a provider that lists all projects too.
// For now, I'll assume we pass the list in or fetch it here.
// I'll make it accepting a list or using a provider if one exists.
// Actually, usually there's a projectsProvider. I'll assume one exists in features/projects/providers/projects_provider.dart
// But to avoid assumption errors, I'll make it purely UI + CurrentProject provider for now,
// or wait to see if I need to use a specific provider.
// I'll make it simple: It displays the current project and allows picking if implemented.

class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProject = ref.watch(currentProjectProvider);

    return InkWell(
      onTap: () {
        // Navigate to project list or show bottom sheet to switch
        context.push('/projects'); // Assuming a route
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              currentProject?.name ?? 'Select Project',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

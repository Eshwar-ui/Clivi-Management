import 'package:flutter/material.dart';

/// Breadcrumb navigation widget for blueprint screens
/// Shows: Project Name / Blueprint / Folder Name
class BlueprintBreadcrumb extends StatelessWidget {
  final String projectName;
  final String? folderName;

  const BlueprintBreadcrumb({
    super.key,
    required this.projectName,
    this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            projectName,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            ' / ',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
          ),
          Text(
            'Blueprint',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          if (folderName != null) ...[
            Text(
              ' / ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              ),
            ),
            Text(
              folderName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

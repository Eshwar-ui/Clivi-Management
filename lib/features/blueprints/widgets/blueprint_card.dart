import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/blueprint_model.dart';

/// A card widget that displays blueprint file information
/// Matches the design with document icon, title, metadata, and view action
class BlueprintCard extends StatelessWidget {
  final Blueprint blueprint;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BlueprintCard({
    super.key,
    required this.blueprint,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = blueprint.fileName.toLowerCase().endsWith('.pdf');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Document Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPdf
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.blue : Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File name (title)
                    Text(
                      _getDisplayName(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Metadata row
                    Row(
                      children: [
                        // File type
                        Text(
                          _getFileType(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),

                        // Admin badge
                        if (blueprint.isAdminOnly) ...[
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Admin',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Date
                        Text(
                          ' • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(blueprint.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete icon (if onDelete is provided)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: Colors.red[400],
                      tooltip: 'Delete',
                    ),
                  // View icon
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: onTap,
                    color: Colors.grey[600],
                    tooltip: 'View',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get display name - use folder name as the main title
  String _getDisplayName() {
    return blueprint.folderName;
  }

  /// Get file type from extension
  String _getFileType() {
    final name = blueprint.fileName.toLowerCase();
    if (name.endsWith('.pdf')) {
      return 'PDF';
    } else if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return 'Image';
    }
    return 'File';
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}

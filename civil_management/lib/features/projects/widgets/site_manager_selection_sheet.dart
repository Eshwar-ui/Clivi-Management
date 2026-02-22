import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';

class SiteManagerSelectionSheet extends ConsumerStatefulWidget {
  final Set<String> initialSelectedIds;

  const SiteManagerSelectionSheet({
    super.key,
    required this.initialSelectedIds,
  });

  @override
  ConsumerState<SiteManagerSelectionSheet> createState() =>
      _SiteManagerSelectionSheetState();
}

class _SiteManagerSelectionSheetState
    extends ConsumerState<SiteManagerSelectionSheet> {
  late Set<String> _selectedIds;
  List<SiteManagerModel> _managers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    try {
      final repository = ref.read(projectRepositoryProvider);
      final managers = await repository.getSiteManagers();
      if (mounted) {
        setState(() {
          _managers = managers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Site Managers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            Expanded(child: Center(child: LoadingIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(child: InlineErrorWidget(message: _error!)),
            )
          else if (_managers.isEmpty)
            const Expanded(child: Center(child: Text('No site managers found')))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _managers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final manager = _managers[index];
                  final isSelected = _selectedIds.contains(manager.id);
                  return _buildManagerTile(manager, isSelected);
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: 'Done (${_selectedIds.length} Selected)',
              onPressed: () {
                Navigator.pop(context, _selectedIds); // Return selected IDs
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerTile(SiteManagerModel manager, bool isSelected) {
    return InkWell(
      onTap: () => _toggleSelection(manager.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey[200],
              child: Text(
                manager.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (manager.phone != null)
                    Text(
                      manager.phone!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

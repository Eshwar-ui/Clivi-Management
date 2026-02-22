import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';

/// A generic searchable dropdown that allows adding a new item if not found.
class SearchableDropdownWithCreate<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final Future<T> Function(String)? onAdd;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isLoading;

  const SearchableDropdownWithCreate({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    this.onAdd,
    required this.onChanged,
    this.value,
    this.hint,
    this.validator,
    this.isLoading = false,
  });

  @override
  State<SearchableDropdownWithCreate<T>> createState() =>
      _SearchableDropdownWithCreateState<T>();
}

class _SearchableDropdownWithCreateState<T>
    extends State<SearchableDropdownWithCreate<T>> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _searchController.text = widget.itemLabelBuilder(widget.value as T);
    }
  }

  @override
  void didUpdateWidget(covariant SearchableDropdownWithCreate<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value != null) {
        _searchController.text = widget.itemLabelBuilder(widget.value as T);
      } else {
        _searchController.clear();
      }
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 5),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: _DropdownList<T>(
                  items: widget.items,
                  itemLabelBuilder: widget.itemLabelBuilder,
                  searchQuery: _searchController.text,
                  onSelect: (item) {
                    _selectItem(item);
                  },
                  onAdd: widget.onAdd != null
                      ? (query) async {
                          _removeOverlay();
                          // Show loading or optimistic update?
                          // For now, call the future
                          try {
                            final newItem = await widget.onAdd!(query);
                            _selectItem(newItem);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding item: $e'),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _selectItem(T item) {
    _searchController.text = widget.itemLabelBuilder(item);
    widget.onChanged(item);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _searchController,
            label: widget.label,
            hintText: widget.hint,
            validator: (val) => widget.validator?.call(widget.value),
            readOnly: false, // Allow typing to search
            suffixIcon: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    ),
                    onPressed: _toggleDropdown,
                  ),
            onChanged: (val) {
              if (!_isOpen) _showOverlay();
              // Force rebuild of overlay to filter items
              _overlayEntry?.markNeedsBuild();
            },
            onTap: () {
              if (!_isOpen) _showOverlay();
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final String searchQuery;
  final Function(T) onSelect;
  final Function(String)? onAdd;

  const _DropdownList({
    required this.items,
    required this.itemLabelBuilder,
    required this.searchQuery,
    required this.onSelect,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = searchQuery.toLowerCase().trim();

    final filteredItems = items.where((item) {
      return itemLabelBuilder(item).toLowerCase().contains(normalizedQuery);
    }).toList();

    // Check if exact match exists
    final exactMatchExists = filteredItems.any(
      (item) => itemLabelBuilder(item).toLowerCase() == normalizedQuery,
    );

    // Check if we should show "Add" option
    // Show if onAdd is provided AND query is not empty AND no exact match found
    final showAddOption =
        onAdd != null && normalizedQuery.isNotEmpty && !exactMatchExists;

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: filteredItems.length + (showAddOption ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index < filteredItems.length) {
          final item = filteredItems[index];
          return ListTile(
            title: Text(itemLabelBuilder(item)),
            onTap: () => onSelect(item),
          );
        } else {
          return ListTile(
            leading: const Icon(Icons.add, color: AppColors.primary),
            title: Text('Add "$searchQuery"'),
            onTap: onAdd != null ? () => onAdd!(searchQuery) : null,
          );
        }
      },
    );
  }
}

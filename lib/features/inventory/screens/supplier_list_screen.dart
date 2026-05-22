import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/loading_widget.dart';
import '../data/models/supplier_model.dart';
import '../providers/inventory_provider.dart';

/// Supplier List Screen - Manage material vendors
class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSupplierDialog(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: suppliersAsync.when(
        loading: () => const LoadingWidget(message: 'Loading suppliers...'),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (suppliers) {
          final filtered = _searchQuery.isEmpty
              ? suppliers
              : suppliers.where((s) {
                  final name = s.name.toLowerCase();
                  final cat = s.category?.toLowerCase() ?? '';
                  final phone = s.phone?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      cat.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

          return filtered.isEmpty
              ? _buildEmptyState(context)
              : _buildSupplierList(context, ref, filtered);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No suppliers yet' : 'No results found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add material vendors for better tracking'
                : 'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(
    BuildContext context,
    WidgetRef ref,
    List<SupplierModel> suppliers,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(suppliersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suppliers.length,
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return _SupplierCard(
            supplier: supplier,
            onTap: () => _showSupplierDetail(context, ref, supplier),
            onEdit: () => _showEditSupplierDialog(context, ref, supplier),
            onDelete: () => _confirmDelete(context, ref, supplier),
          );
        },
      ),
    );
  }

  void _showSupplierDetail(
    BuildContext context,
    WidgetRef ref,
    SupplierModel supplier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SupplierDetailSheet(
        supplier: supplier,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditSupplierDialog(context, ref, supplier);
        },
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SupplierFormSheet(
        onSave: (supplier) async {
          final repository = ref.read(inventoryRepositoryProvider);
          await repository.addSupplier(supplier);
          ref.invalidate(suppliersProvider);
        },
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    WidgetRef ref,
    SupplierModel supplier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SupplierFormSheet(
        supplier: supplier,
        onSave: (updated) async {
          final repository = ref.read(inventoryRepositoryProvider);
          await repository.updateSupplier(supplier.id, updated.toJson());
          ref.invalidate(suppliersProvider);
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SupplierModel supplier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to remove "${supplier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final repository = ref.read(inventoryRepositoryProvider);
                await repository.deleteSupplier(supplier.id);
                ref.invalidate(suppliersProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SupplierDetailSheet extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback? onEdit;

  const _SupplierDetailSheet({required this.supplier, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (supplier.category != null)
                        Text(
                          supplier.category!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.person_outline, 'Contact', supplier.contactPerson),
            _detailRow(Icons.phone_outlined, 'Phone', supplier.phone),
            _detailRow(Icons.email_outlined, 'Email', supplier.email),
            _detailRow(
              Icons.location_on_outlined,
              'Address',
              supplier.address,
            ),
            _detailRow(Icons.notes_outlined, 'Notes', supplier.notes),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            Icons.business,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.category != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  supplier.category!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (supplier.contactPerson != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(supplier.contactPerson!),
              ),
            if (supplier.phone != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  supplier.phone!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}

class _SupplierFormSheet extends StatefulWidget {
  final SupplierModel? supplier;
  final Future<void> Function(SupplierModel) onSave;

  const _SupplierFormSheet({this.supplier, required this.onSave});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _contactController = TextEditingController(
      text: widget.supplier?.contactPerson ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.supplier?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
    _notesController = TextEditingController(
      text: widget.supplier?.notes ?? '',
    );
    _selectedCategory = widget.supplier?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Supplier' : 'Add Supplier',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: SupplierCategories.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update' : 'Add Supplier'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supplier = SupplierModel(
        id: widget.supplier?.id ?? '',
        name: _nameController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.onSave(supplier);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

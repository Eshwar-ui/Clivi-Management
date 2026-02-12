import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/data/models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_repository_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../data/models/bill_model.dart';
import '../providers/bill_provider.dart';

final approvalQueueSiteManagersProvider =
    FutureProvider<List<UserProfileModel>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUsersByRole('site_manager');
});

class AdminApprovalQueueScreen extends ConsumerStatefulWidget {
  const AdminApprovalQueueScreen({super.key});

  @override
  ConsumerState<AdminApprovalQueueScreen> createState() =>
      _AdminApprovalQueueScreenState();
}

class _AdminApprovalQueueScreenState
    extends ConsumerState<AdminApprovalQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedProjectId;
  String? _selectedManagerId;
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _showCompleted => _tabController.index == 1;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin =
        authState.role == UserRole.admin || authState.role == UserRole.superAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Queue')),
        body: const Center(child: Text('Only admin can access this screen.')),
      );
    }

    final billsAsync = ref.watch(dashboardBillsCombinedProvider(false));
    final projectsState = ref.watch(projectListProvider);
    final siteManagersAsync = ref.watch(approvalQueueSiteManagersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Queue'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(projectsState, siteManagersAsync),
          Expanded(
            child: billsAsync.when(
              data: (bills) {
                final filtered = _applyFilters(bills);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _showCompleted
                          ? 'No completed bills for selected filters'
                          : 'No pending bills for selected filters',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final bill = filtered[index];
                    return _ApprovalQueueCard(
                      bill: bill,
                      onReview: !bill.status.isCompleted
                          ? () => _showApprovalDialog(bill)
                          : null,
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(message: 'Loading queue...'),
              error: (err, st) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(dashboardBillsCombinedProvider(false)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    ProjectListState projectsState,
    AsyncValue<List<UserProfileModel>> managersAsync,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _selectedProjectId,
            decoration: const InputDecoration(
              labelText: 'Project',
              prefixIcon: Icon(Icons.business),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Projects'),
              ),
              ...projectsState.projects.map(
                (project) => DropdownMenuItem<String?>(
                  value: project.id,
                  child: Text(project.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedProjectId = value);
            },
          ),
          const SizedBox(height: 10),
          managersAsync.when(
            data: (managers) {
              return DropdownButtonFormField<String?>(
                initialValue: _selectedManagerId,
                decoration: const InputDecoration(
                  labelText: 'Site Manager',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Site Managers'),
                  ),
                  ...managers.map(
                    (manager) => DropdownMenuItem<String?>(
                      value: manager.id,
                      child: Text(manager.fullName ?? manager.email ?? '-'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedManagerId = value);
                },
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 1),
            error: (_, _) => Text(
              'Failed to load site managers',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDateRange,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date Range',
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BillModel> _applyFilters(List<BillModel> bills) {
    final startDate = DateTime(
      _dateRange.start.year,
      _dateRange.start.month,
      _dateRange.start.day,
    );
    final endDate = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
      23,
      59,
      59,
    );

    return bills.where((bill) {
      final isCompleted = bill.status.isCompleted;
      if (_showCompleted != isCompleted) {
        return false;
      }

      if (_selectedProjectId != null && bill.projectId != _selectedProjectId) {
        return false;
      }

      final raisedBy = bill.raisedBy ?? bill.createdBy;
      if (_selectedManagerId != null && raisedBy != _selectedManagerId) {
        return false;
      }

      final billDate = DateTime(
        bill.billDate.year,
        bill.billDate.month,
        bill.billDate.day,
      );
      return !billDate.isBefore(startDate) && !billDate.isAfter(endDate);
    }).toList()
      ..sort((a, b) => b.billDate.compareTo(a.billDate));
  }

  Future<void> _pickDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (selected != null) {
      setState(() => _dateRange = selected);
    }
  }

  Future<void> _showApprovalDialog(BillModel bill) async {
    PaymentStatus selectedPaymentStatus = bill.paymentStatus;
    bool markCompleted = bill.status.isCompleted;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveApproval() async {
              setModalState(() => isSaving = true);
              final success = await ref
                  .read(billControllerProvider.notifier)
                  .updateBillApproval(
                    billId: bill.id,
                    paymentStatus: selectedPaymentStatus,
                    markCompleted: markCompleted,
                  );

              if (!mounted) return;
              setModalState(() => isSaving = false);

              if (success) {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Bill updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Failed to update bill')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approve Bill',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bill.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PaymentStatus>(
                    initialValue: selectedPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Decision',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PaymentStatus.needToPay,
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: PaymentStatus.advance,
                        child: Text('Will Pay'),
                      ),
                      DropdownMenuItem(
                        value: PaymentStatus.fullPaid,
                        child: Text('Paid'),
                      ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setModalState(() => selectedPaymentStatus = value);
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: markCompleted,
                    onChanged: isSaving
                        ? null
                        : (value) => setModalState(() => markCompleted = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Completed'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveApproval,
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Update'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ApprovalQueueCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onReview;

  const _ApprovalQueueCard({
    required this.bill,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '₹${bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${bill.projectName ?? '-'}  |  ${DateFormat('dd MMM yyyy').format(bill.billDate)}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Raised By: ${bill.createdByName ?? bill.raisedBy ?? '-'}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusPill(
                  label: bill.status.isCompleted ? 'Completed' : 'Pending',
                  color: bill.status.isCompleted ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: bill.paymentStatus.label,
                  color: AppColors.info,
                ),
                const Spacer(),
                if (onReview != null)
                  OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Review'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/bill_model.dart';
import '../providers/bill_provider.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  bool get _showCompletedTab => _tabController.index == 1;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role;
    final isSiteManager = role == UserRole.siteManager;
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    final billsAsync = ref.watch(dashboardBillsCombinedProvider(isSiteManager));
    final billsData = billsAsync.valueOrNull ?? const <BillModel>[];
    final pendingCount = billsData
        .where((bill) => !bill.status.isCompleted)
        .length;
    final completedCount = billsData
        .where((bill) => bill.status.isCompleted)
        .length;

    return Scaffold(
      floatingActionButton: isSiteManager
          ? FloatingActionButton(
              onPressed: () => context.push('/bills/create'),
              child: const Icon(Icons.add),
            )
          : isAdmin
          ? FloatingActionButton(
              child: Icon(Icons.playlist_add_check_circle_outlined),
              onPressed: () => context.push('/bills/approval-queue'),
            )
          : null,

      appBar: CustomAppBar(
        title: Text(
          'Raise',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        showBackButton: false,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedFilterDate != null
                                ? DateFormat(
                                    'dd-MM-yyyy',
                                  ).format(_selectedFilterDate!)
                                : 'Select Date',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_selectedFilterDate != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedFilterDate = null),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    tabs: [
                      _buildTab('Pending', pendingCount),
                      _buildTab('Completed', completedCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: billsAsync.when(
        data: (bills) {
          final filteredBills = bills.where((bill) {
            bool matchesDate = true;
            if (_selectedFilterDate != null) {
              matchesDate =
                  bill.billDate.year == _selectedFilterDate!.year &&
                  bill.billDate.month == _selectedFilterDate!.month &&
                  bill.billDate.day == _selectedFilterDate!.day;
            }

            if (_showCompletedTab) {
              return bill.status.isCompleted && matchesDate;
            }
            return !bill.status.isCompleted && matchesDate;
          }).toList()..sort((a, b) => b.billDate.compareTo(a.billDate));

          return _buildBillList(
            bills: filteredBills,
            isAdmin: isAdmin,
            isSiteManager: isSiteManager,
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bills...'),
        error: (err, stack) => AppErrorWidget(
          message: err.toString(),
          onRetry: () =>
              ref.refresh(dashboardBillsStreamProvider(isSiteManager)),
        ),
      ),
      // floatingActionButton: isSiteManager
      //     ? FloatingActionButton(
      //         onPressed: () => context.push('/bills/create'),
      //         child: const Icon(Icons.add),
      //       )
      //     : isAdmin
      //         ? FloatingActionButton(
      //             onPressed: () => context.push('/bills/approval-queue'),
      //             child: const Icon(Icons.playlist_add_check_circle_outlined),
      //           )
      //         : null,
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(child: Text('$label($count)'));
  }

  Widget _buildBillList({
    required List<BillModel> bills,
    required bool isAdmin,
    required bool isSiteManager,
  }) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _showCompletedTab ? 'No completed bills' : 'No pending bills',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final groupedBills = <String, List<BillModel>>{};
    for (final bill in bills) {
      final dateKey = _getDateKey(bill.billDate);
      groupedBills.putIfAbsent(dateKey, () => []);
      groupedBills[dateKey]!.add(bill);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedBills.length,
      itemBuilder: (context, index) {
        final dateKey = groupedBills.keys.elementAt(index);
        final dateBills = groupedBills[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...dateBills.map(
              (bill) => _BillCard(
                bill: bill,
                onTap: isAdmin && !bill.status.isCompleted
                    ? () => _showAdminApprovalDialog(bill)
                    : null,
                canEdit: (isSiteManager && !bill.status.isCompleted) || isAdmin,
                canDelete: isAdmin,
                onMenuAction: (action) {
                  switch (action) {
                    case _BillMenuAction.edit:
                      _showEditBillDialog(bill);
                      break;
                    case _BillMenuAction.delete:
                      _confirmDeleteBill(bill);
                      break;
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  void _refreshBillData() {
    ref.invalidate(dashboardBillsProvider);
    ref.invalidate(dashboardBillsStreamProvider);
    ref.invalidate(dashboardBillsCombinedProvider);
    ref.invalidate(billsProvider);
    ref.invalidate(billsStreamProvider);
    ref.invalidate(billsCombinedProvider);
    ref.invalidate(paginatedPendingBillsProvider);
  }

  Future<void> _showEditBillDialog(BillModel bill) async {
    final titleController = TextEditingController(text: bill.title);
    final amountController = TextEditingController(
      text: bill.amount.toStringAsFixed(2),
    );
    final vendorController = TextEditingController(text: bill.vendorName ?? '');
    final descriptionController = TextEditingController(
      text: bill.description ?? '',
    );

    BillType selectedType = bill.type;
    PaymentType selectedPaymentType = bill.paymentType ?? PaymentType.cash;
    PaymentStatus selectedPaymentStatus = bill.paymentStatus;
    DateTime selectedBillDate = bill.billDate;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveEdit() async {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              if (title.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Enter valid title and amount')),
                );
                return;
              }

              setModalState(() => isSaving = true);
              final success = await ref
                  .read(billControllerProvider.notifier)
                  .updateBill(
                    billId: bill.id,
                    updates: {
                      'title': title,
                      'amount': amount,
                      'bill_type': selectedType.value,
                      'vendor_name': vendorController.text.trim().isEmpty
                          ? null
                          : vendorController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'payment_type': selectedPaymentType.value,
                      'payment_status': selectedPaymentStatus.value,
                      'bill_date': selectedBillDate
                          .toIso8601String()
                          .split('T')
                          .first,
                    },
                  );
              if (!mounted) return;

              setModalState(() => isSaving = false);
              if (success) {
                _refreshBillData();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Bill updated successfully')),
                );
              } else {
                final state = ref.read(billControllerProvider);
                final errorMessage = state.hasError
                    ? state.error.toString()
                    : 'Failed to update bill';
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(errorMessage)));
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Bill',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Bill Title',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<BillType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Bill Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: BillType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setModalState(() => selectedType = value);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentStatus>(
                      initialValue: selectedPaymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        prefixIcon: Icon(Icons.pending_actions_outlined),
                      ),
                      items: PaymentStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedPaymentStatus = value,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentType>(
                      initialValue: selectedPaymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: PaymentType.values
                          .map(
                            (paymentType) => DropdownMenuItem(
                              value: paymentType,
                              child: Text(paymentType.label),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedPaymentType = value,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedBillDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => selectedBillDate = picked);
                              }
                            },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Bill Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat('dd-MM-yyyy').format(selectedBillDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: vendorController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor Name',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveEdit,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteBill(BillModel bill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Delete "${bill.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final success = await ref
        .read(billControllerProvider.notifier)
        .deleteBill(bill.id);
    if (!mounted) return;

    if (success) {
      _refreshBillData();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Bill deleted successfully' : 'Failed to delete bill',
        ),
      ),
    );
  }

  Future<void> _showAdminApprovalDialog(BillModel bill) async {
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
                _refreshBillData();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Bill updated successfully')),
                );
              } else {
                final state = ref.read(billControllerProvider);
                final errorMessage = state.hasError
                    ? state.error.toString()
                    : 'Failed to update bill';
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
                        value: PaymentStatus.halfPaid,
                        child: Text('Half Paid'),
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
                              setModalState(
                                () => selectedPaymentStatus = value,
                              );
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
                    subtitle: const Text(
                      'Completed bills move to site manager Completed tab',
                    ),
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

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<_BillMenuAction>? onMenuAction;

  const _BillCard({
    required this.bill,
    this.onTap,
    this.canEdit = false,
    this.canDelete = false,
    this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd-MM-yyyy').format(bill.billDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${bill.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bill.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Payment Type : ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: bill.paymentStatus.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Raised By : ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: bill.raisedByName ?? bill.createdByName ?? bill.vendorName ?? 'Staff',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(
                    label: bill.status.isCompleted ? 'Completed' : 'Pending',
                    color: bill.status.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: bill.paymentStatus.label,
                    color: AppColors.info,
                  ),
                  const Spacer(),
                  if (canEdit || canDelete)
                    PopupMenuButton<_BillMenuAction>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: onMenuAction,
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<_BillMenuAction>>[];
                        if (canEdit) {
                          items.add(
                            const PopupMenuItem(
                              value: _BillMenuAction.edit,
                              child: Text('Edit'),
                            ),
                          );
                        }
                        if (canDelete) {
                          items.add(
                            const PopupMenuItem(
                              value: _BillMenuAction.delete,
                              child: Text('Delete'),
                            ),
                          );
                        }
                        return items;
                      },
                    ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BillMenuAction { edit, delete }

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

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

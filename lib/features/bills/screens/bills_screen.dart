import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
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

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) setState(() {});
  }

  bool get _showCompletedTab => _tabController.index == 1;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedFilterDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role;
    final isSiteManager = role == UserRole.siteManager;
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    final billsAsync = ref.watch(dashboardBillsCombinedProvider(isSiteManager));
    final billsData = billsAsync.valueOrNull ?? const <BillModel>[];
    final pendingCount =
        billsData.where((b) => !b.status.isCompleted).length;
    final completedCount =
        billsData.where((b) => b.status.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(Size(constraints.maxWidth, constraints.maxHeight));

          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.isDesktop ? 32 : 20,
                    r.isDesktop ? 28 : 16,
                    r.isDesktop ? 32 : 20,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: r.maxContentWidth),
                      child: _buildHeader(
                        context,
                        isAdmin: isAdmin,
                        isSiteManager: isSiteManager,
                        pendingCount: pendingCount,
                        completedCount: completedCount,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: billsAsync.when(
                    data: (bills) {
                      final filtered = bills.where((bill) {
                        bool matchesDate = true;
                        if (_selectedFilterDate != null) {
                          matchesDate =
                              bill.billDate.year ==
                                      _selectedFilterDate!.year &&
                                  bill.billDate.month ==
                                      _selectedFilterDate!.month &&
                                  bill.billDate.day ==
                                      _selectedFilterDate!.day;
                        }
                        return _showCompletedTab
                            ? bill.status.isCompleted && matchesDate
                            : !bill.status.isCompleted && matchesDate;
                      }).toList()
                        ..sort(
                            (a, b) => b.billDate.compareTo(a.billDate));

                      return _buildBillList(
                        bills: filtered,
                        isAdmin: isAdmin,
                        isSiteManager: isSiteManager,
                        r: r,
                      );
                    },
                    loading: () =>
                        const LoadingWidget(message: 'Loading bills...'),
                    error: (err, _) => AppErrorWidget(
                      message: err.toString(),
                      onRetry: _refreshBillData,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(
    BuildContext context, {
    required bool isAdmin,
    required bool isSiteManager,
    required int pendingCount,
    required int completedCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + actions
        Row(
          children: [
            Text(
              'Bills',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            // Date filter
            _DateFilterChip(
              selectedDate: _selectedFilterDate,
              onTap: _pickDate,
              onClear: () => setState(() => _selectedFilterDate = null),
            ),
            if (isSiteManager) ...[
              const SizedBox(width: 10),
              _HeaderButton(
                icon: Icons.add_rounded,
                label: 'New Bill',
                filled: true,
                onTap: () => context.push('/bills/create'),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(width: 10),
              _HeaderButton(
                icon: Icons.checklist_rounded,
                label: 'Approvals',
                filled: true,
                onTap: () => context.push('/bills/approval-queue'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Tab bar
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.all(3),
            tabs: [
              Tab(
                child: Text('Pending  $pendingCount'),
              ),
              Tab(
                child: Text('Completed  $completedCount'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bill List ──

  Widget _buildBillList({
    required List<BillModel> bills,
    required bool isAdmin,
    required bool isSiteManager,
    required R r,
  }) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 28, color: AppColors.textHint),
            ),
            const SizedBox(height: 14),
            Text(
              _showCompletedTab ? 'No completed bills' : 'No pending bills',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<BillModel>>{};
    for (final bill in bills) {
      final key = _getDateKey(bill.billDate);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(bill);
    }

    final columns = r.w >= 1180
        ? 3
        : r.w >= 760
            ? 2
            : 1;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: r.isDesktop ? 32 : 20,
            vertical: 8,
          ),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final dateKey = grouped.keys.elementAt(index);
            final dateBills = grouped[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Text(
                    dateKey.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (columns == 1)
                  ...dateBills.map(
                    (bill) => _buildBillCard(
                      bill,
                      isAdmin: isAdmin,
                      isSiteManager: isSiteManager,
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dateBills.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 190,
                    ),
                    itemBuilder: (context, i) => _buildBillCard(
                      dateBills[i],
                      isAdmin: isAdmin,
                      isSiteManager: isSiteManager,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillCard(
    BillModel bill, {
    required bool isAdmin,
    required bool isSiteManager,
  }) {
    return _BillCard(
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

  // ── Dialogs (unchanged logic) ──

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

    try {
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
                    const SnackBar(
                      content: Text('Enter valid title and amount'),
                    ),
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
                        'description':
                            descriptionController.text.trim().isEmpty
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
                if (sheetContext.mounted) {
                  setModalState(() => isSaving = false);
                }
                if (success) {
                  _refreshBillData();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Bill updated successfully'),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    final state = ref.read(billControllerProvider);
                    final errorMessage = state.hasError
                        ? state.error.toString()
                        : 'Failed to update bill';
                    ScaffoldMessenger.of(this.context)
                        .showSnackBar(SnackBar(content: Text(errorMessage)));
                  }
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
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t.label)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) {
                                if (v != null) {
                                  setModalState(() => selectedType = v);
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
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) {
                                if (v != null) {
                                  setModalState(
                                      () => selectedPaymentStatus = v);
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<PaymentType>(
                        initialValue: selectedPaymentType,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          prefixIcon:
                              Icon(Icons.account_balance_wallet_outlined),
                        ),
                        items: PaymentType.values
                            .map((p) => DropdownMenuItem(
                                value: p, child: Text(p.label)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) {
                                if (v != null) {
                                  setModalState(
                                      () => selectedPaymentType = v);
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
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(
                                      () => selectedBillDate = picked);
                                }
                              },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Bill Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(DateFormat('dd-MM-yyyy')
                              .format(selectedBillDate)),
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
                                      strokeWidth: 2),
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
    } finally {
      titleController.dispose();
      amountController.dispose();
      vendorController.dispose();
      descriptionController.dispose();
    }
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

    final success =
        await ref.read(billControllerProvider.notifier).deleteBill(bill.id);
    if (!mounted) return;

    if (success) _refreshBillData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Bill deleted successfully' : 'Failed to delete bill'),
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
              if (sheetContext.mounted) {
                setModalState(() => isSaving = false);
              }
              if (success) {
                _refreshBillData();
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                        content: Text('Bill updated successfully')),
                  );
                }
              } else {
                if (mounted) {
                  final state = ref.read(billControllerProvider);
                  final errorMessage = state.hasError
                      ? state.error.toString()
                      : 'Failed to update bill';
                  ScaffoldMessenger.of(this.context)
                      .showSnackBar(SnackBar(content: Text(errorMessage)));
                }
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
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bill.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                          child: Text('Pending')),
                      DropdownMenuItem(
                          value: PaymentStatus.advance,
                          child: Text('Will Pay')),
                      DropdownMenuItem(
                          value: PaymentStatus.halfPaid,
                          child: Text('Half Paid')),
                      DropdownMenuItem(
                          value: PaymentStatus.fullPaid,
                          child: Text('Paid')),
                    ],
                    onChanged: isSaving
                        ? null
                        : (v) {
                            if (v != null) {
                              setModalState(
                                  () => selectedPaymentStatus = v);
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: markCompleted,
                    onChanged: isSaving
                        ? null
                        : (v) => setModalState(() => markCompleted = v),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Completed'),
                    subtitle: const Text(
                        'Completed bills move to Completed tab'),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
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

// ── Bill Card ──

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
    final isCompleted = bill.status.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.borderDark.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: date + amount
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('dd MMM yyyy').format(bill.billDate),
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    Text(
                      '₹${bill.amount.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  bill.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Raised by
                if (bill.raisedByName != null ||
                    bill.createdByName != null ||
                    bill.vendorName != null)
                  Text(
                    bill.raisedByName ??
                        bill.createdByName ??
                        bill.vendorName ??
                        '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),

                // Bottom: chips + menu
                Row(
                  children: [
                    _StatusChip(
                      label: isCompleted ? 'Completed' : 'Pending',
                      color: isCompleted
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
                        icon: Icon(Icons.more_horiz_rounded,
                            color: AppColors.textHint, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: onMenuAction,
                        itemBuilder: (_) {
                          final items = <PopupMenuEntry<_BillMenuAction>>[];
                          if (canEdit) {
                            items.add(const PopupMenuItem(
                                value: _BillMenuAction.edit,
                                child: Text('Edit')));
                          }
                          if (canDelete) {
                            items.add(const PopupMenuItem(
                                value: _BillMenuAction.delete,
                                child: Text('Delete')));
                          }
                          return items;
                        },
                      ),
                    if (onTap != null)
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textHint, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BillMenuAction { edit, delete }

// ── Shared Widgets ──

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateFilterChip({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selectedDate != null
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                selectedDate != null
                    ? DateFormat('dd MMM').format(selectedDate!)
                    : 'Date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedDate != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (selectedDate != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 15, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17,
                  color: filled ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

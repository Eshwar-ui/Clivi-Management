import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/project_provider.dart';
import '../../materials/providers/stock_provider.dart';
import 'package:intl/intl.dart';
import '../../materials/screens/material_receive_screen.dart';
import '../../materials/screens/material_consume_screen.dart';

import '../../machinery/screens/machinery_tab_screen.dart';
import '../../labour/screens/labour_tab_screen.dart';

/// Global provider for the date range filter across operations tabs
final projectDateRangeProvider = StateProvider.autoDispose<DateTimeRange?>(
  (ref) => null,
);

/// Project Operations Screen with Materials, Machinery, and Labor tabs
class ProjectOperationsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectOperationsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectOperationsScreen> createState() =>
      _ProjectOperationsScreenState();
}

class _ProjectOperationsScreenState
    extends ConsumerState<ProjectOperationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailProvider(widget.projectId));
    final projectName = state.project?.name ?? 'Project';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projectName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '$projectName / Operations',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        // DateRangePicker moved to individual tabs, specifically the Materials tab header.
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Machinery'),
            Tab(text: 'Labor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MaterialsTab(projectId: widget.projectId),
          MachineryTabScreen(projectId: widget.projectId),
          LabourTabScreen(projectId: widget.projectId),
        ],
      ),
    );
  }
}

/// Materials Tab showing Logs as primary view
class _MaterialsTab extends ConsumerStatefulWidget {
  final String projectId;

  const _MaterialsTab({required this.projectId});

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _showLogMaterialSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sidebarBackground,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 4,
        ),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Log Material',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Materials History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final dateRange = ref.watch(projectDateRangeProvider);
                    final isFiltered = dateRange != null;
                    return OutlinedButton.icon(
                      onPressed: () async {
                        if (isFiltered) {
                          ref.read(projectDateRangeProvider.notifier).state =
                              null;
                        } else {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDateRange: dateRange,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref.read(projectDateRangeProvider.notifier).state =
                                picked;
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(
                          color: isFiltered
                              ? AppColors.primary
                              : AppColors.borderDark,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        backgroundColor: isFiltered
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.transparent,
                      ),
                      icon: Icon(
                        isFiltered ? Icons.clear : Icons.date_range,
                        size: 16,
                        color: isFiltered ? AppColors.primary : Colors.black,
                      ),
                      label: Text(
                        isFiltered ? 'Clear Filter' : 'Select Date',
                        style: TextStyle(
                          color: isFiltered ? AppColors.primary : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _MaterialSummaryHeader(projectId: widget.projectId),
          Expanded(child: _MaterialsHistoryList(projectId: widget.projectId)),
        ],
      ),
    );
  }

  void _showLogMaterialSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Material',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose operation type',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  'Receive Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Log newly arrived supplies to site'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (modalCtx) => Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: MaterialReceiveScreen(
                        projectId: widget.projectId,
                        isEmbedded: true,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 32),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_rounded, color: Colors.orange),
                ),
                title: const Text(
                  'Consume Material',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Log material usage for activities'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (modalCtx) => Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: MaterialConsumeScreen(
                        projectId: widget.projectId,
                        isEmbedded: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaterialSummaryHeader extends ConsumerWidget {
  final String projectId;
  const _MaterialSummaryHeader({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(stockBalanceProvider(projectId));

    return balanceAsync.when(
      data: (stockItems) {
        if (stockItems.isEmpty) return const SizedBox.shrink();

        double steelReceived = 0, steelUsed = 0, steelRemaining = 0;
        double cementReceived = 0, cementUsed = 0, cementRemaining = 0;

        for (var item in stockItems) {
          final name = (item['name'] as String).toLowerCase();
          final received = (item['total_received'] as num).toDouble();
          final used = (item['total_consumed'] as num).toDouble();
          final remaining = (item['current_stock'] as num).toDouble();

          if (name.contains('steel') || name.contains('tmt')) {
            steelReceived += received;
            steelUsed += used;
            steelRemaining += remaining;
          } else if (name.contains('cement')) {
            cementReceived += received;
            cementUsed += used;
            cementRemaining += remaining;
          }
        }

        if (steelReceived == 0 && cementReceived == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.inventory,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Material Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.7),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderDark),
                        ),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Item',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Received',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Used',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Remaining',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    if (steelReceived > 0)
                      _buildTableRow(
                        'Steel',
                        'Tonnes',
                        steelReceived,
                        steelUsed,
                        steelRemaining,
                        Colors.blueGrey,
                      ),
                    if (cementReceived > 0)
                      _buildTableRow(
                        'Cement',
                        'Bags',
                        cementReceived,
                        cementUsed,
                        cementRemaining,
                        Colors.brown,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  TableRow _buildTableRow(
    String name,
    String unit,
    double rec,
    double used,
    double rem,
    Color color,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            '${rec.toStringAsFixed(1)}\n$unit',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            '${used.toStringAsFixed(1)}\n$unit',
            style: const TextStyle(fontSize: 13, color: Colors.orange),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            '${rem.toStringAsFixed(1)}\n$unit',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _MaterialsHistoryList extends ConsumerWidget {
  final String projectId;
  const _MaterialsHistoryList({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(materialLogsProvider(projectId));
    final dateRange = ref.watch(projectDateRangeProvider);

    return logsAsync.when(
      data: (logs) {
        // Filter by date range
        var displayLogs = logs;
        if (dateRange != null) {
          displayLogs = logs.where((log) {
            final logDate = DateTime(
              log.loggedAt.year,
              log.loggedAt.month,
              log.loggedAt.day,
            );
            final start = DateTime(
              dateRange.start.year,
              dateRange.start.month,
              dateRange.start.day,
            );
            final end = DateTime(
              dateRange.end.year,
              dateRange.end.month,
              dateRange.end.day,
            );
            return (logDate.isAtSameMomentAs(start) ||
                    logDate.isAfter(start)) &&
                (logDate.isAtSameMomentAs(end) || logDate.isBefore(end));
          }).toList();
        }

        if (displayLogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No material logs found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding for FAB
          itemCount: displayLogs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = displayLogs[index];
            final isInward = log.logType == 'inward';
            final hasBill =
                isInward && log.billAmount != null && log.billAmount! > 0;
            final isPaid = log.paymentType?.toLowerCase() == 'paid';

            return InkWell(
              onTap: () => _showMaterialLogDetails(context, log, isInward),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isInward
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInward
                            ? Icons.download_rounded
                            : Icons.upload_rounded,
                        color: isInward ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.stockItem?.name ?? 'Unknown Material',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (log.grade != null && log.grade!.isNotEmpty)
                            Text(
                              'GRADE ${log.grade}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isInward
                                      ? (log.supplier?.name ?? 'Unknown Vendor')
                                      : (log.activity ?? 'Consumption'),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (hasBill) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isPaid
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaid
                                        ? Icons.check_circle
                                        : Icons.warning_amber_rounded,
                                    size: 10,
                                    color: isPaid ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '₹${NumberFormat('#,##0').format(log.billAmount)} • ${log.paymentType ?? "Unknown"}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${isInward ? "+" : "-"}${log.quantity.toStringAsFixed(0)} ',
                                style: TextStyle(
                                  color: isInward
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: log.stockItem?.unit ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          DateFormat('MMM dd').format(log.loggedAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showMaterialLogDetails(
    BuildContext context,
    dynamic log,
    bool isInward,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInward ? 'Material Received' : 'Material Consumed',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(log.loggedAt),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              _DetailRow(
                icon: Icons.inventory_2,
                label: 'Material',
                value: log.stockItem?.name ?? 'Unknown',
              ),
              if (log.grade != null && log.grade!.isNotEmpty)
                _DetailRow(
                  icon: Icons.grade,
                  label: 'Grade',
                  value: log.grade!,
                ),
              _DetailRow(
                icon: Icons.scale,
                label: 'Quantity',
                value: '${log.quantity} ${log.stockItem?.unit ?? ''}',
                valueColor: isInward ? Colors.green : Colors.orange,
              ),

              if (isInward) ...[
                const Divider(height: 32),
                _DetailRow(
                  icon: Icons.store,
                  label: 'Vendor',
                  value: log.supplier?.name ?? 'Unknown',
                ),
                if (log.billAmount != null && log.billAmount! > 0)
                  _DetailRow(
                    icon: Icons.receipt_long,
                    label: 'Bill Amount',
                    value: '₹${NumberFormat('#,##0').format(log.billAmount)}',
                  ),
                if (log.paymentType != null && log.paymentType!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.payment,
                    label: 'Payment Status',
                    value: log.paymentType!.toUpperCase(),
                    valueColor: log.paymentType!.toLowerCase() == 'paid'
                        ? Colors.green
                        : Colors.red,
                  ),
              ] else ...[
                const Divider(height: 32),
                _DetailRow(
                  icon: Icons.construction,
                  label: 'Activity',
                  value: log.activity ?? 'N/A',
                ),
              ],

              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const Divider(height: 32),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(log.notes!),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

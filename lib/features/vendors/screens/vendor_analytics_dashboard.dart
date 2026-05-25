import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../data/models/vendor_summary_models.dart';
import '../providers/vendor_analytics_provider.dart';
import '../services/vendor_report_service.dart';

class VendorAnalyticsDashboard extends ConsumerWidget {
  const VendorAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(materialAnalyticsTabProvider);
    final metric = ref.watch(vendorChartMetricProvider);
    final range = ref.watch(vendorAnalyticsDateRangeProvider);

    final request = MaterialVendorAggregatesRequest(
      tab: tab,
      fromDate: range.start,
      toDate: range.end,
    );
    final vendorsAsync = ref.watch(materialVendorAggregatesProvider(request));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (vendors) {
          final sorted = [...vendors]
            ..sort(
              (a, b) =>
                  _metricValue(b, metric).compareTo(_metricValue(a, metric)),
            );
          final topFive = sorted.take(5).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final r = R(Size(constraints.maxWidth, constraints.maxHeight));

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(materialVendorAggregatesProvider(request)),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.isDesktop ? 32 : 20,
                    vertical: r.isDesktop ? 28 : 16,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: r.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'Material Suppliers',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),

                          // Material tabs
                          _MaterialTabs(
                            selected: tab,
                            onChange: (selected) => ref
                                .read(materialAnalyticsTabProvider.notifier)
                                .state = selected,
                          ),
                          const SizedBox(height: 14),

                          // Metric toggle + date range
                          Row(
                            children: [
                              _MetricToggle(
                                selected: metric,
                                onChange: (m) => ref
                                    .read(vendorChartMetricProvider.notifier)
                                    .state = m,
                              ),
                              const Spacer(),
                              _DateRangeLabel(range: range),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Date pickers
                          _MainDateRangePicker(
                            range: range,
                            onPickFrom: () =>
                                _pickFromDate(context, ref, range),
                            onPickTo: () =>
                                _pickToDate(context, ref, range),
                          ),
                          const SizedBox(height: 16),

                          // Chart
                          _SupplierChartCard(
                            vendors: topFive,
                            metric: metric,
                            yTitle: metric == VendorChartMetric.amount
                                ? 'Amount (Rs)'
                                : 'Quantity',
                          ),
                          const SizedBox(height: 24),

                          // Supply details header
                          Row(
                            children: [
                              Text(
                                '${tab.label} Supply Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () async {
                                    await VendorReportService.generateReport(
                                      vendors: sorted,
                                      tab: tab,
                                      fromDate: range.start,
                                      toDate: range.end,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.download_rounded,
                                            size: 15,
                                            color: AppColors.textPrimary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Export',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Vendor list
                          if (sorted.isEmpty)
                            const _EmptyState(
                              'No inward logs found for selected material',
                            )
                          else
                            ...sorted.map(
                              (vendor) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _VendorTile(
                                  aggregate: vendor,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SupplyDetailsScreen(
                                          vendorId: vendor.vendorId,
                                          vendorName: vendor.vendorName,
                                          tab: tab,
                                          fromDate: range.start,
                                          toDate: range.end,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static double _metricValue(
    VendorMaterialAggregate aggregate,
    VendorChartMetric metric,
  ) {
    if (metric == VendorChartMetric.amount) return aggregate.totalAmount;
    return aggregate.quantityForChart;
  }

  void _pickFromDate(
      BuildContext context, WidgetRef ref, DateTimeRange range) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: range.start,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null || !context.mounted) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    final nextEnd = normalized.isAfter(range.end) ? normalized : range.end;
    ref.read(vendorAnalyticsDateRangeProvider.notifier).state =
        DateTimeRange(start: normalized, end: nextEnd);
  }

  void _pickToDate(
      BuildContext context, WidgetRef ref, DateTimeRange range) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: range.end,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null || !context.mounted) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    final nextStart =
        normalized.isBefore(range.start) ? normalized : range.start;
    ref.read(vendorAnalyticsDateRangeProvider.notifier).state =
        DateTimeRange(start: nextStart, end: normalized);
  }
}

// ── Material Tabs ──

class _MaterialTabs extends StatelessWidget {
  final MaterialAnalyticsTab selected;
  final ValueChanged<MaterialAnalyticsTab> onChange;
  const _MaterialTabs({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: MaterialAnalyticsTab.values.map((tab) {
          final isActive = selected == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Metric Toggle ──

class _MetricToggle extends StatelessWidget {
  final VendorChartMetric selected;
  final ValueChanged<VendorChartMetric> onChange;
  const _MetricToggle({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VendorChartMetric.values.map((m) {
        final isActive = selected == m;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => onChange(m),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Text(
                  m == VendorChartMetric.quantity ? 'Qty' : 'Amount',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Date Range ──

class _DateRangeLabel extends StatelessWidget {
  final DateTimeRange range;
  const _DateRangeLabel({required this.range});

  @override
  Widget build(BuildContext context) {
    final days = range.end.difference(range.start).inDays;
    final label =
        days <= 7 ? 'Last 7 days' : DateFormat('dd MMM').format(range.start);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MainDateRangePicker extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  const _MainDateRangePicker({
    required this.range,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DateChip(label: 'From', date: range.start, onTap: onPickFrom)),
        const SizedBox(width: 10),
        Expanded(child: _DateChip(label: 'To', date: range.end, onTap: onPickTo)),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String? label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateChip({this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                '${label != null ? '$label ' : ''}${DateFormat('dd-MM-yyyy').format(date)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chart Card ──

class _SupplierChartCard extends StatelessWidget {
  final List<VendorMaterialAggregate> vendors;
  final VendorChartMetric metric;
  final String yTitle;
  const _SupplierChartCard({
    required this.vendors,
    required this.metric,
    required this.yTitle,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = vendors.isEmpty
        ? 1.0
        : vendors.map((e) => _metricValue(e)).reduce((a, b) => a > b ? a : b) *
            1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  yTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: vendors.isEmpty
                ? const Center(
                    child: Text('No chart data',
                        style: TextStyle(color: Colors.white70)),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxValue,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 5,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withValues(alpha: 0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: maxValue / 5,
                            getTitlesWidget: (value, _) => Text(
                              _axisLabel(value),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= vendors.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _shortName(vendors[i].vendorName),
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: vendors.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: _metricValue(entry.value),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.primary,
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxValue,
                                color:
                                    Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _shortName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? name : words.first;
  }

  double _metricValue(VendorMaterialAggregate aggregate) {
    if (metric == VendorChartMetric.amount) return aggregate.totalAmount;
    return aggregate.quantityForChart;
  }

  String _axisLabel(double value) {
    if (metric == VendorChartMetric.amount) return '${(value / 1000).round()}k';
    return '${value.round()}';
  }
}

// ── Vendor Tile ──

class _VendorTile extends StatelessWidget {
  final VendorMaterialAggregate aggregate;
  final VoidCallback onTap;
  const _VendorTile({required this.aggregate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tag = aggregate.vendorName.trim().isEmpty
        ? 'S'
        : aggregate.vendorName.trim().substring(0, 1).toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.borderDark.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tag,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aggregate.vendorName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aggregate.quantityDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (aggregate.topProjectName != null)
                      Text(
                        'Top: ${aggregate.topProjectName}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
              Text(
                _compactCurrency(aggregate.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-Screens ──

class SupplyDetailsScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final MaterialAnalyticsTab tab;
  final DateTime fromDate;
  final DateTime toDate;

  const SupplyDetailsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.tab,
    required this.fromDate,
    required this.toDate,
  });

  @override
  ConsumerState<SupplyDetailsScreen> createState() =>
      _SupplyDetailsScreenState();
}

class _SupplyDetailsScreenState extends ConsumerState<SupplyDetailsScreen> {
  String? _expandedProjectId;

  @override
  Widget build(BuildContext context) {
    final request = VendorProjectAggregatesRequest(
      vendorId: widget.vendorId,
      tab: widget.tab,
      fromDate: widget.fromDate,
      toDate: widget.toDate,
    );
    final projectsAsync =
        ref.watch(vendorProjectAggregatesProvider(request));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(
          'Supply Details',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        showBackButton: true,
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: _EmptyState('No project-wise supply records'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final project = projects[index];
              final expanded = _expandedProjectId == project.projectId;

              return _ProjectSupplyCard(
                index: index + 1,
                aggregate: project,
                expanded: expanded,
                onToggle: () {
                  setState(() {
                    _expandedProjectId =
                        expanded ? null : project.projectId;
                  });
                },
                onOpenDailyLogs: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectSupplyHistoryScreen(
                        vendorId: widget.vendorId,
                        projectId: project.projectId,
                        projectName: project.projectName,
                        tab: widget.tab,
                        fromDate: widget.fromDate,
                        toDate: widget.toDate,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProjectSupplyHistoryScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String projectId;
  final String projectName;
  final MaterialAnalyticsTab tab;
  final DateTime fromDate;
  final DateTime toDate;

  const ProjectSupplyHistoryScreen({
    super.key,
    required this.vendorId,
    required this.projectId,
    required this.projectName,
    required this.tab,
    required this.fromDate,
    required this.toDate,
  });

  @override
  ConsumerState<ProjectSupplyHistoryScreen> createState() =>
      _ProjectSupplyHistoryScreenState();
}

class _ProjectSupplyHistoryScreenState
    extends ConsumerState<ProjectSupplyHistoryScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
  }

  @override
  Widget build(BuildContext context) {
    final request = VendorProjectDailyLogsRequest(
      vendorId: widget.vendorId,
      projectId: widget.projectId,
      tab: widget.tab,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    final linesAsync = ref.watch(vendorProjectDailyLogsProvider(request));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: Text(
          widget.projectName,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: _DateChip(
                    date: _fromDate,
                    onTap: () async {
                      final picked = await _pickDate(_fromDate);
                      if (picked == null) return;
                      setState(() {
                        _fromDate = picked;
                        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateChip(
                    date: _toDate,
                    onTap: () async {
                      final picked = await _pickDate(_toDate);
                      if (picked == null) return;
                      setState(() {
                        _toDate = picked;
                        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: linesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lines) {
                if (lines.isEmpty) {
                  return const Center(
                    child: _EmptyState(
                        'No inward receive logs in selected range'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) =>
                      _SupplyLineTile(line: lines[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
  }
}

// ── Project Supply Card ──

class _ProjectSupplyCard extends StatelessWidget {
  final int index;
  final VendorProjectAggregate aggregate;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenDailyLogs;

  const _ProjectSupplyCard({
    required this.index,
    required this.aggregate,
    required this.expanded,
    required this.onToggle,
    required this.onOpenDailyLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: onOpenDailyLogs,
                        child: Text(
                          aggregate.projectName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        aggregate.quantityDisplay,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _compactCurrency(aggregate.totalAmount),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              ...aggregate.previewLines.map((line) => _SupplyLineTile(line: line)),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: onOpenDailyLogs,
                  child: const Text('View All',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Supply Line Tile ──

class _SupplyLineTile extends StatelessWidget {
  final VendorSupplyLine line;
  const _SupplyLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.materialName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatQuantity(line.quantity)} ${line.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM dd').format(line.loggedAt),
                style: TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(height: 2),
              Text(
                line.amount > 0 ? _compactCurrency(line.amount) : '--',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ──

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Helpers ──

String _compactCurrency(double value) {
  if (value.abs() >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  }
  if (value.abs() >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  }
  if (value.abs() >= 10000) {
    return '₹${(value / 1000).toStringAsFixed(0)}K';
  }
  return '₹${value.toStringAsFixed(0)}';
}

String _formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toStringAsFixed(0);
  return quantity.toStringAsFixed(2);
}

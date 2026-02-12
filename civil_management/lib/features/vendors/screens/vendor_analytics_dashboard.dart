import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models/vendor_summary_models.dart';
import '../providers/vendor_analytics_provider.dart';

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
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Material Suppliers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
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

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialVendorAggregatesProvider(request)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MaterialTabs(
                    selected: tab,
                    onChange: (selected) {
                      ref.read(materialAnalyticsTabProvider.notifier).state =
                          selected;
                    },
                  ),
                  const SizedBox(height: 12),
                  _MetricToggle(
                    selected: metric,
                    onChange: (m) =>
                        ref.read(vendorChartMetricProvider.notifier).state = m,
                  ),
                  const SizedBox(height: 8),
                  _MainDateRangePicker(
                    range: range,
                    dateLabel: _rangeLabel(range),
                    onPickFrom: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: range.start,
                        firstDate: DateTime(DateTime.now().year - 5),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (picked == null || !context.mounted) return;
                      final normalized = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                      final nextEnd = normalized.isAfter(range.end)
                          ? normalized
                          : range.end;
                      ref
                          .read(vendorAnalyticsDateRangeProvider.notifier)
                          .state = DateTimeRange(
                        start: normalized,
                        end: nextEnd,
                      );
                    },
                    onPickTo: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: range.end,
                        firstDate: DateTime(DateTime.now().year - 5),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (picked == null || !context.mounted) return;
                      final normalized = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                      final nextStart = normalized.isBefore(range.start)
                          ? normalized
                          : range.start;
                      ref
                          .read(vendorAnalyticsDateRangeProvider.notifier)
                          .state = DateTimeRange(
                        start: nextStart,
                        end: normalized,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SupplierChartCard(
                    vendors: topFive,
                    metric: metric,
                    yTitle: metric == VendorChartMetric.amount
                        ? 'Amount (Rs)'
                        : 'Quantity',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${tab.label} Supply Details',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Export',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (sorted.isEmpty)
                    const _EmptyState(
                      'No inward logs found for selected material',
                    )
                  else
                    ...sorted.map(
                      (vendor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorTile(
                          aggregate: vendor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SupplyDetailsScreen(
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
                ],
              ),
            ),
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

  static String _rangeLabel(DateTimeRange range) {
    final days = range.end.difference(range.start).inDays;
    return days <= 7 ? 'Last 7 days' : DateFormat('dd MMM').format(range.start);
  }
}

class _MaterialTabs extends StatelessWidget {
  final MaterialAnalyticsTab selected;
  final ValueChanged<MaterialAnalyticsTab> onChange;

  const _MaterialTabs({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF2F66F5);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabPill(
            label: MaterialAnalyticsTab.steel.label,
            active: selected == MaterialAnalyticsTab.steel,
            activeColor: selectedColor,
            onTap: () => onChange(MaterialAnalyticsTab.steel),
          ),
          _TabPill(
            label: MaterialAnalyticsTab.cement.label,
            active: selected == MaterialAnalyticsTab.cement,
            activeColor: selectedColor,
            onTap: () => onChange(MaterialAnalyticsTab.cement),
          ),
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final VendorChartMetric selected;
  final ValueChanged<VendorChartMetric> onChange;

  const _MetricToggle({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          label: 'Qty',
          active: selected == VendorChartMetric.quantity,
          onTap: () => onChange(VendorChartMetric.quantity),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Amount',
          active: selected == VendorChartMetric.amount,
          onTap: () => onChange(VendorChartMetric.amount),
        ),
      ],
    );
  }
}

class _MainDateRangePicker extends StatelessWidget {
  final DateTimeRange range;
  final String dateLabel;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const _MainDateRangePicker({
    required this.range,
    required this.dateLabel,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MainDateChip(
            label: 'From',
            date: range.start,
            onTap: onPickFrom,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MainDateChip(label: 'To', date: range.end, onTap: onPickTo),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MainDateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _MainDateChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ${DateFormat('dd-MM-yyyy').format(date)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F66F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active
                    ? const Color(0xFF111827)
                    : const Color(0xFF8A9AB2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1736),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1736).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: vendors.isEmpty
                ? const Center(
                    child: Text(
                      'No chart data',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxValue,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 5,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withValues(alpha: 0.08),
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
                              _axisLabel(value, metric),
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
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
                                  style: const TextStyle(
                                    color: Colors.white70,
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
                              width: 14,
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFF2F66F5),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxValue,
                                color: Colors.white.withValues(alpha: 0.07),
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
    if (words.isEmpty) return name;
    return words.first;
  }

  double _metricValue(VendorMaterialAggregate aggregate) {
    if (metric == VendorChartMetric.amount) return aggregate.totalAmount;
    return aggregate.quantityForChart;
  }

  String _axisLabel(double value, VendorChartMetric metric) {
    if (metric == VendorChartMetric.amount) {
      final inK = (value / 1000).round();
      return '${inK}k';
    }
    final rounded = value.round();
    return '$rounded';
  }
}

class _VendorTile extends StatelessWidget {
  final VendorMaterialAggregate aggregate;
  final VoidCallback onTap;

  const _VendorTile({required this.aggregate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final trimmed = aggregate.vendorName.trim();
    final tag = trimmed.isEmpty ? 'S' : trimmed.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F66F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aggregate.quantityDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (aggregate.topProjectName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Top project: ${aggregate.topProjectName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _compactCurrency(aggregate.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final projectsAsync = ref.watch(vendorProjectAggregatesProvider(request));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
        title: const Text(
          'Supply Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
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
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              final expanded = _expandedProjectId == project.projectId;

              return _ProjectSupplyCard(
                index: index + 1,
                aggregate: project,
                expanded: expanded,
                onToggle: () {
                  setState(() {
                    _expandedProjectId = expanded ? null : project.projectId;
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
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
        title: Text(
          widget.projectName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                        if (_fromDate.isAfter(_toDate)) {
                          _toDate = _fromDate;
                        }
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
                        if (_toDate.isBefore(_fromDate)) {
                          _fromDate = _toDate;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: linesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lines) {
                if (lines.isEmpty) {
                  return const Center(
                    child: _EmptyState(
                      'No inward receive logs in selected range',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _SupplyLineTile(line: lines[index]);
                  },
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F66F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF2F66F5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        aggregate.quantityDisplay,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _compactCurrency(aggregate.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.chevron_right_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              ...aggregate.previewLines.map(
                (line) => _SupplyLineTile(line: line),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: onOpenDailyLogs,
                  child: const Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupplyLineTile extends StatelessWidget {
  final VendorSupplyLine line;

  const _SupplyLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.materialName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatQuantity(line.quantity)} ${line.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 3),
              Text(
                line.amount > 0 ? _compactCurrency(line.amount) : '--',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateChip({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD7DEE8)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

String _compactCurrency(double value) {
  if (value.abs() >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  }
  if (value.abs() >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  }
  if (value.abs() >= 1000) {
    return '₹${(value / 1000).toStringAsFixed(0)}K';
  }
  return '₹${value.toStringAsFixed(0)}';
}

String _formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toStringAsFixed(0);
  return quantity.toStringAsFixed(2);
}

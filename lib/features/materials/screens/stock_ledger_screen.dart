import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/stock_provider.dart';

class StockLedgerScreen extends ConsumerWidget {
  final String? projectId;
  const StockLedgerScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock Ledger')),
        body: const Center(child: Text('No project selected')),
      );
    }

    final balanceAsync = ref.watch(stockBalanceProvider(projectId!));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Stock Ledger',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: balanceAsync.when(
        loading: () => const LoadingWidget(message: 'Loading stock ledger...'),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load stock data',
          onRetry: () => ref.invalidate(stockBalanceProvider(projectId!)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              message: 'No stock records yet',
              icon: Icons.inventory_2_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(stockBalanceProvider(projectId!)),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final name = item['name'] as String? ?? 'Unknown';
                final unit = item['unit'] as String? ?? '';
                final grade = item['grade'] as String? ?? '';
                final received =
                    (item['total_received'] as num?)?.toDouble() ?? 0;
                final consumed =
                    (item['total_consumed'] as num?)?.toDouble() ?? 0;
                final balance =
                    (item['current_stock'] as num?)?.toDouble() ??
                        (received - consumed);
                final isLow = item['is_low_stock'] == true;

                return _StockCard(
                  name: name,
                  grade: grade,
                  unit: unit,
                  received: received,
                  consumed: consumed,
                  balance: balance,
                  isLow: isLow,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String name;
  final String grade;
  final String unit;
  final double received;
  final double consumed;
  final double balance;
  final bool isLow;

  const _StockCard({
    required this.name,
    required this.grade,
    required this.unit,
    required this.received,
    required this.consumed,
    required this.balance,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = received > 0 ? consumed / received : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (grade.isNotEmpty)
                      Text(
                        grade,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              if (isLow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(
                  label: 'Received',
                  value: '${_fmt(received)} $unit',
                  color: AppColors.success),
              const SizedBox(width: 16),
              _Metric(
                  label: 'Consumed',
                  value: '${_fmt(consumed)} $unit',
                  color: AppColors.warning),
              const SizedBox(width: 16),
              _Metric(
                  label: 'Balance',
                  value: '${_fmt(balance)} $unit',
                  color: isLow ? AppColors.error : AppColors.primary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.85
                    ? AppColors.error
                    : ratio > 0.6
                        ? AppColors.warning
                        : AppColors.success,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/material_receipt_model.dart';
import '../providers/repository_providers.dart';

final _receiptDetailProvider =
    FutureProvider.autoDispose.family<MaterialReceiptModel, String>(
  (ref, receiptId) =>
      ref.read(receiptsRepositoryProvider).getReceiptById(receiptId),
);

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_receiptDetailProvider(receiptId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Receipt Detail',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load receipt',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(_receiptDetailProvider(receiptId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (receipt) => _ReceiptContent(receipt: receipt),
      ),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  final MaterialReceiptModel receipt;
  const _ReceiptContent({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.borderDark.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${receipt.receiptNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: receipt.paymentStatus),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Date',
                  value: dateFmt.format(receipt.receiptDate),
                ),
                if (receipt.vendorNameSnapshot != null)
                  _InfoRow(
                    label: 'Vendor',
                    value: receipt.vendorNameSnapshot!,
                  ),
                if (receipt.invoiceNumber != null)
                  _InfoRow(
                    label: 'Invoice #',
                    value: receipt.invoiceNumber!,
                  ),
                if (receipt.invoiceDate != null)
                  _InfoRow(
                    label: 'Invoice Date',
                    value: dateFmt.format(receipt.invoiceDate!),
                  ),
                if (receipt.notes != null && receipt.notes!.isNotEmpty)
                  _InfoRow(label: 'Notes', value: receipt.notes!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Totals card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sidebarBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TotalMetric(
                    label: 'Items',
                    value: '${receipt.totalItems}'),
                _TotalMetric(
                  label: 'Subtotal',
                  value: '₹${_fmt(receipt.subtotal)}',
                ),
                _TotalMetric(
                  label: 'GST',
                  value: '₹${_fmt(receipt.totalGst)}',
                ),
                _TotalMetric(
                  label: 'Grand Total',
                  value: '₹${_fmt(receipt.grandTotal)}',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Items
          Text(
            'Line Items',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (receipt.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No items in this receipt',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            )
          else
            ...receipt.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _ItemCard(index: i + 1, item: item);
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AppColors.success,
      'partial' => AppColors.warning,
      _ => AppColors.textHint,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TotalMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalMetric({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final int index;
  final MaterialReceiptItemModel item;

  const _ItemCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.materialName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '₹${(item.totalAmount ?? item.amount ?? 0).toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _MiniLabel(
                  label: 'Qty',
                  value:
                      '${_fmtQty(item.quantity)} ${item.unit}'),
              _MiniLabel(
                  label: 'Rate',
                  value: '₹${item.rate.toStringAsFixed(2)}'),
              if (item.gstPercent > 0)
                _MiniLabel(
                    label: 'GST',
                    value: '${item.gstPercent}%'),
              if (item.brandCompany != null &&
                  item.brandCompany!.isNotEmpty)
                _MiniLabel(label: 'Brand', value: item.brandCompany!),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtQty(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class _MiniLabel extends StatelessWidget {
  final String label;
  final String value;
  const _MiniLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

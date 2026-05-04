import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A card widget for displaying dashboard metrics
///
/// Features:
/// - Icon with colored background
/// - Metric value with optional animation
/// - Growth indicator (positive/negative)
/// - Loading state with shimmer
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? growth;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.growth,
    this.color = AppColors.primary,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const Spacer(),
                  if (growth != null && !isLoading)
                    _buildGrowthIndicator(context),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                _buildLoadingState()
              else
                _buildValueState(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthIndicator(BuildContext context) {
    final isPositive = !growth!.startsWith('-');
    final growthColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: growthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: growthColor,
          ),
          const SizedBox(width: 4),
          Text(
            growth!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: growthColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// A row of metric cards for dashboard
class MetricCardRow extends StatelessWidget {
  final List<MetricCard> cards;

  const MetricCardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards.map((card) {
          return SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: card,
            ),
          );
        }).toList(),
      ),
    );
  }
}

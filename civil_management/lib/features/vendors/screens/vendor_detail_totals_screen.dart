import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vendor_analytics_provider.dart';
import '../data/models/vendor_summary_models.dart';

class VendorDetailTotalsScreen extends ConsumerWidget {
  final String vendorId;
  final String vendorName;

  const VendorDetailTotalsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(
      vendorMaterialTotalsProvider(VendorTotalsRequest(vendorId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(vendorName)),
      body: totalsAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text('No material data for this vendor yet'),
            );
          }

          // Group by material name
          final Map<String, List<VendorMaterialTotal>> byMaterial = {};
          for (final row in rows) {
            byMaterial.putIfAbsent(row.materialName, () => []).add(row);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final material = byMaterial.keys.elementAt(index);
              final entries = byMaterial[material]!;
              final totalIn = entries.fold<double>(
                0,
                (s, e) => s + e.totalInward,
              );
              final totalOut = entries.fold<double>(
                0,
                (s, e) => s + e.totalOutward,
              );
              final net = entries.fold<double>(0, (s, e) => s + e.net);

              return ExpansionTile(
                title: Text(
                  material,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'In: ${totalIn.toStringAsFixed(2)} • Out: ${totalOut.toStringAsFixed(2)} • Net: ${net.toStringAsFixed(2)}',
                ),
                children: entries
                    .map(
                      (e) => ListTile(
                        title: Text(e.projectName),
                        subtitle: Text(
                          'In: ${e.totalInward.toStringAsFixed(2)}  Out: ${e.totalOutward.toStringAsFixed(2)}',
                        ),
                        trailing: Text(e.net.toStringAsFixed(2)),
                      ),
                    )
                    .toList(),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: byMaterial.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

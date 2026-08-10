import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';

class WeightCalcScreen extends ConsumerWidget {
  const WeightCalcScreen({super.key});

  static const Map<int, double> weightPerMeter = {
    25: 0.95,
    50: 2.72,
    65: 3.39,
    80: 4.05,
    100: 6.19,
    125: 9.11,
    150: 12.30,
    200: 19.30,
    250: 27.90,
    300: 38.20,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomItems = ref.watch(bomProvider);
    final pipeItems = bomItems.where((e) => e.category == 'PIPE' && e.uom == 'MTR').toList();

    double totalWeightKg = 0.0;
    final List<Map<String, dynamic>> calculated = [];

    for (var pipe in pipeItems) {
      final sizeDigits = RegExp(r'\d+').firstMatch(pipe.nd)?.group(0);
      final int size = int.tryParse(sizeDigits ?? '0') ?? 0;
      final double wpm = weightPerMeter[size] ?? 5.0;
      final double weight = pipe.qty * wpm;

      totalWeightKg += weight;
      calculated.add({
        'nd': pipe.nd,
        'mtr': pipe.qty,
        'wpm': wpm,
        'weight': weight,
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metricBox('Total Weight (KG)', '${totalWeightKg.toStringAsFixed(1)} kg', Colors.purple),
              const SizedBox(width: 12),
              _metricBox('Metric Tonnes', '${(totalWeightKg / 1000).toStringAsFixed(2)} MT', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          const Text('⚖ Pipe Size-wise Weight Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: calculated.length,
              itemBuilder: (context, index) {
                final item = calculated[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.scale, color: Colors.purple),
                    title: Text('${item['nd']} - ${item['weight'].toStringAsFixed(1)} kg'),
                    subtitle: Text('${item['mtr']} mtr × ${item['wpm']} kg/m'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
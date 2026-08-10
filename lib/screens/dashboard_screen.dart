import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/bom_provider.dart';
import '../providers/spool_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const List<Color> _categoryColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomItems = ref.watch(bomProvider);
    final spools = ref.watch(spoolProvider);

    final totalDrawings = bomItems.map((e) => e.drawingNo).where((d) => d.isNotEmpty).toSet().length;
    final totalMtr = bomItems.where((e) => e.uom == 'MTR').fold(0.0, (sum, item) => sum + item.qty);
    final totalNos = bomItems.where((e) => e.uom != 'MTR').fold(0.0, (sum, item) => sum + item.qty);

    final categoryCounts = _getCategoryCounts(bomItems);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 5 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard('BOM Rows', bomItems.length.toString(), Colors.blue, Icons.list_alt),
                  _statCard('Spools', spools.length.toString(), Colors.green, Icons.label),
                  _statCard('Drawings', totalDrawings.toString(), Colors.orange, Icons.architecture),
                  _statCard('Total MTR', totalMtr.toStringAsFixed(1), Colors.purple, Icons.straighten),
                  _statCard('Total NOS', totalNos.toInt().toString(), Colors.red, Icons.numbers),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 🟢 Category Breakdown Card with Side Legend
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: bomItems.isEmpty
                  ? const SizedBox(
                height: 180,
                child: Center(child: Text('No data available. Upload drawings to extract BOM.')),
              )
                  : Row(
                children: [
                  // 1. Clean Pie Chart (Left Side)
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _getCategorySections(categoryCounts, bomItems.length),
                          sectionsSpace: 2,
                          centerSpaceRadius: 35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 2. Clear Legend List (Right Side)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categoryCounts.entries.toList().asMap().entries.map((entry) {
                        final int index = entry.key;
                        final MapEntry<String, int> cat = entry.value;
                        final color = _categoryColors[index % _categoryColors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${cat.key} (${cat.value})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Icon(icon, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey,fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getCategoryCounts(List bomItems) {
    final Map<String, int> counts = {};
    for (var item in bomItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  List<PieChartSectionData> _getCategorySections(Map<String, int> counts, int totalItems) {
    int index = 0;

    return counts.entries.map((entry) {
      final color = _categoryColors[index % _categoryColors.length];
      index++;

      final double percentage = (entry.value / totalItems) * 100;
      // 🟢 Agar slice 10% se chota hai toh chart section par text hide kar denge
      final bool isLargeEnough = percentage >= 10;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: isLargeEnough ? '${percentage.toStringAsFixed(0)}%' : '',
        showTitle: isLargeEnough,
        radius: 45,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}
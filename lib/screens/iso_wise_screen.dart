import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';
import '../services/excel_service.dart';

class IsoWiseScreen extends ConsumerWidget {
  const IsoWiseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomItems = ref.watch(bomProvider);

    if (bomItems.isEmpty) {
      return const Center(child: Text('No BOM items found. Upload drawings first.'));
    }

    final lineNos = bomItems.map((e) => e.lineNo.isEmpty ? '(No Line)' : e.lineNo).toSet().toList();
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var item in bomItems) {
      final key = '${item.description}||${item.nd}||${item.uom}';
      final lineKey = item.lineNo.isEmpty ? '(No Line)' : item.lineNo;

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'description': item.description,
          'nd': item.nd,
          'uom': item.uom,
          'byLine': <String, double>{},
          'total': 0.0,
        };
      }

      final lineMap = grouped[key]!['byLine'] as Map<String, double>;
      lineMap[lineKey] = (lineMap[lineKey] ?? 0.0) + item.qty;
      grouped[key]!['total'] = (grouped[key]!['total'] as double) + item.qty;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 ISO WISE BOM (Pivot Table)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('DESCRIPTION')),
                    const DataColumn(label: Text('ND/SIZE')),
                    const DataColumn(label: Text('UOM')),
                    ...lineNos.map((l) => DataColumn(label: Text(l))),
                    const DataColumn(label: Text('TOTAL QTY')),
                  ],
                  rows: grouped.values.map((map) {
                    final lineMap = map['byLine'] as Map<String, double>;
                    return DataRow(cells: [
                      DataCell(Text(map['description'])),
                      DataCell(Text(map['nd'])),
                      DataCell(Text(map['uom'])),
                      ...lineNos.map((l) => DataCell(Text(lineMap.containsKey(l) ? lineMap[l]!.toStringAsFixed(1) : '-'))),
                      DataCell(Text(map['total'].toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
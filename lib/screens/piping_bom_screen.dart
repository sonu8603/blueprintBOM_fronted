import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';
import '../services/excel_service.dart';

class PipingBomScreen extends ConsumerWidget {
  const PipingBomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomItems = ref.watch(bomProvider);

    final Map<String, Map<String, dynamic>> consolidated = {};

    for (var item in bomItems) {
      final key = '${item.category}||${item.description}||${item.nd}||${item.uom}';
      if (!consolidated.containsKey(key)) {
        consolidated[key] = {
          'category': item.category,
          'description': item.description,
          'nd': item.nd,
          'uom': item.uom,
          'totalQty': 0.0,
        };
      }
      consolidated[key]!['totalQty'] = (consolidated[key]!['totalQty'] as double) + item.qty;
    }

    final list = consolidated.values.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(' PIPING BOM — Consolidated Procurement List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('CATEGORY')),
                    DataColumn(label: Text('DESCRIPTION')),
                    DataColumn(label: Text('ND/SIZE')),
                    DataColumn(label: Text('TOTAL QTY')),
                    DataColumn(label: Text('UOM')),
                  ],
                  rows: list.map((item) {
                    return DataRow(cells: [
                      DataCell(Chip(label: Text(item['category'], style: const TextStyle(fontSize: 10)))),
                      DataCell(Text(item['description'])),
                      DataCell(Text(item['nd'])),
                      DataCell(Text(item['totalQty'].toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item['uom'])),
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
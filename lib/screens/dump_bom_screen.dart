import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';
import '../providers/spool_provider.dart';
import '../models/bom_item.dart';
import '../services/excel_service.dart';


class DumpBomScreen extends ConsumerStatefulWidget {
  const DumpBomScreen({super.key});

  @override
  ConsumerState<DumpBomScreen> createState() => _DumpBomScreenState();
}

class _DumpBomScreenState extends ConsumerState<DumpBomScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bomItems = ref.watch(bomProvider);
    final filtered = bomItems.where((item) {
      return item.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.drawingNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.lineNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.nd.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          TextField(
            decoration: const InputDecoration(
              hintText: ' Search description, ND, drawing...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),
          const SizedBox(height: 16),

          // 2. Action Bar with Live Counter Badge & Buttons
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.format_list_numbered, size: 18),
                label: Text(
                  'Total Rows: ${filtered.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.blue.shade50,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(bomProvider.notifier).addItem(
                            BomItem(
                              id: '',
                              drawingNo: '',
                              lineNo: '',
                              nd: '',
                              qty: 1,
                              uom: 'NOS',
                              description: '',
                              category: 'OTHER',
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Row'),
                      ),
                      const SizedBox(width: 8),

                      OutlinedButton.icon(
                        onPressed: () {
                          final initialCount = ref.read(bomProvider).length;
                          ref.read(bomProvider.notifier).mergeDuplicates();

                          final finalCount = ref.read(bomProvider).length;
                          final mergedDiff = initialCount - finalCount;

                          if (mergedDiff > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Successfully merged $mergedDiff duplicate row(s)!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ℹ️ No duplicate items found to merge.'),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.merge_type),
                        label: const Text('Merge Duplicates'),
                      ),
                      const SizedBox(width: 8),

                      // 🟢 BUTTON 1: DIRECT DOWNLOAD TO MOBILE
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final spools = ref.read(spoolProvider);
                          if (bomItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ No data to download!')),
                            );
                            return;
                          }

                          final path = await ExcelExportService.downloadToPhone(bomItems, spools);

                          if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📥 File saved in Downloads: ${path.split('/').last}'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.file_download),
                        label: const Text('Direct Download'),
                      ),
                      const SizedBox(width: 8),

                      // 🟢 BUTTON 2: SHARE VIA APPS
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          final spools = ref.read(spoolProvider);
                          if (bomItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ No data to share!')),
                            );
                            return;
                          }

                          ExcelExportService.shareExcelFile(bomItems, spools);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Excel'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Numbered Scrollable Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('DRG NO.')),
                    DataColumn(label: Text('LINE NO.')),
                    DataColumn(label: Text('ND/SIZE')),
                    DataColumn(label: Text('QTY')),
                    DataColumn(label: Text('UOM')),
                    DataColumn(label: Text('DESCRIPTION')),
                    DataColumn(label: Text('CATEGORY')),
                  ],
                  rows: List.generate(filtered.length, (index) {
                    final item = filtered[index];
                    return DataRow(cells: [
                      DataCell(
                        Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => ref.read(bomProvider.notifier).removeItem(index),
                        ),
                      ),
                      DataCell(Text(item.drawingNo)),
                      DataCell(Text(item.lineNo)),
                      DataCell(Text(item.nd)),
                      DataCell(Text(item.qty.toString())),
                      DataCell(Text(item.uom)),
                      DataCell(Text(item.description)),
                      DataCell(Chip(label: Text(item.category, style: const TextStyle(fontSize: 10)))),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
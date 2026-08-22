import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drawing_revision_model.dart';
import '../providers/bom_provider.dart';
import '../providers/revision_provider.dart';
import '../providers/spool_provider.dart';
import '../services/ai_service.dart';
import '../services/token_service.dart';

class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen> {
  final TextEditingController _notesController = TextEditingController();

  Future<void> _loadRevisionIntoWorkspace(
      DrawingRevision revision) async {

    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found'),
        ),
      );
      return;
    }

    final drawing = await AIService.getDrawingById(
      revision.id,
      token,
    );

    if (!mounted) return;

    if (drawing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drawing not found on server'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(bomProvider.notifier).setAll(drawing.bomItems);

    ref.read(spoolProvider.notifier).setAll(drawing.spools);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Loaded ${drawing.drawingNo}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revisions = ref.watch(revisionProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔄 Processed Drawings & Revisions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (revisions.isNotEmpty)
                IconButton(
                  onPressed: () => ref.read(revisionProvider.notifier).clearAll(),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Clear All Revisions',
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 🟢 Local Instant List View
          Expanded(
            flex: 2,
            child: revisions.isEmpty
                ? Center(
              child: Text(
                'No processed drawings saved yet.\nUpload a drawing to create a revision entry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : ListView.builder(
              itemCount: revisions.length,
              itemBuilder: (context, index) {
                final item = revisions[index];
                final dateStr = '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}';

                return Column(
                  children: [
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.description, color: Colors.blue.shade800),
                        ),
                        title: Text(
                          item.drawingNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Line: ${item.lineNo} | Saved: $dateStr'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.bomItems.length} BOM Rows',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            Text(
                              '${item.spools.length} Spools',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () => _loadRevisionIntoWorkspace(item),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 24),
          const Text('📝 Project Site Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Expanded(
            flex: 1,
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write site remarks, client comments, or pending inspection points here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
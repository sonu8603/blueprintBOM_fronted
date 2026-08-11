import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/upload_extract_provider.dart';
import 'log_model/logitem_model.dart';

class UploadExtractScreen extends ConsumerStatefulWidget {
  const UploadExtractScreen({super.key});

  @override
  ConsumerState<UploadExtractScreen> createState() => _UploadExtractScreenState();
}

class _UploadExtractScreenState extends ConsumerState<UploadExtractScreen> {
  late final TextEditingController _jsonController;
  late final ScrollController _logScrollController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
    _logScrollController = ScrollController();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Riverpod State Listeners
    final state = ref.watch(uploadExtractProvider);
    final notifier = ref.read(uploadExtractProvider.notifier);

    // Auto-scroll log console whenever logs change
    ref.listen<UploadExtractState>(uploadExtractProvider, (previous, next) {
      if (next.logs.length != (previous?.logs.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            onPressed: state.isLoading
                ? null
                : () async {
              final res = await notifier.pickAndProcessFile(ref);
              if (res != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Added ${res.bomItems.length} BOM Items & ${res.spools.length} Spools!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: state.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.cloud_upload),
            label: Text(state.isLoading ? 'Processing Drawing...' : 'Upload Drawing (PDF or Image)'),
          ),
          const SizedBox(height: 8),

          // 🟢 Riverpod Driven Log Console
          if (state.logs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade700),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: state.logs.length,
                itemBuilder: (context, i) {
                  final item = state.logs[i];
                  Color txtColor = Colors.grey.shade300;
                  if (item.isError) txtColor = Colors.redAccent;
                  if (item.isSuccess) txtColor = Colors.greenAccent;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      item.text,
                      style: TextStyle(
                        color: txtColor,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const Divider(height: 24),
          const Text('📋 Manual JSON Paste Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _jsonController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '[\n  {"drawing_no":"W101", "line_no":"L-01", "nd":"100 NB", "qty":5, "uom":"MTR", "description":"PIPE A106"}\n]',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                final success = notifier.parseManualJson(_jsonController.text, ref);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Added BOM items successfully!'), backgroundColor: Colors.green),
                  );
                  _jsonController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Invalid or empty JSON format!'), backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Parse & Add to BOM'),
            ),
          ),
        ],
      ),
    );
  }
}
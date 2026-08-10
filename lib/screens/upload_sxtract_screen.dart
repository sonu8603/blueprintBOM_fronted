import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ai_service.dart';
import '../models/bom_item.dart';
import '../providers/bom_provider.dart';
import '../providers/spool_provider.dart';

class UploadExtractScreen extends ConsumerStatefulWidget {
  const UploadExtractScreen({super.key});

  @override
  ConsumerState<UploadExtractScreen> createState() => _UploadExtractScreenState();
}

class LogItem {
  final String text;
  final bool isError;
  final bool isSuccess;
  LogItem(this.text, {this.isError = false, this.isSuccess = false});
}

class _UploadExtractScreenState extends ConsumerState<UploadExtractScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  bool _isLoading = false;
  final List<LogItem> _logs = [];

  void _addLog(String msg, {bool isError = false, bool isSuccess = false}) {
    setState(() {
      _logs.add(LogItem(msg, isError: isError, isSuccess: isSuccess));
    });
    // Auto Scroll Log Console to bottom
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

  Future<void> _pickAndProcessFile() async {
    setState(() {
      _logs.clear();
      _isLoading = true;
    });

    _addLog('🚀 File picker opened...');

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.single;
        final String extension = file.extension?.toLowerCase() ?? '';
        _addLog('📁 File Selected: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)');

        Uint8List? fileBytes = file.bytes;
        if (fileBytes == null && !kIsWeb && file.path != null) {
          fileBytes = await File(file.path!).readAsBytes();
        }

        if (fileBytes == null) {
          _addLog('❌ Could not read file bytes!', isError: true);
          return;
        }

        final bool isPdf = extension == 'pdf';

        // 🟢 Execute AI with Step-by-Step Logging
        final data = await AIService.processFileWithLogs(
          fileBytes: fileBytes,
          isPdf: isPdf,
          onLog: (msg, {isError = false, isSuccess = false}) {
            _addLog(msg, isError: isError, isSuccess: isSuccess);
          },
        );

        ref.read(bomProvider.notifier).addItems(data['bom']);
        ref.read(spoolProvider.notifier).addSpools(data['spools']);
      } else {
        _addLog('⚠️ No file selected.');
      }
    } catch (e) {
      _addLog('❌ Fatal Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseManualJson() {
    try {
      final raw = _jsonController.text.trim();
      final decoded = json.decode(raw);
      final List list = decoded is List ? decoded : (decoded['bom'] ?? []);

      final items = list.map((e) => BomItem.fromJson(e)).toList();
      ref.read(bomProvider.notifier).addItems(items);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Added ${items.length} BOM items successfully!')),
      );
      _jsonController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Invalid JSON format: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _isLoading ? null : _pickAndProcessFile,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload Drawing (PDF or Image)'),
          ),
          const SizedBox(height: 8),

          // 🟢 LIVE TERMINAL LOG CONSOLE (HTML Debug Box jaisa)
          if (_logs.isNotEmpty) ...[
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
                itemCount: _logs.length,
                itemBuilder: (context, i) {
                  final item = _logs[i];
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
              onPressed: _parseManualJson,
              icon: const Icon(Icons.check_circle),
              label: const Text('Parse & Add to BOM'),
            ),
          ),
        ],
      ),
    );
  }
}
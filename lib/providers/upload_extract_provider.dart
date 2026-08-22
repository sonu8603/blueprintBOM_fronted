import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/bom_item.dart';
import '../models/drawing_revision_model.dart';
import '../services/ai_service.dart';
import '../services/token_service.dart';
import '../upload_pdf/log_model/logitem_model.dart';
import '../widgets/extraction_result.dart';
import 'bom_provider.dart';
import 'revision_provider.dart';
import 'spool_provider.dart';

class UploadExtractNotifier extends StateNotifier<UploadExtractState> {
  // 🟢 1. Riverpod Ref inject kiya (WidgetRef ki zaroorat nahi padegi)
  final Ref _ref;

  UploadExtractNotifier(this._ref) : super(UploadExtractState());

  void addLog(String msg, {bool isError = false, bool isSuccess = false}) {
    state = state.copyWith(
      logs: [...state.logs, LogItem(msg, isError: isError, isSuccess: isSuccess)],
    );
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  // 🟢 2. 'WidgetRef ref' parameter hata diya
  Future<ExtractionResult?> pickAndProcessFile() async {
    clearLogs();
    state = state.copyWith(isLoading: true);
    addLog('🚀 Opening file picker...');

    try {
      final token = await TokenService.getToken();

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        addLog('⚠️ No file selected.');
        return null;
      }

      final PlatformFile file = result.files.single;
      final String extension = file.extension?.toLowerCase() ?? '';
      addLog('📁 File Selected: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)');

      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        addLog('❌ Error: Selected file contains no readable data!', isError: true);
        return null;
      }

      final bool isPdf = extension == 'pdf';
      final String activeToken = token ??
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNzVkNDMzZTljMWFmNTcxYzdiZDA3NyIsImVtYWlsIjoic29udUBlbWFpbC5jb20iLCJpYXQiOjE3ODY0NTY4ODd9.Sg3X0dMe0iORbDfwA6HUnozUqE3VZFvOCwfW7JF_XNs';

      final extractionResult = await AIService.processFileWithLogs(
        fileBytes: fileBytes,
        isPdf: isPdf,
        authToken: activeToken,
        onLog: (msg, {isError = false, isSuccess = false}) {
          addLog(msg, isError: isError, isSuccess: isSuccess);
        },
      );

      // 🟢 3. _ref use karke providers update karein
      _ref.read(bomProvider.notifier).setAll(extractionResult.bomItems);
      _ref.read(spoolProvider.notifier).setAll(extractionResult.spools);

      // 🟢 4. Auto save revision entry
      final firstBom = extractionResult.bomItems.isNotEmpty ? extractionResult.bomItems.first : null;
      final String drgName = (firstBom?.drawingNo.isNotEmpty == true)
          ? firstBom!.drawingNo
          : file.name.replaceAll('.pdf', '').replaceAll('.png', '');
      final String lineName = (firstBom?.lineNo.isNotEmpty == true) ? firstBom!.lineNo : 'N/A';

      _ref.read(revisionProvider.notifier).addRevision(
        DrawingRevision(
          id: extractionResult.id,
          drawingNo: drgName,
          lineNo: lineName,
          timestamp: DateTime.now(),
          bomItems: extractionResult.bomItems,
          spools: extractionResult.spools,
        ),
      );

      addLog('🎉 Data applied to UI and saved to Revisions!', isSuccess: true);
      return extractionResult;
    } catch (e) {
      addLog('❌ Operation Stopped: $e', isError: true);
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // 🟢 5. 'WidgetRef ref' parameter yahan se bhi hata diya
  bool parseManualJson(String rawJson) {
    try {
      if (rawJson.trim().isEmpty) return false;

      final decoded = json.decode(rawJson.trim());
      final List list = decoded is List ? decoded : (decoded['bom'] ?? []);

      final items = list.map((e) => BomItem.fromJson(e)).toList();
      _ref.read(bomProvider.notifier).setAll(items);

      return true;
    } catch (e) {
      addLog('❌ Invalid JSON format: $e', isError: true);
      return false;
    }
  }
}

// 🟢 Provider initialization
final uploadExtractProvider =
StateNotifierProvider<UploadExtractNotifier, UploadExtractState>((ref) {
  return UploadExtractNotifier(ref);
});
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/ai_service.dart';
import '../services/token_service.dart';
import '../models/bom_item.dart';

import '../upload_pdf/log_model/logitem_model.dart';
import '../widgets/extraction_result.dart';
import 'bom_provider.dart';
import 'spool_provider.dart';

// 🟢 Log Item Model



class UploadExtractNotifier extends StateNotifier<UploadExtractState> {
  UploadExtractNotifier() : super(UploadExtractState());

  void addLog(String msg, {bool isError = false, bool isSuccess = false}) {
    state = state.copyWith(
      logs: [...state.logs, LogItem(msg, isError: isError, isSuccess: isSuccess)],
    );
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  Future<ExtractionResult?> pickAndProcessFile(WidgetRef ref) async {
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
      // this token is temporary
      final String activeToken = token ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNzVkNDMzZTljMWFmNTcxYzdiZDA3NyIsImVtYWlsIjoic29udUBlbWFpbC5jb20iLCJpYXQiOjE3ODY0MzY3ODJ9.T4ADJhcQ8u4tLBhcu4e5aXQ9ilDxaxjGqeNZL-txOBY';

      final extractionResult = await AIService.processFileWithLogs(
        fileBytes: fileBytes,
        isPdf: isPdf,
         authToken:  activeToken,
       // authToken: token!,
        onLog: (msg, {isError = false, isSuccess = false}) {
          addLog(msg, isError: isError, isSuccess: isSuccess);
        },
      );


      ref.read(bomProvider.notifier).addItems(extractionResult.bomItems);
      ref.read(spoolProvider.notifier).addSpools(extractionResult.spools);

      return extractionResult;
    } catch (e) {
      addLog('❌ Operation Stopped: $e', isError: true);
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  bool parseManualJson(String rawJson, WidgetRef ref) {
    try {
      if (rawJson.trim().isEmpty) return false;

      final decoded = json.decode(rawJson.trim());
      final List list = decoded is List ? decoded : (decoded['bom'] ?? []);

      final items = list.map((e) => BomItem.fromJson(e)).toList();
      ref.read(bomProvider.notifier).addItems(items);

      return true;
    } catch (e) {
      addLog('❌ Invalid JSON format: $e', isError: true);
      return false;
    }
  }
}

//provider
final uploadExtractProvider =
StateNotifierProvider<UploadExtractNotifier, UploadExtractState>((ref) {
  return UploadExtractNotifier();
});
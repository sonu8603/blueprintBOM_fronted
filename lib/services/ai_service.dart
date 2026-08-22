import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/bom_item.dart';
import '../models/drawing_revision_model.dart';
import '../models/spool.dart';
import '../widgets/extraction_result.dart';

class AIService {
  static const String backendUrl = 'http://10.0.2.2:3000/api/drawing/process-drawing';

  static Future<ExtractionResult> processFileWithLogs({
    required Uint8List fileBytes,
    required bool isPdf,
    required String authToken,
    required Function(String log, {bool isError, bool isSuccess}) onLog,
  }) async {
    onLog('🚀 STEP 1: Creating Multipart File Stream...');

    try {
      // 🟢 Multipart Request Setup
      final uri = Uri.parse(backendUrl);
      final request = http.MultipartRequest('POST', uri);

      // Headers Add Karein
      request.headers['Authorization'] = 'Bearer $authToken';

      // 🟢 File Bytes Add Karein ('file' field name backend multer.single('file') se match karna chahiye)
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: isPdf ? 'drawing.pdf' : 'drawing.png',
        ),
      );

      onLog('🤖 STEP 2: Uploading to Server...');

      // Request Send Karein
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 5 minutes.');
        },
      );

      // Stream ko standard response me convert karein
      final response = await http.Response.fromStream(streamedResponse);

      return _handleHttpResponse(response, onLog);
    } on SocketException catch (e) {
      final errorMsg = '❌ Network Error: $e';
      onLog(errorMsg, isError: true);
      throw Exception(errorMsg);
    } catch (e) {
      final errorMsg = '❌ Exception: $e';
      onLog(errorMsg, isError: true);
      rethrow;
    }
  }



  static ExtractionResult _handleHttpResponse(
      http.Response response,
      Function(String log, {bool isError, bool isSuccess}) onLog,
      ) {
    onLog('📡 Server Response Status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> responseData = json.decode(response.body);

        final List<BomItem> bom = (responseData['bom'] as List? ?? [])
            .map((e) => BomItem.fromJson(e))
            .toList();

        final List<Spool> spools = (responseData['spools'] as List? ?? [])
            .map((e) => Spool.fromJson(e))
            .toList();
        final String drawingId =
            responseData['drawingId']?.toString() ?? '';

        onLog('🎉 SUCCESS: Extracted ${bom.length} BOM Items & ${spools.length} Spools!', isSuccess: true);
        return ExtractionResult(
          id: drawingId,
          bomItems: bom,
          spools: spools,
        );

      default:
        final msg = '❌ Failed with Status ${response.statusCode}: ${response.body}';
        onLog(msg, isError: true);
        throw Exception(msg);
    }
  }


  // fetch drawing
// 🟢 NEW: Fetch All Drawing Revisions/History from MongoDB
  static Future<List<Map<String, dynamic>>> fetchAllDrawings(String authToken) async {
    try {
      final uri = Uri.parse('http://10.0.2.2:3000/api/drawing/all');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List list = data['drawings'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      print('❌ Failed to fetch drawing history: $e');
    }
    return [];
  }

  static Future<DrawingRevision?> getDrawingById(
      String drawingId, String authToken) async {
    if (drawingId.trim().isEmpty) {
      print('⚠️ Drawing ID is empty, skipping API call');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:3000/api/drawing/${Uri.encodeComponent(drawingId)}',
        ),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['drawing'] != null) {
          return DrawingRevision.fromJson(
            data['drawing'],
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ Error fetching drawing: $e');
      return null;
    }
  }
}
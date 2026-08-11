// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:http/http.dart' as http;
// import 'package:pdfx/pdfx.dart'; // 🟢 Modern & compatible PDF package
// import '../models/bom_item.dart';
// import '../models/spool.dart';
//
// class AIService {
//
//
//   static const String prompt = '''
//   You are a piping engineering expert. Extract ALL data from this isometric drawing.
//   Return ONLY valid JSON (no markdown formatting):
//   {
//     "drawing_no": "",
//     "line_no": "",
//     "revision": "Rev 0",
//     "weld_type": "BUTT+FILLET",
//     "bom": [
//       {
//         "id": "1",
//         "nd": "100 NB",
//         "qty": "5.2",
//         "uom": "MTR",
//         "description": "PIPE A106 GR B",
//         "category": "PIPE"
//       }
//     ],
//     "spools": [
//       {
//         "spool_mark": "SP-01",
//         "nos_off": "1",
//         "material": "CS",
//         "remark": ""
//       }
//     ]
//   }
//   ''';
//
//   static Future<Map<String, dynamic>> processFileWithLogs({
//     required Uint8List fileBytes,
//     required bool isPdf,
//     required Function(String log, {bool isError, bool isSuccess}) onLog,
//   }) async {
//     if (apiKey == 'YOUR_ANTHROPIC_API_KEY' || apiKey.isEmpty) {
//       onLog('❌ Error: API Key missing in ai_service.dart!', isError: true);
//       throw Exception('API Key missing in ai_service.dart');
//     }
//
//     List<String> imageBase64List = [];
//
//     // ----------------------------------------------------
//     // STEP 1: Convert File to Base64 Images (Page by Page if PDF)
//     // ----------------------------------------------------
//     if (isPdf) {
//       onLog('📄 STEP 1: PDF Document load ho raha hai...');
//       try {
//         final doc = await PdfDocument.openData(fileBytes);
//         onLog('ℹ️ Total Pages found in PDF: ${doc.pagesCount}');
//
//         for (int i = 1; i <= doc.pagesCount; i++) {
//           onLog('🔄 Rendering PDF Page $i/${doc.pagesCount} to Image...');
//           final page = await doc.getPage(i);
//
//           final pageImage = await page.render(
//             width: page.width * 2,  // High resolution for OCR
//             height: page.height * 2,
//             format: PdfPageImageFormat.png,
//           );
//
//           if (pageImage != null && pageImage.bytes.isNotEmpty) {
//             imageBase64List.add(base64Encode(pageImage.bytes));
//             onLog('✓ Page $i/${doc.pagesCount} Rendered Successfully');
//           } else {
//             onLog('⚠️ Page $i image blank ya empty aayi.', isError: true);
//           }
//
//           await page.close();
//         }
//         await doc.close();
//       } catch (e) {
//         onLog('❌ PDF Render Failed: $e', isError: true);
//         throw Exception('PDF Render Error: $e');
//       }
//     } else {
//       onLog('🖼 STEP 1: Image File Detected');
//       imageBase64List.add(base64Encode(fileBytes));
//       onLog('✓ Image Base64 Encoded Successfully');
//     }
//
//     if (imageBase64List.isEmpty) {
//       onLog('❌ No valid pages to process!', isError: true);
//       throw Exception('No pages rendered');
//     }
//
//     // ----------------------------------------------------
//     // STEP 2: Send Rendered Images to Claude AI
//     // ----------------------------------------------------
//     List<BomItem> totalBom = [];
//     List<Spool> totalSpools = [];
//
//     for (int index = 0; index < imageBase64List.length; index++) {
//       final base64Image = imageBase64List[index];
//       onLog('🤖 STEP 2: Sending Page ${index + 1}/${imageBase64List.length} to Claude AI API...');
//
//       try {
//         final response = await http.post(
//           Uri.parse('https://api.anthropic.com/v1/messages'),
//           headers: {
//             'Content-Type': 'application/json',
//             'x-api-key': apiKey,
//             'anthropic-version': '2023-06-01',
//           },
//           body: json.encode({
//             'model': 'claude-3-5-sonnet-20241022',
//             'max_tokens': 4000,
//             'messages': [
//               {
//                 'role': 'user',
//                 'content': [
//                   {
//                     'type': 'image',
//                     'source': {
//                       'type': 'base64',
//                       'media_type': 'image/png',
//                       'data': base64Image,
//                     }
//                   },
//                   {
//                     'type': 'text',
//                     'text': prompt,
//                   }
//                 ]
//               }
//             ]
//           }),
//         ).timeout(
//           const Duration(seconds: 90),
//           onTimeout: () {
//             throw Exception('Request Timed Out (90s). Server slow ya internet issue.');
//           },
//         );
//
//         onLog('📡 Response Status Code: ${response.statusCode}');
//
//         if (response.statusCode == 200) {
//           onLog('🔍 Parsing JSON Response for Page ${index + 1}...');
//           final body = json.decode(response.body);
//           final String rawText = body['content'][0]['text'];
//
//           final cleanJsonText = rawText
//               .replaceAll('```json', '')
//               .replaceAll('```', '')
//               .trim();
//
//           final Map<String, dynamic> jsonMap = json.decode(cleanJsonText);
//
//           final String drawingNo = jsonMap['drawing_no']?.toString() ?? '';
//           final String lineNo = jsonMap['line_no']?.toString() ?? '';
//
//           if (jsonMap['bom'] != null) {
//             final pageBom = (jsonMap['bom'] as List).map((e) {
//               e['drawing_no'] = drawingNo;
//               e['line_no'] = lineNo;
//               return BomItem.fromJson(e);
//             }).toList();
//             totalBom.addAll(pageBom);
//             onLog('✓ Extracted ${pageBom.length} BOM Items from Page ${index + 1}', isSuccess: true);
//           }
//
//           if (jsonMap['spools'] != null) {
//             final pageSpools = (jsonMap['spools'] as List).map((e) {
//               e['drawing_no'] = drawingNo;
//               e['line_no'] = lineNo;
//               return Spool.fromJson(e);
//             }).toList();
//             totalSpools.addAll(pageSpools);
//             onLog('✓ Extracted ${pageSpools.length} Spools from Page ${index + 1}', isSuccess: true);
//           }
//         } else if (response.statusCode == 401) {
//           onLog('❌ Error 401: Invalid API Key! Check your Key in ai_service.dart', isError: true);
//           throw Exception('Invalid API Key (401)');
//         } else {
//           onLog('❌ API Error (${response.statusCode}): ${response.body}', isError: true);
//           throw Exception('API Error (${response.statusCode})');
//         }
//       } catch (e) {
//         onLog('❌ Error processing Page ${index + 1}: $e', isError: true);
//         rethrow;
//       }
//     }
//
//     onLog('🎉 SUCCESS: Total ${totalBom.length} Items & ${totalSpools.length} Spools Extracted!', isSuccess: true);
//     return {'bom': totalBom, 'spools': totalSpools};
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/bom_item.dart';
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
    onLog('🚀 STEP 1: Preparing payload & converting file bytes...');

    try {
      final String base64File = base64Encode(fileBytes);

      onLog('🤖 STEP 2: Connecting to   Server...');

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'fileBytesBase64': base64File,
          'isPdf': isPdf,
        }),
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out after 5 minute. Server slow or weak connection.');
        },
      );

      return _handleHttpResponse(response, onLog);
    } on SocketException catch (e) {
      final errorMsg = '❌ Network Error: Could not connect to Backend ($backendUrl). Ensure server is running. Details: $e';
      onLog(errorMsg, isError: true);
      throw Exception(errorMsg);
    } on TimeoutException catch (e) {
      final errorMsg = '⏱️ Connection Timeout: ${e.message}';
      onLog(errorMsg, isError: true);
      throw Exception(errorMsg);
    } catch (e) {
      final errorMsg = '❌ Unexpected Exception: $e';
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

        onLog('🎉 SUCCESS: Extracted ${bom.length} BOM Items & ${spools.length} Spools!', isSuccess: true);
        return ExtractionResult(bomItems: bom, spools: spools);

      case 401:
        const msg = '❌ 401 Unauthorized: Session expired or invalid token. Please log in again.';
        onLog(msg, isError: true);
        throw Exception(msg);

      case 429:
        const msg = '⚠️ 429 Too Many Requests: Rate limit reached. Please wait a moment and try again.';
        onLog(msg, isError: true);
        throw Exception(msg);

      case 500:
      case 502:
      case 503:
        final msg = '💥 Server Error (${response.statusCode}): ${response.body}';
        onLog(msg, isError: true);
        throw Exception(msg);

      default:
        final msg = '❌ Failed with Status ${response.statusCode}: ${response.body}';
        onLog(msg, isError: true);
        throw Exception(msg);
    }
  }
}
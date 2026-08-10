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




import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import '../models/bom_item.dart';
import '../models/spool.dart';

class AIService {



  static const String prompt = '''
  You are a piping engineering expert. Extract ALL data from this isometric drawing.
  Return ONLY valid JSON (no markdown formatting, no conversational text):
  {
    "drawing_no": "",
    "line_no": "",
    "revision": "Rev 0",
    "weld_type": "BUTT+FILLET",
    "bom": [
      {
        "id": "1",
        "nd": "100 NB",
        "qty": "5.2",
        "uom": "MTR",
        "description": "PIPE A106 GR B",
        "category": "PIPE"
      }
    ],
    "spools": [
      {
        "spool_mark": "SP-01",
        "nos_off": "1",
        "material": "CS",
        "remark": ""
      }
    ]
  }
  ''';

  static Future<Map<String, dynamic>> processFileWithLogs({
    required Uint8List fileBytes,
    required bool isPdf,
    required Function(String log, {bool isError, bool isSuccess}) onLog,
  }) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_NEW_GEMINI_API_KEY_HERE') {
      onLog('❌ Error: Gemini API Key missing in ai_service.dart!', isError: true);
      print('❌ Error: Gemini API Key missing in ai_service.dart!');
      throw Exception('Gemini API Key missing');
    }

    List<String> imageBase64List = [];


    if (isPdf) {
      onLog('📄 STEP 1: PDF Document load ho raha hai...');
      print('📄 STEP 1: PDF Document load ho raha hai...');
      try {
        final doc = await PdfDocument.openData(fileBytes);
        onLog('ℹ️ Total Pages found in PDF: ${doc.pagesCount}');
        print('ℹ️ Total Pages found in PDF: ${doc.pagesCount}');

        for (int i = 1; i <= doc.pagesCount; i++) {
          onLog('🔄 Rendering PDF Page $i/${doc.pagesCount}...');
          print('🔄 Rendering PDF Page $i/${doc.pagesCount}...');
          final page = await doc.getPage(i);


          final pageImage = await page.render(
            width: page.width * 1.2,
            height: page.height * 1.2,
            format: PdfPageImageFormat.jpeg,
          );

          if (pageImage != null && pageImage.bytes.isNotEmpty) {
            imageBase64List.add(base64Encode(pageImage.bytes));
            onLog('✓ Page $i/${doc.pagesCount} Rendered Successfully');
            print('✓ Page $i/${doc.pagesCount} Rendered Successfully');
          }
          await page.close();
        }
        await doc.close();
      } catch (e) {
        onLog('❌ PDF Render Failed: $e', isError: true);
        print('❌ PDF Render Failed: $e');
        throw Exception('PDF Render Error: $e');
      }
    } else {
      onLog('🖼 STEP 1: Image File Detected');
      print('🖼 STEP 1: Image File Detected');
      imageBase64List.add(base64Encode(fileBytes));
    }

    List<BomItem> totalBom = [];
    List<Spool> totalSpools = [];


    for (int index = 0; index < imageBase64List.length; index++) {
      final base64Image = imageBase64List[index];

      if (index > 0) {
        onLog('⏳ Delay 3s before Page ${index + 1}...');
        print('⏳ Delay 3s before Page ${index + 1}...');
        await Future.delayed(const Duration(seconds: 3));
      }

      onLog('🤖 STEP 2: Processing Page ${index + 1}/${imageBase64List.length} with Gemini 3.6 Flash...');
      print('🤖 STEP 2: Processing Page ${index + 1}/${imageBase64List.length} with Gemini 3.6 Flash...');

      bool pageSuccess = false;
      int retries = 0;
      const int maxRetries = 3;

      while (!pageSuccess && retries < maxRetries) {
        try {
          final response = await http.post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent'
            ),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {
                        'mime_type': isPdf ? 'image/jpeg' : 'image/png',
                        'data': base64Image,
                      }
                    }
                  ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 90));

          onLog('📡 Response Status Code: ${response.statusCode}');
          print('📡 Response Status Code: ${response.statusCode}');

          if (response.statusCode == 200) {
            final body = json.decode(response.body);
            final String rawText = body['candidates'][0]['content']['parts'][0]['text'];

            final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
            final match = jsonRegex.firstMatch(rawText);
            final cleanJsonText = match != null ? match.group(0)! : rawText;

            final Map<String, dynamic> jsonMap = json.decode(cleanJsonText);

            final String drawingNo = jsonMap['drawing_no']?.toString() ?? '';
            final String lineNo = jsonMap['line_no']?.toString() ?? '';

            if (jsonMap['bom'] != null) {
              final pageBom = (jsonMap['bom'] as List).map((e) {
                e['drawing_no'] = drawingNo;
                e['line_no'] = lineNo;
                return BomItem.fromJson(e);
              }).toList();
              totalBom.addAll(pageBom);
              onLog('✓ Extracted ${pageBom.length} BOM Items from Page ${index + 1}', isSuccess: true);
              print('✓ Extracted ${pageBom.length} BOM Items from Page ${index + 1}');
            }

            if (jsonMap['spools'] != null) {
              final pageSpools = (jsonMap['spools'] as List).map((e) {
                e['drawing_no'] = drawingNo;
                e['line_no'] = lineNo;
                return Spool.fromJson(e);
              }).toList();
              totalSpools.addAll(pageSpools);
              onLog('✓ Extracted ${pageSpools.length} Spools from Page ${index + 1}', isSuccess: true);
              print('✓ Extracted ${pageSpools.length} Spools from Page ${index + 1}');
            }

            pageSuccess = true;
          } else if (response.statusCode == 429) {
            print("429 body :${response.body}");
            retries++;
            int waitTime = 20 * retries; // 20s, 40s wait
            onLog('⏳ Rate Limit (429) hit. Waiting $waitTime seconds before Retry $retries/$maxRetries...', isError: true);
            print('⏳ Rate Limit (429) hit. Waiting $waitTime seconds before Retry $retries/$maxRetries...');

            await Future.delayed(Duration(seconds: waitTime));
          } else {
            onLog('❌ Gemini API Error (${response.statusCode}): ${response.body}', isError: true);
            print('❌ Gemini API Error (${response.statusCode}): ${response.body}');
            break;
          }
        } catch (e) {
          retries++;
          onLog('❌ Exception on Page ${index + 1}: $e. Retrying in 10s...', isError: true);
          print('❌ Exception on Page ${index + 1}: $e. Retrying in 10s...');
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }

    onLog('🎉 SUCCESS: Total ${totalBom.length} Items & ${totalSpools.length} Spools Extracted!', isSuccess: true);
    print('🎉 SUCCESS: Total ${totalBom.length} Items & ${totalSpools.length} Spools Extracted!');
    return {'bom': totalBom, 'spools': totalSpools};
  }
}
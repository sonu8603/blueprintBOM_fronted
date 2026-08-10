// import 'dart:io';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import '../models/bom_item.dart';
// import '../models/spool.dart';
//
// class ExcelExportService {
//   // 🟢 1. Common Single Table Exporter
//   static Future<void> exportCustomList({
//     required String fileName,
//     required String sheetName,
//     required List<String> headers,
//     required List<List<dynamic>> rows,
//   }) async {
//     final excel = Excel.createExcel();
//     final Sheet sheet = excel[sheetName];
//
//     if (excel.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
//       excel.delete('Sheet1');
//     }
//
//     sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
//
//     for (final row in rows) {
//       sheet.appendRow(row.map((val) => TextCellValue(val.toString())).toList());
//     }
//
//     await _saveAndShareExcel(excel, fileName);
//   }
//
//   // 🟢 2. DUMP BOM + SPOOL Multi-Sheet Exporter (Matches DumpBomScreen)
//   static Future<void> exportAndShare(List<BomItem> bomItems, List<Spool> spools) async {
//     final excel = Excel.createExcel();
//
//     // Sheet 1: DUMP BOM
//     final Sheet bomSheet = excel['DUMP BOM'];
//     bomSheet.appendRow([
//       TextCellValue('S.NO'),
//       TextCellValue('DRG NO.'),
//       TextCellValue('LINE NO.'),
//       TextCellValue('ND/SIZE'),
//       TextCellValue('QTY'),
//       TextCellValue('UOM'),
//       TextCellValue('DESCRIPTION'),
//       TextCellValue('CATEGORY'),
//     ]);
//
//     for (int i = 0; i < bomItems.length; i++) {
//       final item = bomItems[i];
//       bomSheet.appendRow([
//         TextCellValue((i + 1).toString()),
//         TextCellValue(item.drawingNo),
//         TextCellValue(item.lineNo),
//         TextCellValue(item.nd),
//         TextCellValue(item.qty.toString()),
//         TextCellValue(item.uom),
//         TextCellValue(item.description),
//         TextCellValue(item.category),
//       ]);
//     }
//
//     // Sheet 2: SPOOL TRACKER
//     final Sheet spoolSheet = excel['SPOOL TRACKER'];
//     spoolSheet.appendRow([
//       TextCellValue('S.NO'),
//       TextCellValue('DRG NO.'),
//       TextCellValue('SPOOL MARK'),
//       TextCellValue('LINE NO.'),
//       TextCellValue('SIZE'),
//       TextCellValue('MATERIAL'),
//       TextCellValue('STATUS'),
//     ]);
//
//     for (int i = 0; i < spools.length; i++) {
//       final item = spools[i];
//       spoolSheet.appendRow([
//         TextCellValue((i + 1).toString()),
//         TextCellValue(item.drawingNo),
//         TextCellValue(item.spoolMarkNo),
//         TextCellValue(item.lineNo),
//         TextCellValue(item.size),
//         TextCellValue(item.material),
//         TextCellValue(item.dispatchStatus),
//       ]);
//     }
//
//     if (excel.sheets.containsKey('Sheet1')) {
//       excel.delete('Sheet1');
//     }
//
//     await _saveAndShareExcel(excel, 'ISO_BOM_Export.xlsx');
//   }
//
//   // 🟢 3. Pipe BOM Specific Export
//   static Future<void> exportPipeBom(List<BomItem> bomItems) async {
//     final pipeItems = bomItems.where((e) => e.category.toUpperCase() == 'PIPE').toList();
//
//     final headers = ['S.NO', 'DRG NO.', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION'];
//     final rows = List.generate(pipeItems.length, (i) {
//       final item = pipeItems[i];
//       return [i + 1, item.drawingNo, item.lineNo, item.nd, item.qty, item.uom, item.description];
//     });
//
//     await exportCustomList(
//       fileName: 'PIPE_BOM_Export.xlsx',
//       sheetName: 'PIPE BOM',
//       headers: headers,
//       rows: rows,
//     );
//   }
//
//   // 🟢 4. ISO Wise Grouped Export
//   static Future<void> exportIsoWiseBom(List<BomItem> bomItems) async {
//     final excel = Excel.createExcel();
//
//     final Map<String, List<BomItem>> groupedByIso = {};
//     for (var item in bomItems) {
//       final key = item.drawingNo.isEmpty ? 'UNKNOWN_ISO' : item.drawingNo;
//       groupedByIso.putIfAbsent(key, () => []).add(item);
//     }
//
//     final headers = ['S.NO', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION', 'CATEGORY'];
//
//     groupedByIso.forEach((isoName, items) {
//       final cleanSheetName = isoName.length > 30 ? isoName.substring(0, 30) : isoName;
//       final sheet = excel[cleanSheetName];
//
//       sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
//
//       for (int i = 0; i < items.length; i++) {
//         final item = items[i];
//         sheet.appendRow([
//           TextCellValue((i + 1).toString()),
//           TextCellValue(item.lineNo),
//           TextCellValue(item.nd),
//           TextCellValue(item.qty.toString()),
//           TextCellValue(item.uom),
//           TextCellValue(item.description),
//           TextCellValue(item.category),
//         ]);
//       }
//     });
//
//     if (excel.sheets.containsKey('Sheet1') && groupedByIso.isNotEmpty) {
//       excel.delete('Sheet1');
//     }
//
//     await _saveAndShareExcel(excel, 'ISO_Wise_BOM_Export.xlsx');
//   }
//
//   // 🟢 Helper Function
//   static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
//     final fileBytes = excel.save();
//     if (fileBytes == null) return;
//
//     final directory = await getTemporaryDirectory();
//     final filePath = '${directory.path}/$fileName';
//     final file = File(filePath);
//
//     await file.writeAsBytes(fileBytes);
//     await Share.shareXFiles([XFile(filePath)], text: 'Exported Excel File: $fileName');
//   }
// }




// new direct download


import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bom_item.dart';
import '../models/spool.dart';

class ExcelExportService {
  // 🟢 1. DIRECT MOBILE DOWNLOAD (Saves directly to Download folder)
  static Future<String?> downloadToPhone(List<BomItem> bomItems, List<Spool> spools) async {
    final excel = _generateExcelWorkbook(bomItems, spools);
    return await _saveFileToMobileStorage(excel, 'ISO_BOM_Export.xlsx');
  }

  // 🟢 2. SHARE VIA APPS (Opens Gmail, WhatsApp, Drive Share Sheet)
  static Future<void> shareExcelFile(List<BomItem> bomItems, List<Spool> spools) async {
    final excel = _generateExcelWorkbook(bomItems, spools);

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/ISO_BOM_Export.xlsx';
    final file = File(filePath);

    await file.writeAsBytes(fileBytes);
    await Share.shareXFiles([XFile(filePath)], text: 'Exported Excel File');
  }

  // 🟢 3. Pipe BOM Specific Export
  static Future<String?> exportPipeBom(List<BomItem> bomItems) async {
    try{
      final pipeItems = bomItems.where((e) => e.category.toUpperCase() == 'PIPE').toList();

      final headers = ['S.NO', 'DRG NO.', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION'];
      final rows = List.generate(pipeItems.length, (i) {
        final item = pipeItems[i];
        return [i + 1, item.drawingNo, item.lineNo, item.nd, item.qty, item.uom, item.description];
      });

      final excel = Excel.createExcel();
      final Sheet sheet = excel['PIPE BOM'];
      if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
      for (final row in rows) {
        sheet.appendRow(row.map((val) => TextCellValue(val.toString())).toList());
      }

      return await _saveFileToMobileStorage(excel, 'PIPE_BOM_Export.xlsx');


    }
    catch(err){
      print("error of pipe bom fn $err");
      return null;

    }
  }

  // 🟢 4. ISO Wise Grouped Export
  static Future<String?> exportIsoWiseBom(List<BomItem> bomItems) async {
    try{
      final excel = Excel.createExcel();

      final Map<String, List<BomItem>> groupedByIso = {};
      for (var item in bomItems) {
        final key = item.drawingNo.isEmpty ? 'UNKNOWN_ISO' : item.drawingNo;
        groupedByIso.putIfAbsent(key, () => []).add(item);
      }

      final headers = ['S.NO', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION', 'CATEGORY'];

      groupedByIso.forEach((isoName, items) {
        final cleanSheetName = isoName.length > 30 ? isoName.substring(0, 30) : isoName;
        final sheet = excel[cleanSheetName];

        sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          sheet.appendRow([
            TextCellValue((i + 1).toString()),
            TextCellValue(item.lineNo),
            TextCellValue(item.nd),
            TextCellValue(item.qty.toString()),
            TextCellValue(item.uom),
            TextCellValue(item.description),
            TextCellValue(item.category),
          ]);
        }
      });

      if (excel.sheets.containsKey('Sheet1') && groupedByIso.isNotEmpty) {
        excel.delete('Sheet1');
      }

      return await _saveFileToMobileStorage(excel, 'ISO_Wise_BOM_Export.xlsx');



    }
    catch(err){
      print('❌ ISO Wise BOM Export Error: $err');
      return null;
    }
  }

  // Helper: Generates Excel Workbook with DUMP BOM and SPOOL TRACKER
  static Excel _generateExcelWorkbook(List<BomItem> bomItems, List<Spool> spools) {
    final excel = Excel.createExcel();

    // Sheet 1: DUMP BOM
    final Sheet bomSheet = excel['DUMP BOM'];
    bomSheet.appendRow([
      TextCellValue('S.NO'),
      TextCellValue('DRG NO.'),
      TextCellValue('LINE NO.'),
      TextCellValue('ND/SIZE'),
      TextCellValue('QTY'),
      TextCellValue('UOM'),
      TextCellValue('DESCRIPTION'),
      TextCellValue('CATEGORY'),
    ]);

    for (int i = 0; i < bomItems.length; i++) {
      final item = bomItems[i];
      bomSheet.appendRow([
        TextCellValue((i + 1).toString()),
        TextCellValue(item.drawingNo),
        TextCellValue(item.lineNo),
        TextCellValue(item.nd),
        TextCellValue(item.qty.toString()),
        TextCellValue(item.uom),
        TextCellValue(item.description),
        TextCellValue(item.category),
      ]);
    }

    // Sheet 2: SPOOL TRACKER
    final Sheet spoolSheet = excel['SPOOL TRACKER'];
    spoolSheet.appendRow([
      TextCellValue('S.NO'),
      TextCellValue('DRG NO.'),
      TextCellValue('SPOOL MARK'),
      TextCellValue('LINE NO.'),
      TextCellValue('SIZE'),
      TextCellValue('MATERIAL'),
      TextCellValue('NOS OFF'),
      TextCellValue('WELD TYPE'),
      TextCellValue('DISPATCH STATUS'),
      TextCellValue('REMARKS'),
    ]);

    for (int i = 0; i < spools.length; i++) {
      final item = spools[i];
      spoolSheet.appendRow([
        TextCellValue((i + 1).toString()),
        TextCellValue(item.drawingNo),
        TextCellValue(item.spoolMarkNo),
        TextCellValue(item.lineNo),
        TextCellValue(item.size),
        TextCellValue(item.material),
        TextCellValue(item.nosOff),
        TextCellValue(item.weldType),
        TextCellValue(item.dispatchStatus),
        TextCellValue(item.remarks),
      ]);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel;
  }

  // Helper: Saves file to mobile storage


  static Future<String?> _saveFileToMobileStorage(
      Excel excel,
      String fileName,
      ) async {
    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final cleanName = fileName.toLowerCase().endsWith('.xlsx')
        ? fileName.substring(0, fileName.length - 5)
        : fileName;

    final Uint8List bytesList = Uint8List.fromList(fileBytes);

    try {
      if (Platform.isAndroid) {
        // 🟢 1. Storage Permissions Request
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();

        // 🟢 2. Direct Public Download Directory Path
        final publicDownloadDir = Directory('/storage/emulated/0/Download');

        if (await publicDownloadDir.exists()) {
          final filePath = '${publicDownloadDir.path}/$cleanName.xlsx';
          final file = File(filePath);
          await file.writeAsBytes(bytesList);
          return filePath;
        }
      }

      // 🟢 3. Fallback using FileSaver (ext parameter removed)
      final savedPath = await FileSaver.instance.saveFile(
        name: '$cleanName.xlsx',
        bytes: bytesList,
        mimeType: MimeType.microsoftExcel,
      );

      return savedPath;
    } catch (e) {
      print('❌ File Save Error: $e');
      return null;
    }
  }
}
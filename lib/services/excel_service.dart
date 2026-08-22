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
  // 🟢 1. DIRECT MOBILE DOWNLOAD
  static Future<String?> downloadToPhone(List<BomItem> bomItems, List<Spool> spools) async {
    final excel = _generateExcelWorkbook(bomItems, spools);
    return await _saveFileToMobileStorage(excel, 'ISO_BOM_Export.xlsx');
  }

  // 🟢 2. SHARE VIA APPS
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
    try {
      final pipeItems = bomItems.where((e) => e.category.trim().toUpperCase() == 'PIPE').toList();

      final headers = ['S.NO', 'DRG NO.', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION'];
      final rows = List.generate(pipeItems.length, (i) {
        final item = pipeItems[i];
        return [
          i + 1,
          item.drawingNo,
          item.lineNo,
          item.nd,
          item.qty,
          item.uom,
          item.description,
        ];
      });

      final excel = Excel.createExcel();
      final Sheet sheet = excel['PIPE BOM'];
      if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
      for (final row in rows) {
        sheet.appendRow(row.map((val) => TextCellValue(val.toString())).toList());
      }

      _autoFitColumnWidths(sheet);

      return await _saveFileToMobileStorage(excel, 'PIPE_BOM_Export.xlsx');
    } catch (err) {
      print("❌ Pipe BOM Export Error: $err");
      return null;
    }
  }

  // 🟢 4. ISO Wise Grouped Export
  static Future<String?> exportIsoWiseBom(List<BomItem> bomItems) async {
    try {
      final excel = Excel.createExcel();

      final Map<String, List<BomItem>> groupedByIso = {};
      for (var item in bomItems) {
        final key = item.drawingNo.trim().isEmpty ? 'UNKNOWN_ISO' : item.drawingNo;
        groupedByIso.putIfAbsent(key, () => []).add(item);
      }

      final headers = ['S.NO', 'LINE NO.', 'ND/SIZE', 'QTY', 'UOM', 'DESCRIPTION', 'CATEGORY'];
      final Set<String> usedSheetNames = {};

      groupedByIso.forEach((isoName, items) {
        String baseSheetName = _sanitizeSheetName(isoName);
        String finalSheetName = baseSheetName;
        int counter = 1;

        while (usedSheetNames.contains(finalSheetName.toUpperCase())) {
          finalSheetName = '${baseSheetName}_$counter';
          counter++;
        }
        usedSheetNames.add(finalSheetName.toUpperCase());

        final sheet = excel[finalSheetName];
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

        _autoFitColumnWidths(sheet);
      });

      if (excel.sheets.containsKey('Sheet1') && groupedByIso.isNotEmpty) {
        excel.delete('Sheet1');
      }

      return await _saveFileToMobileStorage(excel, 'ISO_Wise_BOM_Export.xlsx');
    } catch (err) {
      print('❌ ISO Wise BOM Export Error: $err');
      return null;
    }
  }

  // 🟢 5. Auto Adjust Column Width Function
  static void _autoFitColumnWidths(Sheet sheet) {
    for (int col = 0; col < sheet.maxColumns; col++) {
      double maxLen = 10.0;
      for (int row = 0; row < sheet.maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        final val = cell.value?.toString() ?? '';
        if (val.length > maxLen) {
          maxLen = val.length.toDouble();
        }
      }
      sheet.setColumnWidth(col, (maxLen + 5.0).clamp(14.0, 65.0));
    }
  }

  // Helper: Sanitizer for Sheet Names
  static String _sanitizeSheetName(String name) {
    var clean = name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_');
    if (clean.length > 28) clean = clean.substring(0, 28);
    return clean.trim().isEmpty ? 'SHEET' : clean;
  }

  // Helper: DUMP BOM & SPOOL TRACKER Workbook
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
    _autoFitColumnWidths(bomSheet);

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
    _autoFitColumnWidths(spoolSheet);

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel;
  }

  // Helper: File Saver
  static Future<String?> _saveFileToMobileStorage(
      Excel excel,
      String fileName,
      ) async {
    try {
      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      final cleanName = fileName.toLowerCase().endsWith('.xlsx')
          ? fileName.substring(0, fileName.length - 5)
          : fileName;

      final Uint8List bytesList = Uint8List.fromList(fileBytes);

      if (Platform.isAndroid) {
        try {
          await Permission.storage.request();
          final publicDownloadDir = Directory('/storage/emulated/0/Download');

          if (await publicDownloadDir.exists()) {
            final filePath = '${publicDownloadDir.path}/$cleanName.xlsx';
            final file = File(filePath);
            await file.writeAsBytes(bytesList, flush: true);
            return filePath;
          }
        } catch (e) {
          print('Direct write failed, falling back to FileSaver: $e');
        }
      }

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
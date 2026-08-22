import 'bom_item.dart';
import 'spool.dart';

class DrawingRevision {
  final String id;
  final String drawingNo;
  final String lineNo;
  final DateTime timestamp;
  final List<BomItem> bomItems;
  final List<Spool> spools;

  DrawingRevision({
    required this.id,
    required this.drawingNo,
    required this.lineNo,
    required this.timestamp,
    required this.bomItems,
    required this.spools,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'drawingNo': drawingNo,
    'drawing_no': drawingNo,
    'lineNo': lineNo,
    'line_no': lineNo,
    'timestamp': timestamp.toIso8601String(),
    'bom': bomItems.map((e) => e.toJson()).toList(),
    'bomItems': bomItems.map((e) => e.toJson()).toList(),
    'spools': spools.map((e) => e.toJson()).toList(),
  };

  factory DrawingRevision.fromJson(Map<String, dynamic> json) {

    final parentDrawingNo = (json['drawingNo'] ?? json['drawing_no'] ?? 'UNKNOWN').toString();
    final parentLineNo = (json['lineNo'] ?? json['line_no'] ?? 'N/A').toString();

    final rawBom = (json['bom'] ?? json['bomItems']) as List? ?? [];
    final rawSpools = (json['spools'] ?? json['spoolItems']) as List? ?? [];
    final List<BomItem> enrichedBom = rawBom.map((item) {
      final itemMap = Map<String, dynamic>.from(item as Map);

      if (itemMap['drawing_no'] == null || itemMap['drawing_no'].toString().trim().isEmpty) {
        itemMap['drawing_no'] = parentDrawingNo;
      }
      if (itemMap['drawingNo'] == null || itemMap['drawingNo'].toString().trim().isEmpty) {
        itemMap['drawingNo'] = parentDrawingNo;
      }
      if (itemMap['line_no'] == null || itemMap['line_no'].toString().trim().isEmpty) {
        itemMap['line_no'] = parentLineNo;
      }
      if (itemMap['lineNo'] == null || itemMap['lineNo'].toString().trim().isEmpty) {
        itemMap['lineNo'] = parentLineNo;
      }

      return BomItem.fromJson(itemMap);
    }).toList();

    return DrawingRevision(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      drawingNo: parentDrawingNo,
      lineNo: parentLineNo,
      timestamp: DateTime.tryParse(
        json['updatedAt']?.toString() ?? json['timestamp']?.toString() ?? '',
      ) ??
          DateTime.now(),
      bomItems: enrichedBom,
      spools: rawSpools.map((e) => Spool.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
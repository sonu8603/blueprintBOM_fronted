import '../models/bom_item.dart';
import '../models/spool.dart';


class ExtractionResult {
  final List<BomItem> bomItems;
  final List<Spool> spools;

  ExtractionResult({
    required this.bomItems,
    required this.spools,
  });
}
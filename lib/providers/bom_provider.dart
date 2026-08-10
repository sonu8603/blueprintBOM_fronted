import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bom_item.dart';

class BomNotifier extends Notifier<List<BomItem>> {
  @override
  List<BomItem> build() => [];

  void addItems(List<BomItem> newItems) {
    state = [...state, ...newItems];
  }

  void addItem(BomItem item) {
    state = [...state, item];
  }

  void updateItem(int index, BomItem item) {
    final updated = [...state];
    updated[index] = item;
    state = updated;
  }

  void removeItem(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void mergeDuplicates() {
    final Map<String, BomItem> mergedMap = {};

    for (final item in state) {

      final cleanDesc = item.description.trim().toLowerCase();
      final cleanNd = item.nd.trim().toLowerCase();
      final cleanUom = item.uom.trim().toLowerCase();
      final cleanDrg = item.drawingNo.trim().toLowerCase();
      final cleanLine = item.lineNo.trim().toLowerCase();

      // Unique Unique Grouping Key
      final key = '${cleanDrg}_${cleanLine}_${cleanNd}_${cleanDesc}_$cleanUom';

      if (mergedMap.containsKey(key)) {
        final existing = mergedMap[key]!;

        mergedMap[key] = existing.copyWith(
          qty: existing.qty + item.qty,
        );
      } else {
        mergedMap[key] = item.copyWith(
          description: item.description.trim(),
          nd: item.nd.trim(),
          uom: item.uom.trim(),
          drawingNo: item.drawingNo.trim(),
          lineNo: item.lineNo.trim(),
        );
      }
    }

    // 🟢 Riverpod UI Refresh ke liye state ko naye list reference se assign karein
    state = mergedMap.values.toList();
  }

  void setAll(List<BomItem> items) {
    state = items;
  }
}

final bomProvider = NotifierProvider<BomNotifier, List<BomItem>>(BomNotifier.new);
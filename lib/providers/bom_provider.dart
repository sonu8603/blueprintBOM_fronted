import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bom_item.dart';
import '../services/local_file_storage.dart';


class BomNotifier extends Notifier<List<BomItem>> {
  @override
  List<BomItem> build() {
    _loadFromCache(); // 🟢 App launch/restart par background se cache read karein
    return [];
  }

  Future<void> _loadFromCache() async {
    final cachedItems = await LocalStorageService.getBomItems();
    if (cachedItems.isNotEmpty) {
      state = cachedItems;
    }
  }

  void addItems(List<BomItem> newItems) {
    state = [...state, ...newItems];
    LocalStorageService.saveBomItems(state); // 🟢 Save to Disk
  }

  void addItem(BomItem item) {
    state = [...state, item];
    LocalStorageService.saveBomItems(state); // 🟢 Save to Disk
  }

  void updateItem(int index, BomItem item) {
    final updated = [...state];
    updated[index] = item;
    state = updated;
    LocalStorageService.saveBomItems(state); // 🟢 Save to Disk
  }

  void removeItem(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
    LocalStorageService.saveBomItems(state); // 🟢 Save to Disk
  }

  void mergeDuplicates() {
    final Map<String, BomItem> mergedMap = {};

    for (final item in state) {
      final cleanDesc = item.description.trim().toLowerCase();
      final cleanNd = item.nd.trim().toLowerCase();
      final cleanUom = item.uom.trim().toLowerCase();
      final cleanDrg = item.drawingNo.trim().toLowerCase();
      final cleanLine = item.lineNo.trim().toLowerCase();

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

    state = mergedMap.values.toList();
    LocalStorageService.saveBomItems(state); // 🟢 Save Merged List
  }

  void setAll(List<BomItem> items) {
    state = items;
    LocalStorageService.saveBomItems(state); // 🟢 Save to Disk
  }

  void clear() {
    state = [];
    LocalStorageService.saveBomItems([]);
  }
}

final bomProvider = NotifierProvider<BomNotifier, List<BomItem>>(BomNotifier.new);
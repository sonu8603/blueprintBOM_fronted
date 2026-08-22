import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bom_item.dart';
import '../models/drawing_revision_model.dart';
import '../revision_notes/local_storage_service.dart' as LocalStorageService;



class RevisionNotifier extends Notifier<List<DrawingRevision>> {
  @override
  List<DrawingRevision> build() {
    _loadFromCache();
    return [];
  }

  Future<void> _loadFromCache() async {
    final cached = await LocalStorageService.getRevisions();
    if (cached.isNotEmpty) {
      state = cached;
    }
  }

  void addRevision(DrawingRevision revision) {
    // Nayi drawing list ke top par aayegi
    state = [revision, ...state];
    LocalStorageService.saveRevisions(state);
  }
  // mege button dabate hi revision screen me update ke liye
  void updateDrawingBom(List<BomItem> updatedBom) {
    if (state.isEmpty || updatedBom.isEmpty) return;

    final String targetDrawingNo = updatedBom.first.drawingNo;

    final updatedList = state.map((rev) {
      // Agar drawing number match kare ya single drawing ho toh update karein
      if (rev.drawingNo == targetDrawingNo || state.length == 1) {
        return DrawingRevision(
          id: rev.id,
          drawingNo: rev.drawingNo,
          lineNo: rev.lineNo,
          timestamp: DateTime.now(),
          bomItems: updatedBom,
          spools: rev.spools,
        );
      }
      return rev;
    }).toList();

    state = updatedList;
    LocalStorageService.saveRevisions(state);
  }

  void removeRevision(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
    LocalStorageService.saveRevisions(state);
  }

  void clearAll() {
    state = [];
    LocalStorageService.saveRevisions([]);
  }
}

final revisionProvider =
NotifierProvider<RevisionNotifier, List<DrawingRevision>>(RevisionNotifier.new);
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spool.dart';
import '../services/local_file_storage.dart';


class SpoolNotifier extends Notifier<List<Spool>> {
  @override
  List<Spool> build() {
    _loadFromCache();
    return [];
  }

  Future<void> _loadFromCache() async {
    final cachedSpools = await LocalStorageService.getSpools();
    if (cachedSpools.isNotEmpty) {
      state = cachedSpools;
    }
  }

  void addSpools(List<Spool> spools) {
    state = [...state, ...spools];
    LocalStorageService.saveSpools(state);
  }

  void updateStatus(int index, String status) {
    final updated = [...state];
    updated[index].dispatchStatus = status;
    state = updated;
    LocalStorageService.saveSpools(state);
  }

  void removeSpool(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
    LocalStorageService.saveSpools(state); // 🟢 Save to Disk
  }

  void setAll(List<Spool> spools) {
    state = spools;
    LocalStorageService.saveSpools(state); // 🟢 Save to Disk
  }

  void clear() {
    state = [];
    LocalStorageService.saveSpools([]);
  }
}

final spoolProvider = NotifierProvider<SpoolNotifier, List<Spool>>(SpoolNotifier.new);
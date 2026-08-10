import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spool.dart';

class SpoolNotifier extends Notifier<List<Spool>> {
  @override
  List<Spool> build() => [];

  void addSpools(List<Spool> spools) {
    state = [...state, ...spools];
  }

  void updateStatus(int index, String status) {
    final updated = [...state];
    updated[index].dispatchStatus = status;
    state = updated;
  }

  void removeSpool(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void setAll(List<Spool> spools) {
    state = spools;
  }
}

final spoolProvider = NotifierProvider<SpoolNotifier, List<Spool>>(SpoolNotifier.new);
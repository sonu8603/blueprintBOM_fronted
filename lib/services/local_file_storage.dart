import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bom_item.dart';
import '../models/spool.dart';

class LocalStorageService {
  static const String _bomKey = 'cached_bom_items';
  static const String _spoolKey = 'cached_spool_items';

  static Future<void> saveBomItems(List<BomItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_bomKey, json.encode(jsonList));
  }

  static Future<List<BomItem>> getBomItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_bomKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = json.decode(jsonString);
      return decoded.map((e) => BomItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSpools(List<Spool> spools) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = spools.map((e) => e.toJson()).toList();
    await prefs.setString(_spoolKey, json.encode(jsonList));
  }

  static Future<List<Spool>> getSpools() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_spoolKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = json.decode(jsonString);
      return decoded.map((e) => Spool.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bomKey);
    await prefs.remove(_spoolKey);
  }
}
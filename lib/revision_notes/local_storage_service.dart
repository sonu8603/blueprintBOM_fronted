import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/drawing_revision_model.dart';

// Class ke andar add karein:
 const String _revisionsKey = 'cached_revisions_list';

 Future<void> saveRevisions(List<DrawingRevision> list) async {
final prefs = await SharedPreferences.getInstance();
final jsonList = list.map((e) => e.toJson()).toList();
await prefs.setString(_revisionsKey, json.encode(jsonList));
}

 Future<List<DrawingRevision>> getRevisions() async {
final prefs = await SharedPreferences.getInstance();
final String? str = prefs.getString(_revisionsKey);
if (str == null || str.isEmpty) return [];
try {
final List decoded = json.decode(str);
return decoded.map((e) => DrawingRevision.fromJson(e)).toList();
} catch (_) {
return [];
}
}
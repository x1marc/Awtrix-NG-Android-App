import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistente Favoriten: Moodlight-Farben (Hex) und Benachrichtigungs-Vorlagen.
class FavStore {
  static const _moodKey = 'fav_moodlight';
  static const _notifyKey = 'fav_notify';

  static Future<List<String>> moodColors() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_moodKey) ?? <String>[];
  }

  static Future<void> setMoodColors(List<String> hex) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_moodKey, hex);
  }

  static Future<List<String>> addMoodColor(String hex) async {
    final list = await moodColors();
    if (!list.contains(hex)) {
      list.insert(0, hex);
      while (list.length > 12) {
        list.removeLast();
      }
      await setMoodColors(list);
    }
    return list;
  }

  static Future<List<Map<String, dynamic>>> notifyPresets() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getStringList(_notifyKey) ?? <String>[];
    final out = <Map<String, dynamic>>[];
    for (final e in s) {
      try {
        final m = jsonDecode(e);
        if (m is Map) out.add(m.cast<String, dynamic>());
      } catch (_) {}
    }
    return out;
  }

  static Future<void> setNotifyPresets(List<Map<String, dynamic>> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_notifyKey, list.map(jsonEncode).toList());
  }

  static Future<List<Map<String, dynamic>>> addNotifyPreset(
      Map<String, dynamic> preset) async {
    final list = await notifyPresets();
    list.insert(0, preset);
    while (list.length > 20) {
      list.removeLast();
    }
    await setNotifyPresets(list);
    return list;
  }

  static Future<List<Map<String, dynamic>>> removeNotifyPreset(int i) async {
    final list = await notifyPresets();
    if (i >= 0 && i < list.length) list.removeAt(i);
    await setNotifyPresets(list);
    return list;
  }
}

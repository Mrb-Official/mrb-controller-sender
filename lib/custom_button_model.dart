import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomButton {
  String id;
  String name;
  String emoji;
  bool isHold; // true = hold, false = tap

  CustomButton({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isHold,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'emoji': emoji, 'isHold': isHold,
  };

  factory CustomButton.fromJson(Map<String, dynamic> j) => CustomButton(
    id: j['id'], name: j['name'], emoji: j['emoji'], isHold: j['isHold'],
  );
}

class ButtonStorage {
  static const _key = 'custom_buttons';

  static Future<List<CustomButton>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CustomButton.fromJson(e)).toList();
  }

  static Future<void> save(List<CustomButton> buttons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(buttons.map((b) => b.toJson()).toList()));
  }
}

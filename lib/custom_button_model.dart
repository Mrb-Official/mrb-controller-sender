import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomButton {
  String id;
  String name;
  String icon;
  bool isHold;
  double x;
  double y;

  CustomButton({
    required this.id,
    required this.name,
    required this.icon,
    required this.isHold,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon,
    'isHold': isHold, 'x': x, 'y': y,
  };

  factory CustomButton.fromJson(Map<String, dynamic> j) => CustomButton(
    id: j['id'], name: j['name'],
    icon: j['icon'] ?? 'gamepad',
    isHold: j['isHold'],
    x: (j['x'] ?? 0.0).toDouble(),
    y: (j['y'] ?? 0.0).toDouble(),
  );
}

List<CustomButton> defaultButtons() => [
  CustomButton(id: 'brake',      name: 'BRAKE',  icon: 'pan_tool',    isHold: true,  x: 235,  y: 720),
  CustomButton(id: 'gas',        name: 'GAS',    icon: 'speed',       isHold: true,  x: 2192, y: 850),
  CustomButton(id: 'gear_up',    name: 'GEAR+',  icon: 'expand_less', isHold: false, x: 1900, y: 600),
  CustomButton(id: 'gear_down',  name: 'GEAR-',  icon: 'expand_more', isHold: false, x: 1900, y: 900),
];

class ButtonStorage {
  static const _key = 'custom_buttons_v2';

  static Future<List<CustomButton>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final defaults = defaultButtons();
      await save(defaults);
      return defaults;
    }
    final list = jsonDecode(raw) as List;
    return list.map((e) => CustomButton.fromJson(e)).toList();
  }

  static Future<void> save(List<CustomButton> buttons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key,
      jsonEncode(buttons.map((b) => b.toJson()).toList()));
  }
}

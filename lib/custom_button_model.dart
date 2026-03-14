import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomButton {
  String id;
  String name;
  String icon;
  bool isHold;
  double touchX;
  double touchY;
  double uiWidth;
  double uiHeight;
  double uiPosX;
  double uiPosY;
  String swipeDir;   // none, up, down, left, right
  double swipeDist;  // pixels to swipe

  CustomButton({
    required this.id,
    required this.name,
    required this.icon,
    required this.isHold,
    required this.touchX,
    required this.touchY,
    this.uiWidth   = 80,
    this.uiHeight  = 64,
    this.uiPosX    = 0,
    this.uiPosY    = 0,
    this.swipeDir  = 'none',
    this.swipeDist = 100,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon, 'isHold': isHold,
    'touchX': touchX, 'touchY': touchY,
    'uiWidth': uiWidth, 'uiHeight': uiHeight,
    'uiPosX': uiPosX, 'uiPosY': uiPosY,
    'swipeDir': swipeDir, 'swipeDist': swipeDist,
  };

  factory CustomButton.fromJson(Map<String, dynamic> j) => CustomButton(
    id:        j['id'],
    name:      j['name'],
    icon:      j['icon'] ?? 'gamepad',
    isHold:    j['isHold'],
    touchX:    (j['touchX'] ?? j['x'] ?? 0.0).toDouble(),
    touchY:    (j['touchY'] ?? j['y'] ?? 0.0).toDouble(),
    uiWidth:   (j['uiWidth']   ?? 80.0).toDouble(),
    uiHeight:  (j['uiHeight']  ?? 64.0).toDouble(),
    uiPosX:    (j['uiPosX']   ?? 0.0).toDouble(),
    uiPosY:    (j['uiPosY']   ?? 0.0).toDouble(),
    swipeDir:  j['swipeDir']  ?? 'none',
    swipeDist: (j['swipeDist'] ?? 100.0).toDouble(),
  );
}

List<CustomButton> defaultButtons() => [
  CustomButton(id: 'brake',     name: 'BRAKE', icon: 'pan_tool',
    isHold: true,  touchX: 235,  touchY: 720,
    uiWidth: 90, uiHeight: 70, uiPosX: 10,  uiPosY: 160,
    swipeDir: 'none', swipeDist: 0),
  CustomButton(id: 'gas',       name: 'GAS',   icon: 'speed',
    isHold: true,  touchX: 2192, touchY: 850,
    uiWidth: 90, uiHeight: 70, uiPosX: 560, uiPosY: 160,
    swipeDir: 'none', swipeDist: 0),
  CustomButton(id: 'gear_up',   name: 'GEAR+', icon: 'expand_less',
    isHold: false, touchX: 1900, touchY: 600,
    uiWidth: 80, uiHeight: 60, uiPosX: 560, uiPosY: 80,
    swipeDir: 'up', swipeDist: 100),
  CustomButton(id: 'gear_down', name: 'GEAR-', icon: 'expand_more',
    isHold: false, touchX: 1900, touchY: 900,
    uiWidth: 80, uiHeight: 60, uiPosX: 560, uiPosY: 250,
    swipeDir: 'down', swipeDist: 100),
];

class ButtonStorage {
  static const _key = 'custom_buttons_v3';

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

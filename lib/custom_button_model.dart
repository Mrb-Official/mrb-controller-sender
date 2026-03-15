import 'dart:convert';
import 'package:flutter/material.dart';
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
  String swipeDir;
  double swipeDist;
  String side; // 'left' or 'right'

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
    this.side      = 'right',
  });

  Color get pressColor {
    switch (name.toUpperCase()) {
      case 'GAS':     return const Color(0xFF00C853);
      case 'BRAKE':   return const Color(0xFFD50000);
      case 'REVERSE': return const Color(0xFFFF6D00);
      case 'FRONT':   return const Color(0xFF00B0FF);
      case 'GEAR+':   return const Color(0xFF00C853);
      case 'GEAR-':   return const Color(0xFFFF6D00);
      default:        return const Color(0xFFFFFFFF);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon, 'isHold': isHold,
    'touchX': touchX, 'touchY': touchY,
    'uiWidth': uiWidth, 'uiHeight': uiHeight,
    'uiPosX': uiPosX, 'uiPosY': uiPosY,
    'swipeDir': swipeDir, 'swipeDist': swipeDist,
    'side': side,
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
    side:      j['side'] ?? 'right',
  );
}

List<CustomButton> defaultButtons() => [
  CustomButton(
    id: 'brake', name: 'BRAKE', icon: 'pan_tool',
    isHold: true,
    touchX: 1933, touchY: 927,
    uiWidth: 130, uiHeight: 140,
    uiPosX: 10, uiPosY: 160,
    swipeDir: 'none', swipeDist: 0,
    side: 'left', // LEFT side
  ),
  CustomButton(
    id: 'gas', name: 'GAS', icon: 'speed',
    isHold: true,
    touchX: 2192, touchY: 850,
    uiWidth: 130, uiHeight: 140,
    uiPosX: 650, uiPosY: 160,
    swipeDir: 'none', swipeDist: 0,
    side: 'right', // RIGHT side
  ),
  CustomButton(
    id: 'reverse', name: 'REVERSE', icon: 'keyboard_arrow_up',
    isHold: false,
    touchX: 2244, touchY: 592,
    uiWidth: 110, uiHeight: 80,
    uiPosX: 560, uiPosY: 80,
    swipeDir: 'up', swipeDist: 250,
    side: 'right',
  ),
  CustomButton(
    id: 'front', name: 'FRONT', icon: 'keyboard_arrow_down',
    isHold: false,
    touchX: 2244, touchY: 400,
    uiWidth: 110, uiHeight: 80,
    uiPosX: 700, uiPosY: 80,
    swipeDir: 'down', swipeDist: 250,
    side: 'left',
  ),
];

class ButtonStorage {
  static const _key = 'custom_buttons_v6';

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

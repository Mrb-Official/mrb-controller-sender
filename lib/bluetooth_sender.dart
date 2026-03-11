import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothSender {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Devices scan karo
  static Future<List<ScanResult>> scanDevices() async {
    List<ScanResult> results = [];
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    final subscription = FlutterBluePlus.scanResults.listen((r) {
      results = r;
    });
    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();
    subscription.cancel();
    return results;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _device = device;
      
      // Services discover karo
      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _characteristic = char;
            break;
          }
        }
      }
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void sendTilt(double tiltX) {
    final axis = (tiltX / 10.0).clamp(-1.0, 1.0);
    _send('STEER:${axis.toStringAsFixed(3)}');
  }

  void sendGas(bool on) => _send(on ? 'GAS:ON' : 'GAS:OFF');
  void sendBrake(bool on) => _send(on ? 'BRK:ON' : 'BRK:OFF');

  void _send(String msg) {
    if (!_isConnected || _characteristic == null) return;
    try {
      _characteristic!.write(utf8.encode(msg), withoutResponse: true);
    } catch (e) {}
  }

  void dispose() {
    _device?.disconnect();
    _isConnected = false;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothSender {
  BluetoothConnection? _connection;
  bool get isConnected => _connection?.isConnected ?? false;

  // Devices scan karo
  static Future<List<BluetoothDevice>> scanDevices() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices;
  }

  // Connect karo
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      return true;
    } catch (e) {
      return false;
    }
  }

  void sendTilt(double tiltX) {
    // -10 to 10 range ko -1.0 to 1.0 mein convert
    final axis = (tiltX / 10.0).clamp(-1.0, 1.0);
    _send('STEER:${axis.toStringAsFixed(3)}');
  }

  void sendGas(bool on) => _send(on ? 'GAS:ON' : 'GAS:OFF');
  void sendBrake(bool on) => _send(on ? 'BRK:ON' : 'BRK:OFF');

  void _send(String msg) {
    if (!isConnected) return;
    try {
      _connection!.output.add(utf8.encode('$msg\n'));
    } catch (e) {}
  }

  void dispose() {
    _connection?.close();
  }
}

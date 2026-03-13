import 'dart:async';
import 'dart:convert';
import 'dart:io';

class UdpSender {
  final String receiverIp;
  final int port;
  static const Duration _sendInterval = Duration(milliseconds: 20);
  RawDatagramSocket? _socket;
  bool _isConnected = false;
  DateTime _lastSendTime = DateTime.now();

  UdpSender({required this.receiverIp, this.port = 9876});
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
    }
  }

  void sendTilt(double tiltX) {
    final now = DateTime.now();
    if (now.difference(_lastSendTime) >= _sendInterval) {
      _send('STEER:${tiltX.toStringAsFixed(3)}');
      _lastSendTime = now;
    }
  }

  void sendGas(bool isPressed) => _send(isPressed ? 'RACE:ON' : 'RACE:OFF');
  void sendBrake(bool isPressed) => _send(isPressed ? 'BRK:ON' : 'BRK:OFF');

  // Custom button: BTN:<name>:ON / BTN:<name>:OFF
  void sendCustomButton(String name, bool isPressed) {
    _send(isPressed ? 'BTN:$name:ON' : 'BTN:$name:OFF');
  }

  void _send(String payload) {
    if (_socket == null || !_isConnected) return;
    try {
      final data = utf8.encode(payload);
      _socket!.send(data, InternetAddress(receiverIp), port);
    } catch (e) {}
  }

  void dispose() {
    _socket?.close();
    _isConnected = false;
  }
}

import 'dart:convert';
import 'package:udp/udp.dart';

class UdpSender {
  final String receiverIp;
  final int port;
  UDP? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  UdpSender({required this.receiverIp, this.port = 9876});

  Future<void> connect() async {
    try {
      _socket = await UDP.bind(Endpoint.any());
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
    }
  }

  void sendTilt(double tiltX) {
    final axis = (tiltX / 10.0).clamp(-1.0, 1.0);
    _send('STEER:${axis.toStringAsFixed(3)}');
  }

  void sendGas(bool on) => _send(on ? 'GAS:ON' : 'GAS:OFF');
  void sendBrake(bool on) => _send(on ? 'BRK:ON' : 'BRK:OFF');

  void _send(String msg) {
    if (_socket == null || !_isConnected) return;
    try {
      _socket!.send(
        utf8.encode(msg),
        Endpoint.unicast(
          InternetAddress(receiverIp),
          port: Port(port),
        ),
      );
    } catch (e) {}
  }

  void dispose() {
    _socket?.close();
    _isConnected = false;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'sensor_service.dart';
import 'udp_sender.dart';

class SteeringUI extends StatefulWidget {
  const SteeringUI({super.key});
  @override
  State<SteeringUI> createState() => _SteeringUIState();
}

class _SteeringUIState extends State<SteeringUI> {
  final SensorService _sensor = SensorService();
  UdpSender? _udp;
  StreamSubscription<SensorData>? _sensorSub;
  final _ipController = TextEditingController(text: '10.136.131.137');

  bool _isConnected = false;
  bool _gasPressed = false;
  bool _brakePressed = false;
  double _tilt = 0.0;
  String _status = 'IP daalo aur connect karo!';

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) return;
    _udp = UdpSender(receiverIp: _ipController.text);
    await _udp!.connect();
    if (_udp!.isConnected) {
      _sensor.start();
      _sensorSub = _sensor.stream.listen((data) {
        _udp?.sendTilt(data.tiltX);
        if (mounted) setState(() => _tilt = data.tiltX);
      });
      setState(() {
        _isConnected = true;
        _status = 'Connected: ${_ipController.text}';
      });
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensor.stop();
    _udp?.dispose();
    setState(() { _isConnected = false; _status = 'Disconnected'; });
  }

  @override
  void dispose() { _disconnect(); _ipController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('🎮 TILT CONTROLLER',
                style: TextStyle(color: Color(0xFF00D4FF), fontSize: 20,
                    fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 16),

              // IP Field
              if (!_isConnected) ...[
                TextField(
                  controller: _ipController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Receiver IP',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.wifi, color: Color(0xFF00D4FF)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF333355)),
                      borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                      borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.link),
                    label: const Text('CONNECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001A2A),
                      foregroundColor: const Color(0xFF00D4FF),
                      side: const BorderSide(color: Color(0xFF00D4FF)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],

              if (_isConnected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('DISCONNECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1A1A),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111122),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(_status,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              _buildTiltBar(),
              const Spacer(),

              // Brake + Gas buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) { setState(() => _brakePressed = true); _udp?.sendBrake(true); },
                      onTapUp: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
                      onPanEnd: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
                      child: Container(
                        height: 130,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _brakePressed ? Colors.redAccent : const Color(0xFF1A1A2E),
                          border: Border.all(
                            color: _brakePressed ? Colors.red : const Color(0xFF333355), width: 2),
                        ),
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_brakePressed ? '🛑' : '🔴', style: const TextStyle(fontSize: 40)),
                            const Text('BRAKE', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) { setState(() => _gasPressed = true); _udp?.sendGas(true); },
                      onTapUp: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
                      onPanEnd: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
                      child: Container(
                        height: 130,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _gasPressed ? const Color(0xFFFF4500) : const Color(0xFF1A1A2E),
                          border: Border.all(
                            color: _gasPressed ? const Color(0xFFFF6B35) : const Color(0xFF333355), width: 2),
                        ),
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_gasPressed ? '🔥' : '🚗', style: const TextStyle(fontSize: 40)),
                            const Text('GAS', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiltBar() {
    final clamped = _tilt.clamp(-10.0, 10.0);
    final fraction = (clamped + 10) / 20;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('◀ LEFT', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(_tilt.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
            const Text('RIGHT ▶', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF111122),
            borderRadius: BorderRadius.circular(5)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00D4FF), Color(0xFFFF4500)],
                  stops: [0.0, 0.5, 1.0]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

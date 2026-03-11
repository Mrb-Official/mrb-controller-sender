import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'sensor_service.dart';
import 'bluetooth_sender.dart';

class SteeringUI extends StatefulWidget {
  const SteeringUI({super.key});
  @override
  State<SteeringUI> createState() => _SteeringUIState();
}

class _SteeringUIState extends State<SteeringUI> {
  final SensorService _sensor = SensorService();
  final BluetoothSender _bt = BluetoothSender();
  StreamSubscription<SensorData>? _sensorSub;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _gasPressed = false;
  bool _brakePressed = false;
  double _tilt = 0.0;
  String _status = 'Scan karo aur connect karo!';

  Future<void> _scan() async {
    setState(() { _isScanning = true; _status = 'Scanning...'; });
    final devices = await BluetoothSender.scanDevices();
    setState(() {
      _devices = devices;
      _isScanning = false;
      _status = devices.isEmpty ? 'Koi device nahi mila!' : '${devices.length} devices mile!';
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _status = 'Connecting...');
    final ok = await _bt.connect(device);
    if (ok) {
      _sensor.start();
      _sensorSub = _sensor.stream.listen((data) {
        _bt.sendTilt(data.tiltX);
        if (mounted) setState(() => _tilt = data.tiltX);
      });
      setState(() {
        _isConnected = true;
        _selectedDevice = device;
        _status = 'Connected: ${device.name}';
      });
    } else {
      setState(() => _status = 'Connect fail! Try again');
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensor.stop();
    _bt.dispose();
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
    });
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              const Text('🎮 TILT CONTROLLER',
                style: TextStyle(color: Color(0xFF00D4FF), fontSize: 20,
                    fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 16),

              // Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111122),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),

              // Scan Button
              if (!_isConnected) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scan,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: Color(0xFF00D4FF)))
                        : const Icon(Icons.bluetooth_searching,
                            color: Color(0xFF00D4FF)),
                    label: Text(_isScanning ? 'Scanning...' : 'BT Scan',
                        style: const TextStyle(color: Color(0xFF00D4FF))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00D4FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Device List
                if (_devices.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111122),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _devices.map((d) => ListTile(
                        leading: const Icon(Icons.phone_android,
                            color: Color(0xFF00D4FF)),
                        title: Text(d.name ?? 'Unknown',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(d.address,
                            style: const TextStyle(color: Colors.white38)),
                        onTap: () => _connect(d),
                      )).toList(),
                    ),
                  ),
              ],

              // Disconnect button
              if (_isConnected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('DISCONNECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1A1A),
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Tilt Bar
              _buildTiltBar(),

              const Spacer(),

              // Controls — Brake | GAS
              Row(
                children: [
                  // BRAKE
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() => _brakePressed = true);
                        _bt.sendBrake(true);
                      },
                      onTapUp: (_) {
                        setState(() => _brakePressed = false);
                        _bt.sendBrake(false);
                      },
                      onPanEnd: (_) {
                        setState(() => _brakePressed = false);
                        _bt.sendBrake(false);
                      },
                      child: Container(
                        height: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _brakePressed
                              ? Colors.redAccent
                              : const Color(0xFF1A1A2E),
                          border: Border.all(
                            color: _brakePressed
                                ? Colors.red
                                : const Color(0xFF333355),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _brakePressed ? '🛑' : '🔴',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // GAS
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() => _gasPressed = true);
                        _bt.sendGas(true);
                      },
                      onTapUp: (_) {
                        setState(() => _gasPressed = false);
                        _bt.sendGas(false);
                      },
                      onPanEnd: (_) {
                        setState(() => _gasPressed = false);
                        _bt.sendGas(false);
                      },
                      child: Container(
                        height: 120,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _gasPressed
                              ? const Color(0xFFFF4500)
                              : const Color(0xFF1A1A2E),
                          border: Border.all(
                            color: _gasPressed
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFF333355),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _gasPressed ? '🔥' : '🚗',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('◀ LEFT', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(_tilt.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white54,
                    fontSize: 12, fontFamily: 'monospace')),
            const Text('RIGHT ▶', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF111122),
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00D4FF), Color(0xFFFF4500)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

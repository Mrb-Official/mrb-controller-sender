import 'dart:async';
import 'package:flutter/material.dart';
import 'sensor_service.dart';
import 'udp_sender.dart';
import 'device_scanner.dart';

class SteeringUI extends StatefulWidget {
  const SteeringUI({super.key});

  @override
  State<SteeringUI> createState() => _SteeringUIState();
}

class _SteeringUIState extends State<SteeringUI> {
  final SensorService _sensorService = SensorService();
  UdpSender? _udpSender;
  StreamSubscription<SensorData>? _sensorSub;

  final TextEditingController _ipController = TextEditingController();
  final int _port = 9876;

  bool _isConnected = false;
  bool _isAcceleratorPressed = false;
  bool _isScanning = false;
  double _currentTilt = 0.0;
  String _steeringDirection = 'CENTER';
  String _statusMessage = 'Auto scan karo ya IP manually daalo';

  static const double _deadzoneThreshold = 2.0;

  // Auto scan
  Future<void> _autoScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning network...';
    });

    final ip = await DeviceScanner.findReceiver();

    if (ip != null) {
      _ipController.text = ip;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Mila! IP: $ip — Connect karo!';
      });
    } else {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Nahi mila! Manually IP daalo';
      });
    }
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) {
      setState(() => _statusMessage = 'Pehle IP daalo ya Scan karo!');
      return;
    }

    setState(() => _statusMessage = 'Connecting...');
    _udpSender = UdpSender(receiverIp: _ipController.text, port: _port);
    await _udpSender!.connect();

    if (_udpSender!.isConnected) {
      _sensorService.start();
      _sensorSub = _sensorService.stream.listen((data) {
        _udpSender?.sendTilt(data.tiltX);
        if (mounted) {
          setState(() {
            _currentTilt = data.tiltX;
            if (data.tiltX > _deadzoneThreshold) {
              _steeringDirection = 'LEFT';
            } else if (data.tiltX < -_deadzoneThreshold) {
              _steeringDirection = 'RIGHT';
            } else {
              _steeringDirection = 'CENTER';
            }
          });
        }
      });
      setState(() {
        _isConnected = true;
        _statusMessage = 'Connected: ${_ipController.text}';
      });
    } else {
      setState(() => _statusMessage = 'Failed! IP check karo');
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensorService.stop();
    _udpSender?.dispose();
    setState(() {
      _isConnected = false;
      _currentTilt = 0.0;
      _steeringDirection = 'CENTER';
      _statusMessage = 'Disconnected';
    });
  }

  void _onAcceleratorDown() {
    setState(() => _isAcceleratorPressed = true);
    _udpSender?.sendAccelerator(true);
  }

  void _onAcceleratorUp() {
    setState(() => _isAcceleratorPressed = false);
    _udpSender?.sendAccelerator(false);
  }

  @override
  void dispose() {
    _disconnect();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // LEFT PANEL
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TILT STEERING',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // IP Field
                    TextField(
                      controller: _ipController,
                      enabled: !_isConnected,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        labelText: 'Receiver IP',
                        labelStyle:
                            const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.wifi,
                            color: Color(0xFF00D4FF)),
                        suffixText: ':$_port',
                        suffixStyle:
                            const TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF333355)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF00D4FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF222233)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Auto Scan Button
                    if (!_isConnected)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isScanning ? null : _autoScan,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00D4FF)),
                                )
                              : const Icon(Icons.search,
                                  color: Color(0xFF00D4FF)),
                          label: Text(
                            _isScanning
                                ? 'Scanning...'
                                : 'Auto Scan',
                            style: const TextStyle(
                                color: Color(0xFF00D4FF)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF00D4FF)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Connect Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isConnected ? _disconnect : _connect,
                        icon: Icon(_isConnected
                            ? Icons.link_off
                            : Icons.link),
                        label: Text(_isConnected
                            ? 'DISCONNECT'
                            : 'CONNECT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected
                              ? const Color(0xFF2A1A1A)
                              : const Color(0xFF001A2A),
                          foregroundColor: _isConnected
                              ? Colors.redAccent
                              : const Color(0xFF00D4FF),
                          side: BorderSide(
                            color: _isConnected
                                ? Colors.redAccent
                                : const Color(0xFF00D4FF),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tilt Bar
                    _buildTiltBar(),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // RIGHT PANEL - Accelerator
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('GAS',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => _onAcceleratorDown(),
                        onTapUp: (_) => _onAcceleratorUp(),
                        onPanEnd: (_) => _onAcceleratorUp(),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _isAcceleratorPressed
                                ? const Color(0xFFFF4500)
                                : const Color(0xFF1A1A2E),
                            border: Border.all(
                              color: _isAcceleratorPressed
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFF333355),
                              width: 2,
                            ),
                            boxShadow: _isAcceleratorPressed
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF4500)
                                          .withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              _isAcceleratorPressed ? '🔥' : '🚗',
                              style:
                                  const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiltBar() {
    final clampedTilt = _currentTilt.clamp(-10.0, 10.0);
    final fillFraction = (clampedTilt + 10) / 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TILT',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11)),
            Text(
              _steeringDirection,
              style: TextStyle(
                color: _steeringDirection == 'CENTER'
                    ? Colors.white38
                    : const Color(0xFF00D4FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentTilt.toStringAsFixed(2),
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF111122),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fillFraction,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0066FF),
                    Color(0xFF00D4FF),
                    Color(0xFFFF4500),
                  ],
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

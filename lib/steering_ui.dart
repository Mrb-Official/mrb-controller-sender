import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sensor_service.dart';
import 'udp_sender.dart';
import 'custom_button_model.dart';
import 'button_editor.dart';

class SteeringUI extends StatefulWidget {
  const SteeringUI({super.key});
  @override
  State<SteeringUI> createState() => _SteeringUIState();
}

class _SteeringUIState extends State<SteeringUI> {
  final SensorService _sensor = SensorService();
  UdpSender? _udp;
  StreamSubscription<SensorData>? _sensorSub;
  final _ipController = TextEditingController();

  bool _isConnected = false;
  bool _gasPressed   = false;
  bool _brakePressed = false;
  double _tilt = 0.0;
  List<CustomButton> _customButtons = [];
  final Map<String, bool> _customPressed = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _ipController.text = prefs.getString('receiver_ip') ?? '');
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final btns = await ButtonStorage.load();
    setState(() {
      _customButtons = btns;
      for (var b in btns) _customPressed[b.id] = false;
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receiver_ip', ip);
    _udp = UdpSender(receiverIp: ip);
    await _udp!.connect();
    if (_udp!.isConnected) {
      _sensor.start();
      _sensorSub = _sensor.stream.listen((data) {
        _udp?.sendTilt(data.tiltX);
        if (mounted) setState(() => _tilt = data.tiltX);
      });
      setState(() => _isConnected = true);
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensor.stop();
    _udp?.dispose();
    setState(() { _isConnected = false; _tilt = 0; });
  }

  @override
  void dispose() { _disconnect(); _ipController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) return _buildConnectScreen();
    return _buildControllerScreen();
  }

  Widget _buildConnectScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom - 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_esports,
                  color: Color(0xFF00D4FF), size: 72),
                const SizedBox(height: 16),
                const Text('MRB Controller',
                  style: TextStyle(color: Colors.brown.shade900, fontSize: 26,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Tilt Steering',
                  style: TextStyle(color: Colors.brown.shade300, fontSize: 14)),
                const SizedBox(height: 56),
                TextField(
                  controller: _ipController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _connect(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Receiver IP Address',
                    labelStyle: const TextStyle(color: Colors.brown.shade300),
                    prefixIcon: const Icon(Icons.wifi, color: Color(0xFF00D4FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF333355))),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF))),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A800),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControllerScreen() {
    final angle = (_tilt / 10.0 * 90.0).clamp(-90.0, 90.0);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports,
                    color: Color(0xFF00D4FF), size: 20),
                  const SizedBox(width: 8),
                  const Text('MRB Controller',
                    style: TextStyle(color: Colors.brown.shade600, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF00FF88))),
                  const SizedBox(width: 6),
                  Text(_ipController.text,
                    style: const TextStyle(color: Colors.brown.shade300, fontSize: 12)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ButtonEditor()));
                      _loadButtons();
                    },
                    child: const Icon(Icons.tune, color: Colors.brown.shade300, size: 22),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _disconnect,
                    child: const Icon(Icons.link_off, color: Colors.brown.shade300, size: 22),
                  ),
                ],
              ),
            ),

            // Steering wheel
            Expanded(
              flex: 4,
              child: Center(
                child: CustomPaint(
                  size: const Size(190, 190),
                  painter: _WheelPainter(angle: angle),
                ),
              ),
            ),

            // Tilt bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white24, size: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_tilt.clamp(-10.0, 10.0) + 10) / 20,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFFFF3CD),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(const Color(0xFF0066FF),
                              const Color(0xFFFF4500),
                              (_tilt.clamp(-10.0, 10.0) + 10) / 20)!),
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white24, size: 14),
                ],
              ),
            ),

            // Custom buttons
            if (_customButtons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _customButtons.map((btn) {
                    final pressed = _customPressed[btn.id] ?? false;
                    return GestureDetector(
                      onTapDown: (_) {
                        if (btn.isHold) {
                          setState(() => _customPressed[btn.id] = true);
                          _udp?.sendCustomButton(btn.name, true);
                        }
                      },
                      onTapUp: (_) {
                        if (btn.isHold) {
                          setState(() => _customPressed[btn.id] = false);
                          _udp?.sendCustomButton(btn.name, false);
                        } else {
                          _udp?.sendCustomButton(btn.name, true);
                          Future.delayed(const Duration(milliseconds: 100),
                            () => _udp?.sendCustomButton(btn.name, false));
                        }
                      },
                      onTapCancel: () {
                        setState(() => _customPressed[btn.id] = false);
                        _udp?.sendCustomButton(btn.name, false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 72, height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: pressed
                            ? const Color(0xFF1A2A4A)
                            : const Color(0xFFFFF3CD),
                          border: Border.all(
                            color: pressed
                              ? const Color(0xFFD4A800)
                              : const Color(0xFFE8D48A)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gamepad_outlined,
                              color: pressed
                                ? const Color(0xFFD4A800)
                                : Colors.brown.shade300,
                              size: 20),
                            const SizedBox(height: 2),
                            Text(btn.name,
                              style: TextStyle(
                                color: pressed ? Colors.white : Colors.brown.shade300,
                                fontSize: 9, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Brake + Gas
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) { setState(() => _brakePressed = true); _udp?.sendBrake(true); },
                        onTapUp: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
                        onPanEnd: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _brakePressed
                              ? const Color(0xFF3A0000)
                              : const Color(0xFFFFF3CD),
                            border: Border.all(
                              color: _brakePressed
                                ? Colors.redAccent
                                : const Color(0xFFE8D48A),
                              width: 2)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pan_tool,
                                color: _brakePressed
                                  ? Colors.redAccent : Colors.brown.shade300,
                                size: 32),
                              const SizedBox(height: 6),
                              Text('BRAKE',
                                style: TextStyle(
                                  color: _brakePressed
                                    ? Colors.redAccent : Colors.brown.shade300,
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) { setState(() => _gasPressed = true); _udp?.sendGas(true); },
                        onTapUp: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
                        onPanEnd: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _gasPressed
                              ? const Color(0xFF1A2A00)
                              : const Color(0xFFFFF3CD),
                            border: Border.all(
                              color: _gasPressed
                                ? const Color(0xFF88FF00)
                                : const Color(0xFFE8D48A),
                              width: 2)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speed,
                                color: _gasPressed
                                  ? const Color(0xFF88FF00) : Colors.brown.shade300,
                                size: 32),
                              const SizedBox(height: 6),
                              Text('GAS',
                                style: TextStyle(
                                  color: _gasPressed
                                    ? const Color(0xFF88FF00) : Colors.brown.shade300,
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final double angle;
  _WheelPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 8;

    canvas.drawCircle(Offset(cx, cy), r,
      Paint()..color = const Color(0xFFD4A800)
        ..style = PaintingStyle.stroke..strokeWidth = 10);
    canvas.drawCircle(Offset(cx, cy), r * 0.32,
      Paint()..color = const Color(0xFFD4A800)
        ..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62),
      -pi / 2, -angle * pi / 180, false,
      Paint()..color = const Color(0x3300D4FF)
        ..style = PaintingStyle.stroke..strokeWidth = 8);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-angle * pi / 180);
    final spoke = Paint()..color = const Color(0xFF334466)
      ..style = PaintingStyle.stroke..strokeWidth = 7;
    for (int i = 0; i < 3; i++) {
      final a = (i * 120 - 90) * pi / 180;
      canvas.drawLine(
        Offset(r * 0.32 * cos(a), r * 0.32 * sin(a)),
        Offset(r * cos(a), r * sin(a)), spoke);
    }
    canvas.drawCircle(Offset(0, -r + 8), 6,
      Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}

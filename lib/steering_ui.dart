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

class _SteeringUIState extends State<SteeringUI>
    with SingleTickerProviderStateMixin {
  final SensorService _sensor = SensorService();
  UdpSender? _udp;
  StreamSubscription<SensorData>? _sensorSub;
  final _ipController = TextEditingController();

  bool _isConnected = false;
  bool _gasPressed  = false;
  bool _brakePressed = false;
  double _tilt = 0.0;
  String _status = 'IP daalo aur connect karo!';
  List<CustomButton> _customButtons = [];
  final Map<String, bool> _customPressed = {};

  late AnimationController _wheelAnim;
  double _wheelAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _wheelAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _loadIp();
    _loadButtons();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _ipController.text = prefs.getString('receiver_ip') ?? '10.136.131.137');
  }

  Future<void> _saveIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receiver_ip', _ipController.text);
  }

  Future<void> _loadButtons() async {
    final btns = await ButtonStorage.load();
    setState(() {
      _customButtons = btns;
      for (var b in btns) _customPressed[b.id] = false;
    });
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) return;
    await _saveIp();
    _udp = UdpSender(receiverIp: _ipController.text);
    await _udp!.connect();
    if (_udp!.isConnected) {
      _sensor.start();
      _sensorSub = _sensor.stream.listen((data) {
        _udp?.sendTilt(data.tiltX);
        if (mounted) setState(() {
          _tilt = data.tiltX;
          _wheelAngle = (data.tiltX / 10.0 * 90.0).clamp(-90.0, 90.0);
        });
      });
      setState(() { _isConnected = true; _status = '✅ ${_ipController.text}'; });
    } else {
      setState(() => _status = '❌ Connect nahi hua!');
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensor.stop();
    _udp?.dispose();
    setState(() { _isConnected = false; _status = 'Disconnected'; _tilt = 0; _wheelAngle = 0; });
  }

  @override
  void dispose() {
    _wheelAnim.dispose();
    _disconnect();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isConnected) _buildConnectPanel(),
            if (_isConnected) _buildConnectedStatus(),
            const SizedBox(height: 8),
            _buildSteeringWheel(),
            const SizedBox(height: 4),
            _buildTiltBar(),
            const Spacer(),
            _buildCustomButtons(),
            _buildMainButtons(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A3A))),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0044FF)],
              ),
            ),
            child: const Center(child: Text('🎮', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MRB CONTROLLER', style: TextStyle(
                color: Color(0xFF00D4FF), fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text('Tilt Steering', style: TextStyle(
                color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          if (_isConnected)
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF00FF88)),
            ),
          const SizedBox(width: 8),
          // Edit buttons
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ButtonEditor()));
              _loadButtons();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF333355)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('⚙️ Buttons',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Receiver IP',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.wifi, color: Color(0xFF00D4FF), size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF333355)),
                  borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CONNECT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(_status,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          GestureDetector(
            onTap: _disconnect,
            child: const Text('DISCONNECT',
              style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSteeringWheel() {
    return SizedBox(
      width: 140, height: 140,
      child: CustomPaint(
        painter: _SteeringWheelPainter(angle: _wheelAngle),
      ),
    );
  }

  Widget _buildTiltBar() {
    final fraction = (_tilt.clamp(-10.0, 10.0) + 10) / 20;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('◀ L', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text(_tilt.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
              const Text('R ▶', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF111122), borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00D4FF), Color(0xFFFF4500)],
                    stops: [0.0, 0.5, 1.0]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButtons() {
    if (_customButtons.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                Future.delayed(const Duration(milliseconds: 100), () {
                  _udp?.sendCustomButton(btn.name, false);
                });
              }
            },
            onTapCancel: () {
              if (btn.isHold) {
                setState(() => _customPressed[btn.id] = false);
                _udp?.sendCustomButton(btn.name, false);
              }
            },
            child: Container(
              width: 80, height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: pressed ? const Color(0xFF2244AA) : const Color(0xFF111133),
                border: Border.all(
                  color: pressed ? const Color(0xFF00D4FF) : const Color(0xFF333355), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(btn.emoji, style: const TextStyle(fontSize: 24)),
                  Text(btn.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // BRAKE
          Expanded(
            child: GestureDetector(
              onTapDown: (_) { setState(() => _brakePressed = true); _udp?.sendBrake(true); },
              onTapUp: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
              onPanEnd: (_) { setState(() => _brakePressed = false); _udp?.sendBrake(false); },
              child: Container(
                height: 110,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _brakePressed ? const Color(0xFF4A0000) : const Color(0xFF1A1A2E),
                  border: Border.all(
                    color: _brakePressed ? Colors.redAccent : const Color(0xFF333355), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_brakePressed ? '🛑' : '🔴', style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    const Text('BRAKE',
                      style: TextStyle(color: Colors.white54, fontSize: 13,
                        fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
          // GAS
          Expanded(
            child: GestureDetector(
              onTapDown: (_) { setState(() => _gasPressed = true); _udp?.sendGas(true); },
              onTapUp: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
              onPanEnd: (_) { setState(() => _gasPressed = false); _udp?.sendGas(false); },
              child: Container(
                height: 110,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _gasPressed ? const Color(0xFF3A1500) : const Color(0xFF1A1A2E),
                  border: Border.all(
                    color: _gasPressed ? const Color(0xFFFF6B35) : const Color(0xFF333355), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_gasPressed ? '🔥' : '🚗', style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    const Text('GAS',
                      style: TextStyle(color: Colors.white54, fontSize: 13,
                        fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteeringWheelPainter extends CustomPainter {
  final double angle;
  _SteeringWheelPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 10;

    final ringPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final spokePaint = Paint()
      ..color = const Color(0xFF888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final centerPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final arcPaint = Paint()
      ..color = const Color(0x66FF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    canvas.drawCircle(Offset(cx, cy), r * 0.35, centerPaint);

    // Arc
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.65);
    canvas.drawArc(rect, -pi / 2, -angle * pi / 180, false, arcPaint);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-angle * pi / 180);

    for (int i = 0; i < 3; i++) {
      final a = (i * 120 - 90) * pi / 180;
      canvas.drawLine(
        Offset(r * 0.35 * cos(a), r * 0.35 * sin(a)),
        Offset(r * cos(a), r * sin(a)),
        spokePaint);
    }

    canvas.drawCircle(Offset(0, -r + 10), 8, dotPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SteeringWheelPainter old) => old.angle != angle;
}

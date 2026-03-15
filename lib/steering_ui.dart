import 'dart:async';
import 'dart:math';
import 'dart:io';
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
  double _tilt = 0.0;
  List<CustomButton> _buttons = [];
  final Map<String, bool> _pressed = {};
  bool _scanning = false;
  String _scanStatus = '';

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('receiver_ip') ?? '';
    await _loadButtons();
  }

  Future<void> _loadButtons() async {
    final btns = await ButtonStorage.load();
    setState(() {
      _buttons = btns;
      for (var b in btns) _pressed[b.id] = false;
    });
  }

  Future<void> _autoScan() async {
    setState(() { _scanning = true; _scanStatus = 'Scanning...'; });
    try {
      final interfaces = await NetworkInterface.list();
      String subnet = '192.168.43';
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('10.') || ip.startsWith('192.168.')) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              break;
            }
          }
        }
      }
      bool found = false;
      for (int i = 1; i < 255 && !found; i++) {
        final ip = '$subnet.$i';
        try {
          final socket = await Socket.connect(ip, 9876,
            timeout: const Duration(milliseconds: 80));
          socket.destroy();
          setState(() { _ipController.text = ip; _scanStatus = 'Found: $ip ✓'; });
          found = true;
        } catch (_) {}
      }
      if (!found) setState(() => _scanStatus = 'Not found');
    } catch (_) { setState(() => _scanStatus = 'Error'); }
    setState(() => _scanning = false);
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receiver_ip', ip);
    _udp = UdpSender(receiverIp: ip);
    await _udp!.connect();
    if (_udp!.isConnected) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _udp!.sendButtonConfig(_buttons.map((b) => {
        'name': b.name, 'x': b.touchX, 'y': b.touchY,
        'isHold': b.isHold, 'swipeDir': b.swipeDir,
        'swipeDist': b.swipeDist,
      }).toList());
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

  void _onDown(CustomButton btn) {
    setState(() => _pressed[btn.id] = true);
    if (btn.swipeDir != 'none') {
      _udp?.sendCustomButton(btn.name, true,
        swipeDir: btn.swipeDir, swipeDist: btn.swipeDist);
    } else if (btn.isHold) {
      _udp?.sendCustomButton(btn.name, true);
    } else {
      _udp?.sendCustomButton(btn.name, true);
      Future.delayed(const Duration(milliseconds: 80),
        () => _udp?.sendCustomButton(btn.name, false));
    }
  }

  void _onUp(CustomButton btn) {
    setState(() => _pressed[btn.id] = false);
    if (btn.isHold && btn.swipeDir == 'none') {
      _udp?.sendCustomButton(btn.name, false);
    }
  }

  void _onCancel(CustomButton btn) {
    setState(() => _pressed[btn.id] = false);
    if (btn.isHold && btn.swipeDir == 'none') {
      _udp?.sendCustomButton(btn.name, false);
    }
  }

  @override
  void dispose() { _disconnect(); _ipController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
    _isConnected ? _buildController() : _buildConnect();

  // ── CONNECT SCREEN ──────────────────────────────
  Widget _buildConnect() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo SVG style
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports_esports,
                        color: Colors.white, size: 52),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('MRB Controller',
                  style: TextStyle(color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Tilt Steering',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 40),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _connect(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Receiver IP',
                        hintStyle: const TextStyle(color: Colors.white24),
                        prefixIcon: const Icon(Icons.wifi, color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52, height: 52,
                    child: OutlinedButton(
                      onPressed: _scanning ? null : _autoScan,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: _scanning
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search,
                            color: Colors.white54, size: 22),
                    ),
                  ),
                ]),
                if (_scanStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_scanStatus,
                      style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: FilledButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const ButtonEditor()));
                    _loadButtons();
                  },
                  icon: const Icon(Icons.tune,
                    color: Colors.white24, size: 16),
                  label: const Text('Configure Buttons',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CONTROLLER SCREEN ────────────────────────────
  Widget _buildController() {
    final angle = (_tilt / 10.0 * 90.0).clamp(-90.0, 90.0);
    final leftBtns  = _buttons.where((b) => b.touchX < 1080).toList();
    final rightBtns = _buttons.where((b) => b.touchX >= 1080).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Row(
          children: [
            // LEFT
            SizedBox(
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: leftBtns.map((b) => _buildBtn(b)).toList(),
              ),
            ),

            // CENTER
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00FF88))),
                      const SizedBox(width: 4),
                      Text(_ipController.text,
                        style: const TextStyle(
                          color: Colors.white24, fontSize: 10)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => const ButtonEditor()));
                          _loadButtons();
                        },
                        child: const Icon(Icons.tune,
                          color: Colors.white24, size: 16)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _disconnect,
                        child: const Icon(Icons.link_off,
                          color: Colors.white24, size: 16)),
                    ]),
                  ),
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _WheelPainter(angle: angle),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (_tilt.clamp(-10.0, 10.0) + 10) / 20,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF1A1A1A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(Colors.blue, Colors.orange,
                            (_tilt.clamp(-10.0, 10.0) + 10) / 20)!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT
            SizedBox(
              width: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rightBtns.map((b) => _buildBtn(b)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(CustomButton btn) {
    final pressed = _pressed[btn.id] ?? false;
    final pressColor = btn.pressColor;

    return GestureDetector(
      onTapDown: (_) => _onDown(btn),
      onTapUp: (_) => _onUp(btn),
      onTapCancel: () => _onCancel(btn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        width:  btn.uiWidth,
        height: btn.uiHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: pressed
            ? pressColor.withOpacity(0.15)
            : const Color(0xFF111111),
          border: Border.all(
            color: pressed ? pressColor : Colors.white12,
            width: pressed ? 2 : 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(btn.icon),
              color: pressed ? pressColor : Colors.white38,
              size: btn.uiHeight * 0.35),
            const SizedBox(height: 4),
            Text(btn.name,
              style: TextStyle(
                color: pressed ? pressColor : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
              overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    const map = {
      'speed':               Icons.speed,
      'pan_tool':            Icons.pan_tool,
      'keyboard_arrow_up':   Icons.keyboard_arrow_up,
      'keyboard_arrow_down': Icons.keyboard_arrow_down,
      'expand_less':         Icons.expand_less,
      'expand_more':         Icons.expand_more,
      'gamepad':             Icons.gamepad,
      'touch_app':           Icons.touch_app,
      'arrow_upward':        Icons.arrow_upward,
      'arrow_downward':      Icons.arrow_downward,
      'arrow_back':          Icons.arrow_back,
      'arrow_forward':       Icons.arrow_forward,
      'bolt':                Icons.bolt,
      'flag':                Icons.flag,
      'sports_score':        Icons.sports_score,
      'u_turn_left':         Icons.u_turn_left,
      'swap_vert':           Icons.swap_vert,
    };
    return map[name] ?? Icons.gamepad;
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
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawCircle(Offset(cx, cy), r * 0.28,
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.6),
      -pi / 2, -angle * pi / 180, false,
      Paint()..color = Colors.white30
        ..style = PaintingStyle.stroke..strokeWidth = 6);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-angle * pi / 180);
    final spoke = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke..strokeWidth = 6;
    for (int i = 0; i < 3; i++) {
      final a = (i * 120 - 90) * pi / 180;
      canvas.drawLine(
        Offset(r * 0.28 * cos(a), r * 0.28 * sin(a)),
        Offset(r * cos(a), r * sin(a)), spoke);
    }
    canvas.drawCircle(Offset(0, -r + 8), 5,
      Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}

import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sensor_service.dart';
import 'udp_sender.dart';
import 'custom_button_model.dart';
import 'button_editor.dart';
import 'sound_service.dart';

class SteeringUI extends StatefulWidget {
  const SteeringUI({super.key});
  @override
  State<SteeringUI> createState() => _SteeringUIState();
}

class _SteeringUIState extends State<SteeringUI>
    with TickerProviderStateMixin {

  final SensorService _sensor = SensorService();
  UdpSender? _udp;
  StreamSubscription<SensorData>? _sensorSub;
  final _ipController = TextEditingController();

  bool _isConnected = false;
  bool _showConnectAnim = false;
  double _tilt = 0.0;
  List<CustomButton> _buttons = [];
  final Map<String, bool> _pressed = {};
  bool _scanning = false;
  String _scanStatus = '';

  late AnimationController _connectCtrl;
  late AnimationController _dotCtrl;
  late Animation<double> _connectScaleAnim;
  late Animation<double> _connectFadeAnim;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();

    _connectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800));
    _connectScaleAnim = Tween<double>(begin: 0.4, end: 1.0)
      .animate(CurvedAnimation(
        parent: _connectCtrl, curve: Curves.elasticOut));
    _connectFadeAnim = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _connectCtrl, curve: Curves.easeOut));

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900))..repeat();
    _dotAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_dotCtrl);

    _init();
    _bootHaptic();
    SoundService.playBoot();
  }

  Future<void> _bootHaptic() async {
    await Future.delayed(const Duration(milliseconds: 400));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }

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
          setState(() {
            _ipController.text = ip;
            _scanStatus = 'Found: $ip ✓';
          });
          found = true;
        } catch (_) {}
      }
      if (!found) setState(() => _scanStatus = 'Not found');
    } catch (_) {
      setState(() => _scanStatus = 'Error');
    }
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
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      SoundService.playConnect();

      setState(() => _showConnectAnim = true);
      _connectCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1400));

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
      setState(() {
        _isConnected = true;
        _showConnectAnim = false;
      });
    }
  }

  void _disconnect() {
    _sensorSub?.cancel();
    _sensor.stop();
    _udp?.dispose();
    HapticFeedback.mediumImpact();
    setState(() { _isConnected = false; _tilt = 0; });
  }

  void _onDown(CustomButton btn) {
    HapticFeedback.mediumImpact();
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
  void dispose() {
    _connectCtrl.dispose();
    _dotCtrl.dispose();
    SoundService.dispose();
    _disconnect();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showConnectAnim) return _buildConnectAnim();
    if (_isConnected) return _buildController();
    return _buildConnect();
  }

  Widget _buildConnectAnim() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: AnimatedBuilder(
          animation: _connectCtrl,
          builder: (_, __) => Opacity(
            opacity: _connectFadeAnim.value,
            child: Transform.scale(
              scale: _connectScaleAnim.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 2))),
                    Container(width: 130, height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 2))),
                    Container(
                      width: 86, height: 86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A1A1A)),
                      child: const Icon(Icons.gamepad_outlined,
                        color: Colors.white, size: 42)),
                  ]),
                  const SizedBox(height: 28),
                  const Text('Controller Connected',
                    style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(_ipController.text,
                    style: const TextStyle(color: Colors.white38,
                      fontSize: 13, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnect() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 48, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset('assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.gamepad_outlined,
                        color: Colors.white, size: 48)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('MRB Controller',
                  style: TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _dotAnim,
                  builder: (_, __) {
                    final d = _dotAnim.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Waiting to pair',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 13)),
                        const SizedBox(width: 6),
                        _dot(d > 0.25),
                        const SizedBox(width: 3),
                        _dot(d > 0.55),
                        const SizedBox(width: 3),
                        _dot(d > 0.80),
                      ],
                    );
                  },
                ),
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
                        prefixIcon: const Icon(Icons.wifi,
                          color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white)),
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
                      style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                      color: Colors.white24, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 5, height: 5,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active
        ? Colors.white.withOpacity(0.7)
        : Colors.white.withOpacity(0.15)),
  );

  Widget _buildController() {
    final angle = (_tilt / 10.0 * 90.0).clamp(-90.0, 90.0);
    final leftBtns = _buttons.where((b) => b.side == 'left').toList();
    final rightBtns = _buttons.where((b) => b.side != 'left').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Center wheel area
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: _WheelPainter(angle: angle),
                    ),
                  ),
                ),
                
                // Top bar with controls
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00FF88),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _ipController.text,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ButtonEditor(),
                            ),
                          );
                          _loadButtons();
                        },
                        child: const Icon(Icons.tune, color: Colors.white24, size: 18),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: _disconnect,
                        child: const Icon(Icons.link_off, color: Colors.white24, size: 18),
                      ),
                    ],
                  ),
                ),
                
                // Left side buttons - positioned dynamically
                ...leftBtns.map((b) {
                  // Calculate position based on uiPosX and uiPosY
                  double left = 16 + b.uiPosX;
                  double top = (screenHeight / 2) - (b.uiHeight / 2) + b.uiPosY;
                  
                  // Ensure button stays within screen bounds
                  left = left.clamp(8.0, screenWidth / 2 - b.uiWidth - 8);
                  top = top.clamp(8.0, screenHeight - b.uiHeight - 8);
                  
                  return Positioned(
                    left: left,
                    top: top,
                    child: _buildBtn(b),
                  );
                }).toList(),
                
                // Right side buttons - positioned dynamically
                ...rightBtns.map((b) {
                  // For right side, position from right edge with offset
                  double right = 16 - b.uiPosX;
                  double top = (screenHeight / 2) - (b.uiHeight / 2) + b.uiPosY;
                  
                  // Calculate left position for Positioned widget
                  double left = screenWidth - b.uiWidth - right;
                  
                  // Ensure button stays within screen bounds
                  left = left.clamp(screenWidth / 2, screenWidth - b.uiWidth - 8);
                  top = top.clamp(8.0, screenHeight - b.uiHeight - 8);
                  
                  return Positioned(
                    left: left,
                    top: top,
                    child: _buildBtn(b),
                  );
                }).toList(),
                
                // Bottom progress bar
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_tilt.clamp(-10.0, 10.0) + 10) / 20,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          Colors.blue,
                          Colors.orange,
                          (_tilt.clamp(-10.0, 10.0) + 10) / 20,
                        )!,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

 Widget _buildBtn(CustomButton btn) {
  final pressed = _pressed[btn.id] ?? false;
  final pressColor = btn.pressColor;
  final w = btn.uiWidth.clamp(60.0, 170.0);
  final h = btn.uiHeight.clamp(50.0, 200.0);

  return GestureDetector(
    behavior: HitTestBehavior.opaque, // <-- Add this line
    onTapDown: (_) => _onDown(btn),
    onTapUp: (_) => _onUp(btn),
    onTapCancel: () => _onCancel(btn),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: pressed
            ? pressColor.withOpacity(0.15)
            : const Color(0xFF111111),
        border: Border.all(
          color: pressed ? pressColor : Colors.white12,
          width: pressed ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(btn.icon),
            color: pressed ? pressColor : Colors.white38,
            size: h * 0.32,
          ),
          const SizedBox(height: 4),
          Text(
            btn.name,
            style: TextStyle(
              color: pressed ? pressColor : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
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
      'u_turn_left':         Icons.u_turn_left,
      'swap_vert':           Icons.swap_vert,
      'bolt':                Icons.bolt,
      'flag':                Icons.flag,
      'sports_score':        Icons.sports_score,
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

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r,
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 8);
    
    // Inner circle
    canvas.drawCircle(Offset(cx, cy), r * 0.28,
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 4);
    
    // Arc indicator
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.6),
      -pi / 2, -angle * pi / 180, false,
      Paint()..color = Colors.white30
        ..style = PaintingStyle.stroke..strokeWidth = 6);

    // Spokes
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
    
    // Top indicator
    canvas.drawCircle(Offset(0, -r + 8), 5,
      Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}

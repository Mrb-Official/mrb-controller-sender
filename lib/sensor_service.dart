import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static const double _alpha = 0.15;
  double _smoothedX = 0.0;
  double _smoothedY = 0.0;
  double get tiltX => _smoothedX;
  double get tiltY => _smoothedY;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  void start() {
    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 16),
    ).listen((event) {
      _smoothedX = _smoothedX * (1 - _alpha) + event.y * _alpha;
      _smoothedY = _smoothedY * (1 - _alpha) + event.x * _alpha;
      _controller.add(SensorData(
        tiltX: _smoothedX,
        tiltY: _smoothedY,
        rawX: event.y,
      ));
    });
  }

  void stop() {
    _subscription?.cancel();
    _controller.close();
  }
}

class SensorData {
  final double tiltX;
  final double tiltY;
  final double rawX;
  const SensorData({
    required this.tiltX,
    required this.tiltY,
    required this.rawX,
  });
}

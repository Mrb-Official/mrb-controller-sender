import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'steering_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TiltSteeringApp());
}

class TiltSteeringApp extends StatelessWidget {
  const TiltSteeringApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilt Steering',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D4FF),
          secondary: const Color(0xFFFF4500),
        ),
      ),
      home: const SteeringUI(),
    );
  }
}
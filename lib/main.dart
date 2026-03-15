import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'steering_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TiltSteeringApp());
}

class TiltSteeringApp extends StatelessWidget {
  const TiltSteeringApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRB Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF111111),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const SteeringUI(),
    );
  }
}

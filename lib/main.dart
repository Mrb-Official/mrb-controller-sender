import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'steering_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A800),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      ),
      home: const SteeringUI(),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBoot() async {
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/boot.mp3'));
      // Smooth fade out at end
      await Future.delayed(const Duration(milliseconds: 1200));
      await _fadeOut();
    } catch (_) {}
  }

  static Future<void> playConnect() async {
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/connect.mp3'));
      await Future.delayed(const Duration(milliseconds: 1000));
      await _fadeOut();
    } catch (_) {}
  }

  static Future<void> _fadeOut() async {
    for (double v = 1.0; v >= 0; v -= 0.1) {
      await _player.setVolume(v < 0 ? 0 : v);
      await Future.delayed(const Duration(milliseconds: 40));
    }
    await _player.stop();
    await _player.setVolume(1.0);
  }

  static void dispose() => _player.dispose();
}

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Play loud Kirana new order chime in a loop until acknowledged
  static Future<void> playNewOrderAlert() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0); // Maximum volume for shop floor
      // Using an asset or high-priority audio stream
      await _player.play(AssetSource('sounds/new_order_alert.mp3'));
    } catch (e) {
      // Audio playback fallback
    }
  }

  /// Stop sound when owner taps "Acknowledge" or opens order
  static Future<void> stopAlert() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}

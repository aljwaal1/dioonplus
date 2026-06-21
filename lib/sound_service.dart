import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays short, tasteful UI sound effects bundled as offline assets.
/// Sounds are subtle by design and always paired with haptic feedback.
/// The user can mute sounds; the preference is persisted locally.
class SoundService {
  SoundService._internal();
  static final SoundService instance = SoundService._internal();

  static const _prefsKey = 'debt_advanced_sound_enabled_v1';

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  bool _ready = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.55);
    _ready = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> _play(String asset, {double volume = 0.55}) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$asset'));
    } catch (_) {
      // Sound is a nice-to-have; never let playback errors affect the app.
    }
  }

  Future<void> success() async {
    HapticFeedback.lightImpact();
    await _play('success_chime.wav', volume: 0.6);
  }

  Future<void> tap() async {
    HapticFeedback.selectionClick();
    await _play('soft_tap.wav', volume: 0.4);
  }

  Future<void> remove() async {
    HapticFeedback.mediumImpact();
    await _play('delete_swipe.wav', volume: 0.5);
  }
}

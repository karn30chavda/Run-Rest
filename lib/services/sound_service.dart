import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sound_settings.dart';
import '../models/timeline_item.dart';
import 'sound_synthesizer.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  late AudioPlayer _alertPlayer;
  late AudioPlayer _countdownPlayer;
  late AudioPlayer _metronomePlayer;
  late AudioPlayer _bgPlayer;

  final Map<String, String> _cachedFilePaths = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    _alertPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _countdownPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _metronomePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _bgPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

    // Configure AudioContext to allow mixing with background music (Spotify, etc.)
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        },
      ),
    );

    AudioPlayer.global.setAudioContext(audioContext);

    // Pre-cache primary sounds to temporary files for ultra-low latency on mobile
    try {
      await _precacheSounds();
    } catch (e) {
      debugPrint('Error precaching audio: $e');
    }

    _isInitialized = true;
  }

  Future<void> _precacheSounds() async {
    final tempDir = await getTemporaryDirectory();

    Future<void> cache(String key, Uint8List bytes) async {
      final file = File('${tempDir.path}/rr_$key.wav');
      await file.writeAsBytes(bytes, flush: true);
      _cachedFilePaths[key] = file.path;
    }

    // Classic Beeps
    await cache('high_beep', SoundSynthesizer.createTone(freq: 1000, durationSec: 0.35));
    await cache('low_beep', SoundSynthesizer.createTone(freq: 500, durationSec: 0.35));
    await cache('ready_beep', SoundSynthesizer.createTone(freq: 750, durationSec: 0.35));
    await cache('tick', SoundSynthesizer.createTone(freq: 850, durationSec: 0.12));
    await cache('metronome', SoundSynthesizer.createTone(freq: 1800, durationSec: 0.04, isClick: true));

    // Other Alert Types
    await cache('boxing_bell', SoundSynthesizer.createBoxingBell());
    await cache('whistle', SoundSynthesizer.createWhistle());
    await cache('zen_chime', SoundSynthesizer.createZenChime());
    await cache('arcade_chirp', SoundSynthesizer.createArcadeChirp());
    await cache('victory', SoundSynthesizer.createVictoryFanfare());

    // Ambient Loops
    await cache('bg_ambientPulse', SoundSynthesizer.createAmbientLoop('ambientPulse'));
    await cache('bg_loFiFlow', SoundSynthesizer.createAmbientLoop('loFiFlow'));
    await cache('bg_technoDrive', SoundSynthesizer.createAmbientLoop('technoDrive'));
  }

  Future<void> playAlert({
    required PhaseType phase,
    required AlertSoundType alertType,
    required double volume,
    required bool enabled,
  }) async {
    if (!enabled || volume <= 0) return;

    try {
      await _alertPlayer.setVolume(volume);

      String soundKey;
      switch (alertType) {
        case AlertSoundType.boxingBell:
          soundKey = 'boxing_bell';
          break;
        case AlertSoundType.digitalWhistle:
          soundKey = 'whistle';
          break;
        case AlertSoundType.zenChime:
          soundKey = 'zen_chime';
          break;
        case AlertSoundType.arcadeChirp:
          soundKey = 'arcade_chirp';
          break;
        case AlertSoundType.classicBeep:
          if (phase == PhaseType.run) {
            soundKey = 'high_beep';
          } else if (phase == PhaseType.rest) {
            soundKey = 'low_beep';
          } else if (phase == PhaseType.done) {
            soundKey = 'victory';
          } else {
            soundKey = 'ready_beep';
          }
          break;
      }

      final path = _cachedFilePaths[soundKey];
      if (path != null) {
        await _alertPlayer.stop();
        await _alertPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing alert: $e');
    }
  }

  Future<void> playCountdownTick({
    required double volume,
    required bool enabled,
  }) async {
    if (!enabled || volume <= 0) return;

    try {
      await _countdownPlayer.setVolume(volume * 0.9);
      final path = _cachedFilePaths['tick'];
      if (path != null) {
        await _countdownPlayer.stop();
        await _countdownPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing countdown tick: $e');
    }
  }

  Future<void> playMetronomeTick({
    required double volume,
    required bool enabled,
  }) async {
    if (!enabled || volume <= 0) return;

    try {
      await _metronomePlayer.setVolume(volume);
      final path = _cachedFilePaths['metronome'];
      if (path != null) {
        await _metronomePlayer.stop();
        await _metronomePlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing metronome tick: $e');
    }
  }

  Future<void> playVictory({
    required double volume,
    required bool enabled,
  }) async {
    if (!enabled || volume <= 0) return;

    try {
      await _alertPlayer.setVolume(volume);
      final path = _cachedFilePaths['victory'];
      if (path != null) {
        await _alertPlayer.stop();
        await _alertPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing victory: $e');
    }
  }

  Future<void> playPreview(AlertSoundType alertType, double volume) async {
    await playAlert(
      phase: PhaseType.run,
      alertType: alertType,
      volume: volume,
      enabled: true,
    );
  }

  Future<void> updateBackgroundMusic({
    required BackgroundMusicType type,
    required double volume,
    required bool isRunning,
  }) async {
    if (!isRunning ||
        type == BackgroundMusicType.none ||
        type == BackgroundMusicType.externalAudio ||
        volume <= 0) {
      await _bgPlayer.stop();
      return;
    }

    try {
      final key = 'bg_${type.name}';
      final path = _cachedFilePaths[key];
      if (path != null) {
        await _bgPlayer.setVolume(volume);
        if (_bgPlayer.state != PlayerState.playing) {
          await _bgPlayer.play(DeviceFileSource(path));
        }
      }
    } catch (e) {
      debugPrint('Error updating background music: $e');
    }
  }

  Future<void> stopAll() async {
    try {
      await _alertPlayer.stop();
      await _countdownPlayer.stop();
      await _metronomePlayer.stop();
      await _bgPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  void dispose() {
    _alertPlayer.dispose();
    _countdownPlayer.dispose();
    _metronomePlayer.dispose();
    _bgPlayer.dispose();
  }
}

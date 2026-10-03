import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/history_entry.dart';
import '../models/sound_settings.dart';
import '../models/timeline_item.dart';
import '../models/workout_config.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/vibration_service.dart';
import '../services/voice_service.dart';

enum TimerState { idle, running, paused, done }

class TimerProvider extends ChangeNotifier {
  final StorageService _storage;
  final SoundService _soundService = SoundService();
  final VoiceService _voiceService = VoiceService();
  final VibrationService _vibrationService = VibrationService();

  WorkoutConfig _config = const WorkoutConfig();
  SoundSettings _soundSettings = const SoundSettings();
  List<HistoryEntry> _history = [];
  List<WorkoutConfig> _customPresets = [];
  bool _keepAwake = true;

  TimerState _state = TimerState.idle;
  List<TimelineItem> _plan = [];
  int _totalRounds = 1;
  int _elapsedMs = 0;
  int _anchorTimeMs = 0;
  int _currentIndex = -1;
  String _lastCountdownKey = '';
  int _skippedMs = 0;
  DateTime? _startedAt;

  Timer? _ticker;
  Timer? _metronomeTicker;
  int _lastMetronomeBeatMs = 0;

  TimerProvider(this._storage) {
    _init();
  }

  WorkoutConfig get config => _config;
  SoundSettings get soundSettings => _soundSettings;
  List<HistoryEntry> get history => _history;
  List<WorkoutConfig> get customPresets => _customPresets;
  TimerState get state => _state;
  bool get keepAwake => _keepAwake;

  Future<void> _init() async {
    _config = _storage.loadConfig();
    _soundSettings = _storage.loadSoundSettings();
    _history = _storage.loadHistory();
    _customPresets = _storage.loadCustomPresets();
    _keepAwake = _storage.loadKeepAwake();

    await _soundService.init();
    await _voiceService.init();
    notifyListeners();
  }

  int get totalDurationMs => _plan.isNotEmpty ? _plan.last.endMs : 0;

  int get currentPositionMs {
    if (_state == TimerState.running) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return _elapsedMs + max(0, now - _anchorTimeMs);
    }
    if (_state == TimerState.done) {
      return totalDurationMs;
    }
    return _elapsedMs;
  }

  int get activeIndex {
    final pos = currentPositionMs;
    return _plan.indexWhere((p) => pos < p.endMs);
  }

  TimelineItem? get currentItem {
    final idx = activeIndex;
    if (idx >= 0 && idx < _plan.length) {
      return _plan[idx];
    }
    return null;
  }

  TimelineItem? get nextItem {
    final idx = activeIndex;
    if (idx >= 0 && idx + 1 < _plan.length) {
      return _plan[idx + 1];
    }
    return null;
  }

  PhaseType get currentPhase {
    if (_state == TimerState.done) return PhaseType.done;
    if (_state == TimerState.idle) return PhaseType.ready;
    return currentItem?.kind ?? PhaseType.ready;
  }

  Duration get remainingIntervalDuration {
    final item = currentItem;
    if (item == null) {
      return _state == TimerState.done
          ? Duration.zero
          : _config.runDuration;
    }
    final ms = max(0, item.endMs - currentPositionMs);
    return Duration(milliseconds: ms);
  }

  Duration get remainingSessionDuration {
    final total = totalDurationMs;
    if (total == 0) {
      final c = _config;
      final int base = c.mode == WorkoutMode.rounds
          ? (c.runDuration.inMilliseconds + c.restDuration.inMilliseconds) * c.rounds
          : c.totalDuration.inMilliseconds;
      return Duration(milliseconds: base + c.leadDuration.inMilliseconds + c.warmupDuration.inMilliseconds + c.cooldownDuration.inMilliseconds);
    }
    final ms = max(0, total - currentPositionMs);
    return Duration(milliseconds: ms);
  }

  int get currentRoundNumber => currentItem?.round ?? 1;
  int get totalRounds => _totalRounds;

  double get intervalProgress {
    final item = currentItem;
    if (item == null || item.lenMs <= 0) return 0.0;
    final remaining = item.endMs - currentPositionMs;
    return (1.0 - (remaining / item.lenMs)).clamp(0.0, 1.0);
  }

  double get sessionProgress {
    final total = totalDurationMs;
    if (total <= 0) return 0.0;
    return (currentPositionMs / total).clamp(0.0, 1.0);
  }

  void updateConfig(WorkoutConfig newConfig) {
    if (_state == TimerState.running || _state == TimerState.paused) return;
    _config = newConfig;
    _storage.saveConfig(newConfig);
    notifyListeners();
  }

  void updateSoundSettings(SoundSettings newSettings) {
    _soundSettings = newSettings;
    _storage.saveSoundSettings(newSettings);
    if (_state == TimerState.running) {
      _soundService.updateBackgroundMusic(
        type: newSettings.backgroundMusic,
        volume: newSettings.bgMusicVolume,
        isRunning: true,
      );
    }
    notifyListeners();
  }

  void setKeepAwake(bool value) {
    _keepAwake = value;
    _storage.saveKeepAwake(value);
    if (_state == TimerState.running && value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    notifyListeners();
  }

  void saveCurrentAsCustomPreset(String name) {
    final newPreset = _config.copyWith(
      preset: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    _customPresets.add(newPreset);
    _storage.saveCustomPresets(_customPresets);
    notifyListeners();
  }

  void deleteCustomPreset(String presetId) {
    _customPresets.removeWhere((p) => p.preset == presetId);
    _storage.saveCustomPresets(_customPresets);
    notifyListeners();
  }

  List<TimelineItem> _buildTimeline(WorkoutConfig c) {
    final items = <TimelineItem>[];
    int end = 0;

    void add(PhaseType kind, int len, [int round = 0]) {
      if (len > 0) {
        items.add(TimelineItem(
          kind: kind,
          startMs: end,
          endMs: end + len,
          lenMs: len,
          round: round,
        ));
        end += len;
      }
    }

    add(PhaseType.ready, c.leadDuration.inMilliseconds);
    add(PhaseType.warm, c.warmupDuration.inMilliseconds);

    final runMs = c.runDuration.inMilliseconds;
    final restMs = c.restDuration.inMilliseconds;
    int left = c.mode == WorkoutMode.rounds
        ? (runMs + restMs) * c.rounds
        : c.totalDuration.inMilliseconds;

    int round = 1;
    while (left > 0) {
      final rLen = min(left, runMs);
      add(PhaseType.run, rLen, round);
      left -= rLen;
      if (left <= 0) break;

      final restLen = min(left, restMs);
      add(PhaseType.rest, restLen, round);
      left -= restLen;
      round++;
    }

    add(PhaseType.cool, c.cooldownDuration.inMilliseconds);
    return items;
  }

  void start() {
    if (_state == TimerState.idle || _state == TimerState.done) {
      _plan = _buildTimeline(_config);
      _totalRounds = _plan.map((p) => p.round).fold(1, max);
      _elapsedMs = 0;
      _skippedMs = 0;
      _currentIndex = -1;
      _lastCountdownKey = '';
      _startedAt = DateTime.now();
    }

    _state = TimerState.running;
    _anchorTimeMs = DateTime.now().millisecondsSinceEpoch;

    if (_keepAwake) {
      WakelockPlus.enable();
    }

    _startTickers();

    _soundService.updateBackgroundMusic(
      type: _soundSettings.backgroundMusic,
      volume: _soundSettings.bgMusicVolume,
      isRunning: true,
    );

    // Initial alert if first phase
    final item = currentItem;
    if (item != null) {
      _announcePhase(item);
    }

    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;
    _elapsedMs = currentPositionMs;
    _state = TimerState.paused;
    _stopTickers();
    _soundService.stopAll();
    WakelockPlus.disable();
    notifyListeners();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    start();
  }

  void reset() {
    _state = TimerState.idle;
    _elapsedMs = 0;
    _plan = [];
    _currentIndex = -1;
    _stopTickers();
    _soundService.stopAll();
    _voiceService.stop();
    WakelockPlus.disable();
    notifyListeners();
  }

  void skipInterval() {
    if (_state != TimerState.running && _state != TimerState.paused) return;
    final item = currentItem;
    if (item == null) return;

    final pos = currentPositionMs;
    _skippedMs += (item.endMs - pos);
    _elapsedMs = item.endMs;
    _anchorTimeMs = DateTime.now().millisecondsSinceEpoch;
    _currentIndex = -1;
    _lastCountdownKey = '';

    if (_elapsedMs >= totalDurationMs) {
      _finish();
    } else {
      final next = currentItem;
      if (next != null && _state == TimerState.running) {
        _announcePhase(next);
      }
      notifyListeners();
    }
  }

  void _startTickers() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());

    _metronomeTicker?.cancel();
    _lastMetronomeBeatMs = 0;
    _metronomeTicker = Timer.periodic(const Duration(milliseconds: 30), (_) => _metronomeTick());
  }

  void _stopTickers() {
    _ticker?.cancel();
    _ticker = null;
    _metronomeTicker?.cancel();
    _metronomeTicker = null;
  }

  void _tick() {
    if (_state != TimerState.running) return;
    final pos = currentPositionMs;
    if (pos >= totalDurationMs) {
      _finish();
      return;
    }

    final idx = activeIndex;
    if (idx < 0 || idx >= _plan.length) return;
    final item = _plan[idx];

    // Phase transition detection
    if (idx != _currentIndex) {
      _currentIndex = idx;
      _lastCountdownKey = '';
      _announcePhase(item);
    }

    // 3, 2, 1 Countdown beeps before interval ends
    final remainingMs = item.endMs - pos;
    final remainingSec = (remainingMs / 1000).ceil();
    final key = '$idx:$remainingSec';

    if (remainingSec <= 3 && remainingSec >= 1 && key != _lastCountdownKey) {
      _lastCountdownKey = key;
      _soundService.playCountdownTick(
        volume: _soundSettings.volume,
        enabled: _soundSettings.soundEnabled,
      );
    }

    notifyListeners();
  }

  void _metronomeTick() {
    if (_state != TimerState.running ||
        !_soundSettings.soundEnabled ||
        !_soundSettings.metronomeEnabled ||
        _soundSettings.volume <= 0) {
      return;
    }

    final item = currentItem;
    if (item == null) return;

    // Metronome plays during RUN, or during REST if metronomeDuringRest is true
    final isAllowedPhase = item.kind == PhaseType.run ||
        (item.kind == PhaseType.rest && _soundSettings.metronomeDuringRest);

    if (!isAllowedPhase) {
      _lastMetronomeBeatMs = 0;
      return;
    }

    final int bpm = _soundSettings.metronomeBpm.clamp(30, 300);
    final int intervalMs = (60000 / bpm).round();
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (_lastMetronomeBeatMs == 0 || now - _lastMetronomeBeatMs >= intervalMs) {
      _lastMetronomeBeatMs = now;
      _soundService.playMetronomeTick(
        volume: _soundSettings.volume * 0.7,
        enabled: true,
      );
    }
  }

  void _announcePhase(TimelineItem item) {
    // Sound alert
    _soundService.playAlert(
      phase: item.kind,
      alertType: _soundSettings.alertType,
      volume: _soundSettings.volume,
      enabled: _soundSettings.soundEnabled,
    );

    // Voice announcement
    _voiceService.speak(
      item.kind.displayName,
      enabled: _soundSettings.voiceEnabled && _soundSettings.soundEnabled,
      volume: _soundSettings.volume,
    );

    // Vibration pattern
    _vibrationService.vibrate(
      _soundSettings.vibrationPattern,
      enabled: _soundSettings.vibrateEnabled,
    );
  }

  void _finish() {
    final end = totalDurationMs;
    _state = TimerState.done;
    _elapsedMs = end;
    _stopTickers();
    WakelockPlus.disable();

    _soundService.playVictory(
      volume: _soundSettings.volume,
      enabled: _soundSettings.soundEnabled,
    );

    _voiceService.speak(
      'Workout complete! Excellent work!',
      enabled: _soundSettings.voiceEnabled && _soundSettings.soundEnabled,
      volume: _soundSettings.volume,
    );

    _vibrationService.vibrate(
      VibrationPattern.doublePulse,
      enabled: _soundSettings.vibrateEnabled,
    );

    // Save workout to history
    final entry = HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _startedAt ?? DateTime.now(),
      seconds: max(0, ((end - _skippedMs) / 1000).round()),
      rounds: _totalRounds,
      runSeconds: _config.runDuration.inSeconds,
      restSeconds: _config.restDuration.inSeconds,
      skippedSeconds: (_skippedMs / 1000).round(),
      workoutName: _config.name,
    );

    _history.insert(0, entry);
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }
    _storage.saveHistory(_history);

    notifyListeners();
  }

  void deleteHistoryEntry(String id) {
    _history.removeWhere((h) => h.id == id);
    _storage.saveHistory(_history);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _storage.saveHistory(_history);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTickers();
    _soundService.dispose();
    super.dispose();
  }
}

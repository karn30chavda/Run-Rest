import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import '../models/sound_settings.dart';
import '../models/workout_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _keyConfig = 'run_rest_config';
  static const _keySound = 'run_rest_sound';
  static const _keyHistory = 'run_rest_history';
  static const _keyThemeMode = 'run_rest_theme_mode';
  static const _keyAccentColor = 'run_rest_accent_color';
  static const _keyCustomPresets = 'run_rest_custom_presets';
  static const _keyKeepAwake = 'run_rest_keep_awake';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  WorkoutConfig loadConfig() {
    final raw = _prefs?.getString(_keyConfig);
    if (raw != null) {
      try {
        return WorkoutConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const WorkoutConfig();
  }

  Future<void> saveConfig(WorkoutConfig config) async {
    await _prefs?.setString(_keyConfig, jsonEncode(config.toJson()));
  }

  SoundSettings loadSoundSettings() {
    final raw = _prefs?.getString(_keySound);
    if (raw != null) {
      try {
        return SoundSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const SoundSettings();
  }

  Future<void> saveSoundSettings(SoundSettings settings) async {
    await _prefs?.setString(_keySound, jsonEncode(settings.toJson()));
  }

  List<HistoryEntry> loadHistory() {
    final raw = _prefs?.getString(_keyHistory);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveHistory(List<HistoryEntry> history) async {
    final encoded = jsonEncode(history.take(100).map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyHistory, encoded);
  }

  String loadThemeMode() {
    return _prefs?.getString(_keyThemeMode) ?? 'dark';
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString(_keyThemeMode, mode);
  }

  int loadAccentColorValue() {
    return _prefs?.getInt(_keyAccentColor) ?? 0xFF10B981; // Default Emerald
  }

  Future<void> saveAccentColorValue(int value) async {
    await _prefs?.setInt(_keyAccentColor, value);
  }

  bool loadKeepAwake() {
    return _prefs?.getBool(_keyKeepAwake) ?? true;
  }

  Future<void> saveKeepAwake(bool keepAwake) async {
    await _prefs?.setBool(_keyKeepAwake, keepAwake);
  }

  List<WorkoutConfig> loadCustomPresets() {
    final raw = _prefs?.getString(_keyCustomPresets);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => WorkoutConfig.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveCustomPresets(List<WorkoutConfig> presets) async {
    final encoded = jsonEncode(presets.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyCustomPresets, encoded);
  }
}

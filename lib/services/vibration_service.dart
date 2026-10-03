import 'package:flutter/services.dart';
import '../models/sound_settings.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  Future<void> vibrate(VibrationPattern pattern, {required bool enabled}) async {
    if (!enabled || pattern == VibrationPattern.none) return;

    try {
      switch (pattern) {
        case VibrationPattern.standard:
          await HapticFeedback.mediumImpact();
          break;
        case VibrationPattern.doublePulse:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 140));
          await HapticFeedback.mediumImpact();
          break;
        case VibrationPattern.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case VibrationPattern.subtle:
          await HapticFeedback.selectionClick();
          break;
        case VibrationPattern.none:
          break;
      }
    } catch (_) {}
  }
}

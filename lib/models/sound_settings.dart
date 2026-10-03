enum AlertSoundType {
  classicBeep,
  boxingBell,
  digitalWhistle,
  zenChime,
  arcadeChirp;

  String get displayName {
    switch (this) {
      case AlertSoundType.classicBeep:
        return 'Classic Beep';
      case AlertSoundType.boxingBell:
        return 'Boxing Gym Bell';
      case AlertSoundType.digitalWhistle:
        return 'Referee Whistle';
      case AlertSoundType.zenChime:
        return 'Zen Singing Bowl';
      case AlertSoundType.arcadeChirp:
        return 'Arcade Synth';
    }
  }

  String get description {
    switch (this) {
      case AlertSoundType.classicBeep:
        return 'High pitch for Run, Low pitch for Rest';
      case AlertSoundType.boxingBell:
        return 'Authentic resonant ring bell for rounds';
      case AlertSoundType.digitalWhistle:
        return 'Sharp coach sports whistle';
      case AlertSoundType.zenChime:
        return 'Harmonic, gentle singing bowl tone';
      case AlertSoundType.arcadeChirp:
        return 'Retro futuristic energy blip';
    }
  }
}

enum VibrationPattern {
  standard,
  doublePulse,
  heavy,
  subtle,
  none;

  String get displayName {
    switch (this) {
      case VibrationPattern.standard:
        return 'Standard Pulse';
      case VibrationPattern.doublePulse:
        return 'Double Pulse';
      case VibrationPattern.heavy:
        return 'Heavy Impact';
      case VibrationPattern.subtle:
        return 'Subtle Click';
      case VibrationPattern.none:
        return 'Off';
    }
  }
}

enum BackgroundMusicType {
  none,
  externalAudio,
  ambientPulse,
  loFiFlow,
  technoDrive;

  String get displayName {
    switch (this) {
      case BackgroundMusicType.none:
        return 'No Music';
      case BackgroundMusicType.externalAudio:
        return 'Spotify / External Music (Allow Ducking)';
      case BackgroundMusicType.ambientPulse:
        return 'Built-in Cardio Pulse (120 BPM)';
      case BackgroundMusicType.loFiFlow:
        return 'Built-in Lo-Fi Workout Groove';
      case BackgroundMusicType.technoDrive:
        return 'Built-in Driving Techno Beat';
    }
  }

  String get description {
    switch (this) {
      case BackgroundMusicType.none:
        return 'Only timer sound cues and metronome';
      case BackgroundMusicType.externalAudio:
        return 'Play your favorite music apps simultaneously without interruption';
      case BackgroundMusicType.ambientPulse:
        return 'Steady rhythmic pulse to lock into your cadence';
      case BackgroundMusicType.loFiFlow:
        return 'Smooth, mellow ambient workout beats';
      case BackgroundMusicType.technoDrive:
        return 'Energetic electronic workout rhythm';
    }
  }
}

class SoundSettings {
  final bool soundEnabled;
  final double volume; // 0.0 to 1.0
  final bool metronomeEnabled;
  final int metronomeBpm; // 30 to 300
  final bool metronomeDuringRest;
  final bool voiceEnabled;
  final bool vibrateEnabled;
  final AlertSoundType alertType;
  final VibrationPattern vibrationPattern;
  final BackgroundMusicType backgroundMusic;
  final double bgMusicVolume; // 0.0 to 1.0

  const SoundSettings({
    this.soundEnabled = true,
    this.volume = 0.8,
    this.metronomeEnabled = true,
    this.metronomeBpm = 160,
    this.metronomeDuringRest = false,
    this.voiceEnabled = true,
    this.vibrateEnabled = true,
    this.alertType = AlertSoundType.classicBeep,
    this.vibrationPattern = VibrationPattern.standard,
    this.backgroundMusic = BackgroundMusicType.externalAudio,
    this.bgMusicVolume = 0.5,
  });

  SoundSettings copyWith({
    bool? soundEnabled,
    double? volume,
    bool? metronomeEnabled,
    int? metronomeBpm,
    bool? metronomeDuringRest,
    bool? voiceEnabled,
    bool? vibrateEnabled,
    AlertSoundType? alertType,
    VibrationPattern? vibrationPattern,
    BackgroundMusicType? backgroundMusic,
    double? bgMusicVolume,
  }) {
    return SoundSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      volume: volume ?? this.volume,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      metronomeBpm: metronomeBpm ?? this.metronomeBpm,
      metronomeDuringRest: metronomeDuringRest ?? this.metronomeDuringRest,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      alertType: alertType ?? this.alertType,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      bgMusicVolume: bgMusicVolume ?? this.bgMusicVolume,
    );
  }

  Map<String, dynamic> toJson() => {
    'soundEnabled': soundEnabled,
    'volume': volume,
    'metronomeEnabled': metronomeEnabled,
    'metronomeBpm': metronomeBpm,
    'metronomeDuringRest': metronomeDuringRest,
    'voiceEnabled': voiceEnabled,
    'vibrateEnabled': vibrateEnabled,
    'alertType': alertType.name,
    'vibrationPattern': vibrationPattern.name,
    'backgroundMusic': backgroundMusic.name,
    'bgMusicVolume': bgMusicVolume,
  };

  factory SoundSettings.fromJson(Map<String, dynamic> json) {
    return SoundSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      metronomeEnabled: json['metronomeEnabled'] as bool? ?? true,
      metronomeBpm: json['metronomeBpm'] as int? ?? 160,
      metronomeDuringRest: json['metronomeDuringRest'] as bool? ?? false,
      voiceEnabled: json['voiceEnabled'] as bool? ?? true,
      vibrateEnabled: json['vibrateEnabled'] as bool? ?? true,
      alertType: AlertSoundType.values.firstWhere(
        (e) => e.name == json['alertType'],
        orElse: () => AlertSoundType.classicBeep,
      ),
      vibrationPattern: VibrationPattern.values.firstWhere(
        (e) => e.name == json['vibrationPattern'],
        orElse: () => VibrationPattern.standard,
      ),
      backgroundMusic: BackgroundMusicType.values.firstWhere(
        (e) => e.name == json['backgroundMusic'],
        orElse: () => BackgroundMusicType.externalAudio,
      ),
      bgMusicVolume: (json['bgMusicVolume'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

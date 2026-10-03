enum WorkoutMode {
  time,
  rounds;

  String get label => this == WorkoutMode.time ? 'Total Time' : 'Number of Rounds';
}

class WorkoutConfig {
  final Duration runDuration;
  final Duration restDuration;
  final Duration leadDuration;
  final Duration warmupDuration;
  final Duration cooldownDuration;
  final WorkoutMode mode;
  final Duration totalDuration;
  final int rounds;
  final String preset;
  final String name;

  const WorkoutConfig({
    this.runDuration = const Duration(seconds: 60),
    this.restDuration = const Duration(seconds: 90),
    this.leadDuration = const Duration(seconds: 3),
    this.warmupDuration = Duration.zero,
    this.cooldownDuration = Duration.zero,
    this.mode = WorkoutMode.time,
    this.totalDuration = const Duration(minutes: 20),
    this.rounds = 8,
    this.preset = 'walk',
    this.name = 'Run / Walk (60/90)',
  });

  WorkoutConfig copyWith({
    Duration? runDuration,
    Duration? restDuration,
    Duration? leadDuration,
    Duration? warmupDuration,
    Duration? cooldownDuration,
    WorkoutMode? mode,
    Duration? totalDuration,
    int? rounds,
    String? preset,
    String? name,
  }) {
    return WorkoutConfig(
      runDuration: runDuration ?? this.runDuration,
      restDuration: restDuration ?? this.restDuration,
      leadDuration: leadDuration ?? this.leadDuration,
      warmupDuration: warmupDuration ?? this.warmupDuration,
      cooldownDuration: cooldownDuration ?? this.cooldownDuration,
      mode: mode ?? this.mode,
      totalDuration: totalDuration ?? this.totalDuration,
      rounds: rounds ?? this.rounds,
      preset: preset ?? this.preset,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
    'runDuration': runDuration.inSeconds,
    'restDuration': restDuration.inSeconds,
    'leadDuration': leadDuration.inSeconds,
    'warmupDuration': warmupDuration.inSeconds,
    'cooldownDuration': cooldownDuration.inSeconds,
    'mode': mode.name,
    'totalDuration': totalDuration.inMinutes,
    'rounds': rounds,
    'preset': preset,
    'name': name,
  };

  factory WorkoutConfig.fromJson(Map<String, dynamic> json) {
    return WorkoutConfig(
      runDuration: Duration(seconds: json['runDuration'] as int? ?? 60),
      restDuration: Duration(seconds: json['restDuration'] as int? ?? 90),
      leadDuration: Duration(seconds: json['leadDuration'] as int? ?? 3),
      warmupDuration: Duration(seconds: json['warmupDuration'] as int? ?? 0),
      cooldownDuration: Duration(seconds: json['cooldownDuration'] as int? ?? 0),
      mode: (json['mode'] as String?) == 'rounds' ? WorkoutMode.rounds : WorkoutMode.time,
      totalDuration: Duration(minutes: json['totalDuration'] as int? ?? 20),
      rounds: json['rounds'] as int? ?? 8,
      preset: json['preset'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Custom Workout',
    );
  }

  static const List<WorkoutConfig> defaultPresets = [
    WorkoutConfig(
      preset: 'walk',
      name: 'Run / Walk · 60 / 90',
      runDuration: Duration(seconds: 60),
      restDuration: Duration(seconds: 90),
      leadDuration: Duration(seconds: 3),
      mode: WorkoutMode.time,
      totalDuration: Duration(minutes: 20),
      rounds: 8,
    ),
    WorkoutConfig(
      preset: 'hiit',
      name: 'HIIT Cardio · 30 / 30',
      runDuration: Duration(seconds: 30),
      restDuration: Duration(seconds: 30),
      leadDuration: Duration(seconds: 3),
      mode: WorkoutMode.time,
      totalDuration: Duration(minutes: 15),
      rounds: 15,
    ),
    WorkoutConfig(
      preset: 'tabata',
      name: 'Tabata · 20 / 10 (8 Rounds)',
      runDuration: Duration(seconds: 20),
      restDuration: Duration(seconds: 10),
      leadDuration: Duration(seconds: 5),
      mode: WorkoutMode.rounds,
      totalDuration: Duration(minutes: 4),
      rounds: 8,
    ),
    WorkoutConfig(
      preset: 'boxing',
      name: 'Boxing Rounds · 3m / 1m',
      runDuration: Duration(minutes: 3),
      restDuration: Duration(minutes: 1),
      leadDuration: Duration(seconds: 5),
      mode: WorkoutMode.rounds,
      rounds: 6,
      warmupDuration: Duration(minutes: 1),
      cooldownDuration: Duration(minutes: 1),
    ),
    WorkoutConfig(
      preset: 'sprint',
      name: 'Sprint Repeats · 15 / 45',
      runDuration: Duration(seconds: 15),
      restDuration: Duration(seconds: 45),
      leadDuration: Duration(seconds: 5),
      mode: WorkoutMode.rounds,
      rounds: 10,
      warmupDuration: Duration(minutes: 2),
      cooldownDuration: Duration(minutes: 2),
    ),
  ];
}

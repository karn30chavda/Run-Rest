class HistoryEntry {
  final String id;
  final DateTime date;
  final int seconds;
  final int rounds;
  final int runSeconds;
  final int restSeconds;
  final int skippedSeconds;
  final String workoutName;

  const HistoryEntry({
    required this.id,
    required this.date,
    required this.seconds,
    required this.rounds,
    required this.runSeconds,
    required this.restSeconds,
    this.skippedSeconds = 0,
    this.workoutName = 'Interval Session',
  });

  int get estimatedCalories {
    // Standard MET calculation for HIIT / Interval running (~11 kcal/min)
    final activeMinutes = (seconds - skippedSeconds) / 60.0;
    return (activeMinutes * 10.5).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'seconds': seconds,
    'rounds': rounds,
    'runSeconds': runSeconds,
    'restSeconds': restSeconds,
    'skippedSeconds': skippedSeconds,
    'workoutName': workoutName,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      seconds: json['seconds'] as int? ?? 0,
      rounds: json['rounds'] as int? ?? 1,
      runSeconds: json['runSeconds'] as int? ?? 60,
      restSeconds: json['restSeconds'] as int? ?? 90,
      skippedSeconds: json['skippedSeconds'] as int? ?? 0,
      workoutName: json['workoutName'] as String? ?? 'Interval Session',
    );
  }
}

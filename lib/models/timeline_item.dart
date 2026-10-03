import 'package:flutter/material.dart';

enum PhaseType {
  ready,
  warm,
  run,
  rest,
  cool,
  done;

  String get displayName {
    switch (this) {
      case PhaseType.ready:
        return 'Get ready';
      case PhaseType.warm:
        return 'Warm up';
      case PhaseType.run:
        return 'Run';
      case PhaseType.rest:
        return 'Rest';
      case PhaseType.cool:
        return 'Cool down';
      case PhaseType.done:
        return 'Well done!';
    }
  }

  Color get color {
    switch (this) {
      case PhaseType.ready:
        return const Color(0xFFE5A91E); // Amber / Gold
      case PhaseType.warm:
        return const Color(0xFFB570EA); // Vibrant Purple
      case PhaseType.run:
        return const Color(0xFFFF5238); // Energetic Coral / Red-Orange
      case PhaseType.rest:
        return const Color(0xFF00B4D8); // Cyan / Blue-Green
      case PhaseType.cool:
        return const Color(0xFF64A0FA); // Calm Blue
      case PhaseType.done:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  IconData get icon {
    switch (this) {
      case PhaseType.ready:
        return Icons.timer_outlined;
      case PhaseType.warm:
        return Icons.accessibility_new_rounded;
      case PhaseType.run:
        return Icons.directions_run_rounded;
      case PhaseType.rest:
        return Icons.self_improvement_rounded;
      case PhaseType.cool:
        return Icons.air_rounded;
      case PhaseType.done:
        return Icons.emoji_events_rounded;
    }
  }
}

class TimelineItem {
  final PhaseType kind;
  final int startMs;
  final int endMs;
  final int lenMs;
  final int round;

  const TimelineItem({
    required this.kind,
    required this.startMs,
    required this.endMs,
    required this.lenMs,
    this.round = 0,
  });
}

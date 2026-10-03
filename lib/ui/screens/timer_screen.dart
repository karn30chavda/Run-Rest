import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/sound_settings.dart';
import '../../providers/timer_provider.dart';
import '../widgets/circular_timer_gauge.dart';
import '../widgets/custom_select_sheet.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isRunning = timer.state == TimerState.running;
    final isPaused = timer.state == TimerState.paused;
    final isDone = timer.state == TimerState.done;
    final isIdle = timer.state == TimerState.idle;

    final phase = timer.currentPhase;
    final currentItem = timer.currentItem;
    final nextItem = timer.nextItem;

    final roundText = isDone
        ? 'COMPLETED'
        : (currentItem != null && currentItem.round > 0)
            ? 'ROUND ${currentItem.round} OF ${timer.totalRounds}'
            : (isIdle ? 'READY TO START' : '');

    final nextPhaseText = isDone
        ? 'Session Complete'
        : nextItem != null
            ? 'Next: ${nextItem.kind.displayName}'
            : (isIdle
                ? 'First: ${timer.config.leadDuration.inSeconds > 0 ? "Get ready" : "Run"}'
                : 'Next: Finish');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top quick control bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // App title & preset badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RUN / REST',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          timer.config.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Quick sound mute toggle
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      timer.updateSoundSettings(
                        timer.soundSettings.copyWith(
                          soundEnabled: !timer.soundSettings.soundEnabled,
                        ),
                      );
                    },
                    icon: Icon(
                      timer.soundSettings.soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: timer.soundSettings.soundEnabled
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    tooltip: timer.soundSettings.soundEnabled ? 'Mute' : 'Unmute',
                  ),

                  // Background music mode chip
                  InkWell(
                    onTap: () async {
                      final selected = await CustomSelectSheet.show<BackgroundMusicType>(
                        context: context,
                        title: 'Background Audio Mode',
                        selectedValue: timer.soundSettings.backgroundMusic,
                        options: BackgroundMusicType.values.map((bg) {
                          return SelectOption(
                            value: bg,
                            title: bg.displayName,
                            subtitle: bg.description,
                            icon: bg == BackgroundMusicType.none
                                ? Icons.music_off_rounded
                                : (bg == BackgroundMusicType.externalAudio
                                    ? Icons.queue_music_rounded
                                    : Icons.library_music_rounded),
                          );
                        }).toList(),
                      );
                      if (selected != null) {
                        timer.updateSoundSettings(
                          timer.soundSettings.copyWith(backgroundMusic: selected),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            timer.soundSettings.backgroundMusic == BackgroundMusicType.none
                                ? Icons.music_off_outlined
                                : Icons.music_note_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timer.soundSettings.backgroundMusic == BackgroundMusicType.externalAudio
                                ? 'Spotify/Mix'
                                : timer.soundSettings.backgroundMusic == BackgroundMusicType.none
                                    ? 'No BGM'
                                    : 'BGM On',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Hero Circular Timer Gauge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: CircularTimerGauge(
                progress: timer.intervalProgress,
                timeFormatted: _formatDuration(timer.remainingIntervalDuration),
                phase: phase,
                nextPhaseText: nextPhaseText,
                roundText: roundText,
                isRunning: isRunning,
                isPaused: isPaused,
              ),
            ),

            const SizedBox(height: 18),

            // Overall Session Progress and Remaining Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: timer.sessionProgress,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF26332A) : const Color(0xFFE2ECE5),
                      valueColor: AlwaysStoppedAnimation<Color>(phase.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDone
                            ? 'Workout Completed!'
                            : '${_formatDuration(timer.remainingSessionDuration)} session left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      if (timer.soundSettings.metronomeEnabled && isRunning)
                        Row(
                          children: [
                            Icon(Icons.speed_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              '${timer.soundSettings.metronomeBpm} BPM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  // Reset Button
                  IconButton.filledTonal(
                    onPressed: (isRunning || isPaused || isDone)
                        ? () {
                            HapticFeedback.mediumImpact();
                            if (isRunning || isPaused) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Reset Workout?'),
                                  content: const Text(
                                    'Are you sure you want to reset? Current progress will be discarded.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        timer.reset();
                                      },
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              timer.reset();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.replay_rounded),
                    iconSize: 26,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                    tooltip: 'Reset',
                  ),

                  const SizedBox(width: 14),

                  // Main Start / Pause / Resume Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        if (isRunning) {
                          timer.pause();
                        } else if (isPaused) {
                          timer.resume();
                        } else {
                          timer.start();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning ? const Color(0xFFE5A91E) : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(62),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRunning
                                ? Icons.pause_rounded
                                : (isPaused ? Icons.play_arrow_rounded : Icons.play_arrow_rounded),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRunning
                                ? 'PAUSE'
                                : (isPaused ? 'RESUME' : (isDone ? 'START AGAIN' : 'START WORKOUT')),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Skip Interval Button
                  IconButton.filledTonal(
                    onPressed: (isRunning || isPaused)
                        ? () {
                            HapticFeedback.mediumImpact();
                            timer.skipInterval();
                          }
                        : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 26,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                    tooltip: 'Skip Interval',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

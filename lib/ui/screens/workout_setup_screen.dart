import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/workout_config.dart';
import '../../providers/timer_provider.dart';
import '../widgets/custom_select_sheet.dart';
import '../widgets/duration_picker_sheet.dart';

class WorkoutSetupScreen extends StatelessWidget {
  const WorkoutSetupScreen({super.key});

  String _formatSec(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '$m min';
    return '$s sec';
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final config = timer.config;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLocked = timer.state == TimerState.running || timer.state == TimerState.paused;

    // Presets list combining defaults and user custom presets
    final allPresets = [
      ...WorkoutConfig.defaultPresets,
      ...timer.customPresets,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Setup', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: isLocked
                ? null
                : () {
                    _showSavePresetDialog(context, timer);
                  },
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save Custom Preset',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          if (isLocked)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Workout is currently active. Reset or finish session to modify configuration.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Preset Selection Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Workout Preset',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: isLocked
                        ? null
                        : () async {
                            final selected = await CustomSelectSheet.show<String>(
                              context: context,
                              title: 'Choose Workout Preset',
                              selectedValue: config.preset,
                              options: [
                                const SelectOption(
                                  value: 'custom',
                                  title: 'Custom Workout',
                                  subtitle: 'Configure your own intervals and rounds',
                                  icon: Icons.tune_rounded,
                                ),
                                ...allPresets.map((p) => SelectOption(
                                      value: p.preset,
                                      title: p.name,
                                      subtitle:
                                          'Run ${_formatSec(p.runDuration)} · Rest ${_formatSec(p.restDuration)} · ${p.mode == WorkoutMode.rounds ? "${p.rounds} rounds" : "${p.totalDuration.inMinutes}m total"}',
                                      icon: Icons.flash_on_rounded,
                                    )),
                              ],
                            );
                            if (selected != null) {
                              if (selected == 'custom') {
                                timer.updateConfig(config.copyWith(
                                  preset: 'custom',
                                  name: 'Custom Workout',
                                ));
                              } else {
                                final matched = allPresets.firstWhere((p) => p.preset == selected);
                                timer.updateConfig(matched);
                              }
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3E33) : const Color(0xFFE2E8E4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to choose preset or customize',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Interval Intervals Config Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interval Durations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),

                  // Run Duration Tile
                  _DurationTile(
                    title: 'Run Duration',
                    subtitle: 'High energy interval',
                    value: config.runDuration,
                    color: const Color(0xFFFF5238),
                    icon: Icons.directions_run_rounded,
                    disabled: isLocked,
                    onTap: () async {
                      final res = await DurationPickerSheet.show(
                        context: context,
                        title: 'Run Duration',
                        initialDuration: config.runDuration,
                        minSeconds: 5,
                        maxSeconds: 1800,
                        stepSeconds: 5,
                      );
                      if (res != null) {
                        timer.updateConfig(config.copyWith(
                          runDuration: res,
                          preset: 'custom',
                          name: 'Custom Workout',
                        ));
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // Rest Duration Tile
                  _DurationTile(
                    title: 'Rest Duration',
                    subtitle: 'Recovery interval',
                    value: config.restDuration,
                    color: const Color(0xFF00B4D8),
                    icon: Icons.self_improvement_rounded,
                    disabled: isLocked,
                    onTap: () async {
                      final res = await DurationPickerSheet.show(
                        context: context,
                        title: 'Rest Duration',
                        initialDuration: config.restDuration,
                        minSeconds: 5,
                        maxSeconds: 1800,
                        stepSeconds: 5,
                      );
                      if (res != null) {
                        timer.updateConfig(config.copyWith(
                          restDuration: res,
                          preset: 'custom',
                          name: 'Custom Workout',
                        ));
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // Get Ready / Lead Duration Tile
                  _DurationTile(
                    title: 'Get Ready (Prep)',
                    subtitle: 'Countdown before starting',
                    value: config.leadDuration,
                    color: const Color(0xFFE5A91E),
                    icon: Icons.timer_outlined,
                    disabled: isLocked,
                    onTap: () async {
                      final res = await DurationPickerSheet.show(
                        context: context,
                        title: 'Get Ready Countdown',
                        initialDuration: config.leadDuration,
                        minSeconds: 0,
                        maxSeconds: 30,
                        stepSeconds: 1,
                      );
                      if (res != null) {
                        timer.updateConfig(config.copyWith(
                          leadDuration: res,
                          preset: 'custom',
                          name: 'Custom Workout',
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Workout Mode & Length Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Goal & Target',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),

                  // Mode Selector
                  InkWell(
                    onTap: isLocked
                        ? null
                        : () async {
                            final selected = await CustomSelectSheet.show<WorkoutMode>(
                              context: context,
                              title: 'Choose Workout Goal',
                              selectedValue: config.mode,
                              options: const [
                                SelectOption(
                                  value: WorkoutMode.time,
                                  title: 'Total Time Goal',
                                  subtitle: 'Repeats intervals until total minutes are reached',
                                  icon: Icons.hourglass_top_rounded,
                                ),
                                SelectOption(
                                  value: WorkoutMode.rounds,
                                  title: 'Fixed Number of Rounds',
                                  subtitle: 'Executes an exact count of Run + Rest sets',
                                  icon: Icons.replay_rounded,
                                ),
                              ],
                            );
                            if (selected != null) {
                              timer.updateConfig(config.copyWith(
                                mode: selected,
                                preset: 'custom',
                                name: 'Custom Workout',
                              ));
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3E33) : const Color(0xFFE2E8E4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                config.mode.label,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Total minutes OR Rounds count
                  if (config.mode == WorkoutMode.time)
                    _DurationTile(
                      title: 'Total Target Time',
                      subtitle: 'Overall workout length',
                      value: config.totalDuration,
                      color: theme.colorScheme.primary,
                      icon: Icons.timer_rounded,
                      disabled: isLocked,
                      onTap: () async {
                        final res = await DurationPickerSheet.show(
                          context: context,
                          title: 'Total Session Duration',
                          initialDuration: config.totalDuration,
                          minSeconds: 60,
                          maxSeconds: 7200,
                          stepSeconds: 60,
                        );
                        if (res != null) {
                          timer.updateConfig(config.copyWith(
                            totalDuration: res,
                            preset: 'custom',
                            name: 'Custom Workout',
                          ));
                        }
                      },
                    )
                  else
                    _RoundsStepperTile(
                      rounds: config.rounds,
                      disabled: isLocked,
                      onChanged: (newRounds) {
                        timer.updateConfig(config.copyWith(
                          rounds: newRounds,
                          preset: 'custom',
                          name: 'Custom Workout',
                        ));
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Extras: Warmup & Cooldown
          Card(
            child: ExpansionTile(
              shape: const Border(),
              leading: Icon(Icons.more_time_rounded, color: theme.colorScheme.primary),
              title: const Text('Warm-up & Cool-down', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: Text(
                'Warmup: ${_formatSec(config.warmupDuration)} · Cooldown: ${_formatSec(config.cooldownDuration)}',
                style: const TextStyle(fontSize: 12.5),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _DurationTile(
                        title: 'Warm-up Duration',
                        subtitle: 'Gentle preparation pace',
                        value: config.warmupDuration,
                        color: const Color(0xFFB570EA),
                        icon: Icons.accessibility_new_rounded,
                        disabled: isLocked,
                        onTap: () async {
                          final res = await DurationPickerSheet.show(
                            context: context,
                            title: 'Warm-up Duration',
                            initialDuration: config.warmupDuration,
                            minSeconds: 0,
                            maxSeconds: 1800,
                            stepSeconds: 15,
                          );
                          if (res != null) {
                            timer.updateConfig(config.copyWith(
                              warmupDuration: res,
                              preset: 'custom',
                              name: 'Custom Workout',
                            ));
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _DurationTile(
                        title: 'Cool-down Duration',
                        subtitle: 'Heart rate recovery',
                        value: config.cooldownDuration,
                        color: const Color(0xFF64A0FA),
                        icon: Icons.air_rounded,
                        disabled: isLocked,
                        onTap: () async {
                          final res = await DurationPickerSheet.show(
                            context: context,
                            title: 'Cool-down Duration',
                            initialDuration: config.cooldownDuration,
                            minSeconds: 0,
                            maxSeconds: 1800,
                            stepSeconds: 15,
                          );
                          if (res != null) {
                            timer.updateConfig(config.copyWith(
                              cooldownDuration: res,
                              preset: 'custom',
                              name: 'Custom Workout',
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context, TimerProvider timer) {
    final controller = TextEditingController(text: 'My Interval Routine');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Custom Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g. 5K Sprint Blast',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                timer.saveCurrentAsCustomPreset(text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preset "$text" saved!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Duration value;
  final Color color;
  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  const _DurationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '$m min';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF26332A) : const Color(0xFFE5ECE7),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _format(value),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundsStepperTile extends StatelessWidget {
  final int rounds;
  final bool disabled;
  final ValueChanged<int> onChanged;

  const _RoundsStepperTile({
    required this.rounds,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF26332A) : const Color(0xFFE5ECE7),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Number of Rounds',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              Text(
                'Run + Rest pairs',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: (!disabled && rounds > 1)
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(rounds - 1);
                      }
                    : null,
                icon: const Icon(Icons.remove, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$rounds',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: (!disabled && rounds < 99)
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(rounds + 1);
                      }
                    : null,
                icon: const Icon(Icons.add, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/sound_settings.dart';
import '../../providers/timer_provider.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';
import '../widgets/custom_select_sheet.dart';

class AudioSettingsScreen extends StatelessWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final settings = timer.soundSettings;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound & Audio', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // Master Audio Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Master Volume & Sound',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Switch(
                        value: settings.soundEnabled,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          timer.updateSoundSettings(settings.copyWith(soundEnabled: val));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Volume: ${(settings.volume * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: settings.soundEnabled
                            ? () {
                                HapticFeedback.lightImpact();
                                SoundService().playPreview(settings.alertType, settings.volume);
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Test Alert'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: settings.soundEnabled
                        ? (val) {
                            timer.updateSoundSettings(settings.copyWith(volume: val));
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Alert Sound Type Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interval Alert Tone',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose the sound effect played on Run and Rest transitions',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final selected = await CustomSelectSheet.show<AlertSoundType>(
                        context: context,
                        title: 'Select Alert Sound Type',
                        selectedValue: settings.alertType,
                        options: AlertSoundType.values.map((type) {
                          return SelectOption(
                            value: type,
                            title: type.displayName,
                            subtitle: type.description,
                            icon: Icons.notifications_active_rounded,
                          );
                        }).toList(),
                      );
                      if (selected != null) {
                        timer.updateSoundSettings(settings.copyWith(alertType: selected));
                        SoundService().playPreview(selected, settings.volume);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.music_note_rounded, color: primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.alertType.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                Text(
                                  settings.alertType.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Background Music & Audio Ducking Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.headphones_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Background Music',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Run alongside Spotify/Apple Music simultaneously or play built-in workout beats',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () async {
                      final selected = await CustomSelectSheet.show<BackgroundMusicType>(
                        context: context,
                        title: 'Select Background Music Mode',
                        selectedValue: settings.backgroundMusic,
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
                        timer.updateSoundSettings(settings.copyWith(backgroundMusic: selected));
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            settings.backgroundMusic == BackgroundMusicType.none
                                ? Icons.music_off_outlined
                                : Icons.album_rounded,
                            color: primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.backgroundMusic.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                ),
                                Text(
                                  settings.backgroundMusic.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: primary),
                        ],
                      ),
                    ),
                  ),

                  if (settings.backgroundMusic != BackgroundMusicType.none &&
                      settings.backgroundMusic != BackgroundMusicType.externalAudio) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Built-in Music Volume',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        Text(
                          '${(settings.bgMusicVolume * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w700, color: primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.bgMusicVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (val) {
                        timer.updateSoundSettings(settings.copyWith(bgMusicVolume: val));
                      },
                    ),
                  ],

                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: primary, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Audio Ducking is fully enabled: your background Spotify / music app will smoothly lower volume during beeps and continue uninterrupted.',
                            style: TextStyle(fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cadence Metronome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cadence Metronome',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Switch(
                        value: settings.metronomeEnabled,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          timer.updateSoundSettings(settings.copyWith(metronomeEnabled: val));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Helps maintain steady running strides (e.g. 160-180 SPM/BPM)',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tempo: ${settings.metronomeBpm} BPM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primary),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: settings.metronomeEnabled && settings.metronomeBpm > 30
                                ? () {
                                    HapticFeedback.selectionClick();
                                    timer.updateSoundSettings(
                                      settings.copyWith(metronomeBpm: settings.metronomeBpm - 5),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.remove, size: 16),
                            style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            onPressed: settings.metronomeEnabled && settings.metronomeBpm < 300
                                ? () {
                                    HapticFeedback.selectionClick();
                                    timer.updateSoundSettings(
                                      settings.copyWith(metronomeBpm: settings.metronomeBpm + 5),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.add, size: 16),
                            style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Slider(
                    value: settings.metronomeBpm.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 270,
                    onChanged: settings.metronomeEnabled
                        ? (val) {
                            timer.updateSoundSettings(settings.copyWith(metronomeBpm: val.round()));
                          }
                        : null,
                  ),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Play metronome during Rest interval', style: TextStyle(fontSize: 13.5)),
                    value: settings.metronomeDuringRest,
                    onChanged: settings.metronomeEnabled
                        ? (val) {
                            timer.updateSoundSettings(settings.copyWith(metronomeDuringRest: val ?? false));
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Voice Coach & Vibration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Voice Announcements', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Speaks interval cues: "Run", "Rest", "Get ready"'),
                    value: settings.voiceEnabled,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      timer.updateSoundSettings(settings.copyWith(voiceEnabled: val));
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibrate on Transitions', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Tactile haptic pulses for quiet workouts'),
                    value: settings.vibrateEnabled,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      timer.updateSoundSettings(settings.copyWith(vibrateEnabled: val));
                    },
                  ),
                  if (settings.vibrateEnabled) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final selected = await CustomSelectSheet.show<VibrationPattern>(
                          context: context,
                          title: 'Select Vibration Pattern',
                          selectedValue: settings.vibrationPattern,
                          options: VibrationPattern.values.map((v) {
                            return SelectOption(
                              value: v,
                              title: v.displayName,
                              icon: Icons.vibration_rounded,
                            );
                          }).toList(),
                        );
                        if (selected != null) {
                          timer.updateSoundSettings(settings.copyWith(vibrationPattern: selected));
                          VibrationService().vibrate(selected, enabled: true);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pattern: ${settings.vibrationPattern.displayName}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            Icon(Icons.chevron_right_rounded, color: primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

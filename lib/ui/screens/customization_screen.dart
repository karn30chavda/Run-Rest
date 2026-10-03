import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/timer_provider.dart';
import '../widgets/custom_select_sheet.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final timerProv = context.watch<TimerProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance & System', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // Theme Mode Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Theme',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Switch between light, dark, and battery-efficient AMOLED black',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final selected = await CustomSelectSheet.show<AppThemeMode>(
                        context: context,
                        title: 'Select Theme Mode',
                        selectedValue: themeProv.mode,
                        options: const [
                          SelectOption(
                            value: AppThemeMode.system,
                            title: 'System Default',
                            subtitle: 'Follows your device dark/light setting',
                            icon: Icons.brightness_auto_rounded,
                          ),
                          SelectOption(
                            value: AppThemeMode.light,
                            title: 'Light Theme',
                            subtitle: 'Crisp, clean high-contrast daytime layout',
                            icon: Icons.light_mode_rounded,
                          ),
                          SelectOption(
                            value: AppThemeMode.dark,
                            title: 'Dark Charcoal',
                            subtitle: 'Comfortable low-glare dark green/gray interface',
                            icon: Icons.dark_mode_rounded,
                          ),
                          SelectOption(
                            value: AppThemeMode.amoled,
                            title: 'AMOLED Pure Black',
                            subtitle: 'True #000000 black for maximum battery savings during runs',
                            icon: Icons.nightlight_round,
                          ),
                        ],
                      );
                      if (selected != null) {
                        themeProv.setThemeMode(selected);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            themeProv.mode == AppThemeMode.light
                                ? Icons.light_mode_rounded
                                : (themeProv.mode == AppThemeMode.amoled
                                    ? Icons.nightlight_round
                                    : Icons.dark_mode_rounded),
                            color: primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              themeProv.mode.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

          // Accent Color Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accent Color Palette',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personalize the app highlights, dials, and progress rings',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: ThemeProvider.availableAccents.map((c) {
                      final isSelected = themeProv.accentColor.toARGB32() == c.toARGB32();
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          themeProv.setAccentColor(c);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 22)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Screen Wake Lock & System Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Keep Screen Awake', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Prevents display sleep during active workout intervals'),
                    value: timerProv.keepAwake,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      timerProv.setKeepAwake(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('100% Offline & Private', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('All workouts and settings are stored locally on your device.'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Run / Rest Interval Timer', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Version 2.0.0 · Flutter Android Release'),
                  ),
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

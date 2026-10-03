import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_settings_screen.dart';
import 'customization_screen.dart';
import 'history_screen.dart';
import 'timer_screen.dart';
import 'workout_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TimerScreen(),
    WorkoutSetupScreen(),
    AudioSettingsScreen(),
    HistoryScreen(),
    CustomizationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          if (_currentIndex != idx) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = idx;
            });
          }
        },
        height: 68,
        indicatorColor: primary.withValues(alpha: isDark ? 0.22 : 0.15),
        backgroundColor: isDark ? const Color(0xFF141C17) : Colors.white,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded, color: primary),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: primary),
            label: 'Setup',
          ),
          NavigationDestination(
            icon: const Icon(Icons.volume_up_outlined),
            selectedIcon: Icon(Icons.volume_up_rounded, color: primary),
            label: 'Audio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded, color: primary),
            label: 'Theme',
          ),
        ],
      ),
    );
  }
}

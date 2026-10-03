import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationPickerSheet extends StatefulWidget {
  final String title;
  final Duration initialDuration;
  final int minSeconds;
  final int maxSeconds;
  final int stepSeconds;

  const DurationPickerSheet({
    super.key,
    required this.title,
    required this.initialDuration,
    this.minSeconds = 0,
    this.maxSeconds = 3600,
    this.stepSeconds = 5,
  });

  static Future<Duration?> show({
    required BuildContext context,
    required String title,
    required Duration initialDuration,
    int minSeconds = 0,
    int maxSeconds = 3600,
    int stepSeconds = 5,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DurationPickerSheet(
        title: title,
        initialDuration: initialDuration,
        minSeconds: minSeconds,
        maxSeconds: maxSeconds,
        stepSeconds: stepSeconds,
      ),
    );
  }

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  late int _currentSeconds;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.initialDuration.inSeconds.clamp(
      widget.minSeconds,
      widget.maxSeconds,
    );
  }

  void _adjust(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentSeconds = (_currentSeconds + delta).clamp(
        widget.minSeconds,
        widget.maxSeconds,
      );
    });
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '$m min';
    return '$s sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E2822) : Colors.white;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(),

            // Big time display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _formatTime(_currentSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: -1,
                ),
              ),
            ),

            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Slider(
                value: _currentSeconds.toDouble(),
                min: widget.minSeconds.toDouble(),
                max: widget.maxSeconds.toDouble(),
                divisions: (widget.maxSeconds - widget.minSeconds) ~/ widget.stepSeconds,
                onChanged: (val) {
                  setState(() {
                    _currentSeconds = val.round();
                  });
                },
              ),
            ),

            // Quick adjustment chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _QuickChip(label: '-15s', onTap: () => _adjust(-15)),
                  _QuickChip(label: '-5s', onTap: () => _adjust(-5)),
                  _QuickChip(label: '+5s', onTap: () => _adjust(5)),
                  _QuickChip(label: '+15s', onTap: () => _adjust(15)),
                  _QuickChip(label: '+30s', onTap: () => _adjust(30)),
                  _QuickChip(label: '+1m', onTap: () => _adjust(60)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(Duration(seconds: _currentSeconds));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Set Duration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isDark ? const Color(0xFF26332A) : const Color(0xFFE8EFEA),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

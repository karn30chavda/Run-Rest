import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/timeline_item.dart';

class CircularTimerGauge extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (interval progress)
  final String timeFormatted;
  final PhaseType phase;
  final String nextPhaseText;
  final String roundText;
  final bool isRunning;
  final bool isPaused;

  const CircularTimerGauge({
    super.key,
    required this.progress,
    required this.timeFormatted,
    required this.phase,
    required this.nextPhaseText,
    required this.roundText,
    required this.isRunning,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phaseColor = phase.color;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glow
          if (isRunning && !isPaused)
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: phaseColor.withValues(alpha: isDark ? 0.22 : 0.15),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),

          // Custom ring painter
          CustomPaint(
            size: const Size(280, 280),
            painter: _GaugePainter(
              progress: progress,
              color: phaseColor,
              trackColor: isDark ? const Color(0xFF26332A) : const Color(0xFFE2ECE5),
              isDark: isDark,
            ),
          ),

          // Inner content (Phase badge, Countdown, Next phase)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Round indicator
                if (roundText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      roundText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),

                // Phase Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(phase.icon, size: 18, color: phaseColor),
                    const SizedBox(width: 6),
                    Text(
                      isPaused ? 'PAUSED' : phase.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: phaseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Giant Monospace Countdown
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeFormatted,
                    style: GoogleFonts.outfit(
                      fontSize: 78,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -2.0,
                      color: isDark ? Colors.white : const Color(0xFF141C16),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Next interval chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: isDark ? 0.15 : 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: phaseColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    nextPhaseText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active progress arc
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing head dot
    final headAngle = -pi / 2 + sweepAngle;
    final headPoint = Offset(
      center.dx + radius * cos(headAngle),
      center.dy + radius * sin(headAngle),
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPoint, strokeWidth * 0.9, glowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPoint, strokeWidth * 0.35, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

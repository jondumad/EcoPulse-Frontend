import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';
import '../eco_pulse_widgets.dart';

class SemanticMarker extends StatelessWidget {
  final Mission mission;
  final ValueNotifier<double> zoomNotifier;

  const SemanticMarker({
    super.key,
    required this.mission,
    required this.zoomNotifier,
  });

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Environmental':
        return AppTheme.forest;
      case 'Social':
        return AppTheme.violet;
      case 'Educational':
        return AppTheme.ink;
      case 'Health':
        return AppTheme.terracotta;
      default:
        return AppTheme.forest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: zoomNotifier,
      builder: (context, zoom, _) {
        // Transition t: 14.0 -> 15.0 for expansion
        double t = (zoom - 14.0).clamp(0.0, 1.0);
        // Icon visibility t: 11.0 -> 12.0
        // Mini-dot visibility for far zoom (10 -> 12)
        double dotT = (zoom - 10.0).clamp(0.0, 1.0);

        final color = _getCategoryColor(mission.categories.firstOrNull?.name);

        return Transform.scale(
          scale: 0.5 + (0.5 * dotT),
          alignment: Alignment.center,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The Bubble and Caret
                Positioned(
                  bottom:
                      40, // Half of marker height (80/2) to put tip at center
                  left: -80, // Half of marker width (160/2)
                  right: -80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 + (2 * t),
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            t > 0.5 ? 12 : 24,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: dotT),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1 * dotT),
                              blurRadius: 4 * dotT,
                              offset: Offset(0, 4 * t),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: dotT,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * t),
                                child: Text(
                                  mission.categories.firstOrNull?.icon ?? '📍',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            if (t > 0.01)
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: t,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Opacity(
                                      opacity: t,
                                      child: Text(
                                        mission.title.length > 14
                                            ? '${mission.title.substring(0, 14)}...'
                                            : mission.title,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (t > 0.1)
                        Opacity(
                          opacity: t,
                          child: CustomPaint(
                            size: Size(12 * t, 6 * t),
                            painter: _MarkerCaretPainter(color: color),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MarkerCaretPainter extends CustomPainter {
  final Color color;
  _MarkerCaretPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

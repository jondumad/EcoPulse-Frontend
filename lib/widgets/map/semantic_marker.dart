import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';

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
        // Behavior Thresholds
        final bool isExpanded = zoom > 14.5;
        final bool isIconVisible = zoom > 12.0;

        // Overall visibility/scale t (10.0 -> 12.0)
        double scaleT = Curves.easeOut.transform(
          (zoom - 10.0).clamp(0.0, 1.0),
        );

        final color = _getCategoryColor(mission.categories.firstOrNull?.name);
        final bool isUrgent =
            mission.priority == 'Urgent' || mission.priority == 'Emergency';

        return Transform.scale(
          scale: 0.45 + (0.35 * scaleT),
          alignment: Alignment.center,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 12 : 8,
                        vertical: isExpanded ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red.shade700 : color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Icon (Visual Anchor)
                          if (isIconVisible)
                            Text(
                              mission.categories.firstOrNull?.icon ?? '📍',
                              style: TextStyle(
                                fontSize: isExpanded ? 14 : 16,
                              ),
                            ),

                          // Stacked Info (Title & Points)
                          if (isExpanded) ...[
                            const SizedBox(width: 10),
                            // Subtle Separator
                            Container(
                              width: 1,
                              height: 18, // Slightly taller for larger text
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mission.title.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10, // Increased from 8.5
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  '${mission.pointsValue} POINTS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 8, // Increased from 7
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Simple Caret
                    if (isIconVisible)
                      CustomPaint(
                        size: const Size(8, 4),
                        painter: _MarkerCaretPainter(
                          color: isUrgent ? Colors.red.shade700 : color,
                        ),
                      ),
                  ],
                ),

                // Priority Pulse
                if (isUrgent && isIconVisible)
                  _UrgentPulse(color: Colors.red.shade700),
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UrgentPulse extends StatefulWidget {
  final Color color;
  const _UrgentPulse({required this.color});

  @override
  State<_UrgentPulse> createState() => _UrgentPulseState();
}

class _UrgentPulseState extends State<_UrgentPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 32 + (16 * _controller.value),
          height: 24 + (8 * _controller.value),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.color.withValues(alpha: 1.0 - _controller.value),
              width: 1.2,
            ),
          ),
        );
      },
    );
  }
}

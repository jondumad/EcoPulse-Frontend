import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for GoogleFonts
import '../../../../models/mission_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/eco_pulse_widgets.dart';

class TimelineVisuals extends StatelessWidget {
  final Mission mission;
  const TimelineVisuals({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final schedStart = mission.startTime;
        final schedEnd = mission.endTime;
        final actualStart = mission.actualStartTime;
        final actualEnd = mission.actualEndTime;
        final now = DateTime.now();

        // Contextual late start clipping
        final bool isStartLate =
            actualStart != null &&
            actualStart.difference(schedStart).inMinutes > 20;

        DateTime minTime = schedStart;
        if (actualStart != null) {
          if (isStartLate) {
            minTime = actualStart.subtract(const Duration(minutes: 10));
          } else if (actualStart.isBefore(minTime)) {
            minTime = actualStart;
          }
        }

        DateTime maxTime = schedEnd;
        if (actualEnd != null && actualEnd.isAfter(maxTime)) {
          maxTime = actualEnd;
        } else if (mission.status == 'InProgress' && now.isAfter(maxTime)) {
          maxTime = now;
        }

        final rangeDuration = maxTime.difference(minTime).inMilliseconds;
        final paddingMs = (rangeDuration * 0.12).toInt();
        final displayMin = minTime.subtract(Duration(milliseconds: paddingMs));
        final displayMax = maxTime.add(Duration(milliseconds: paddingMs));
        final totalDisplayDuration = displayMax
            .difference(displayMin)
            .inMilliseconds;

        if (totalDisplayDuration <= 0) return const SizedBox();

        double getX(DateTime time) {
          final diff = time.difference(displayMin).inMilliseconds;
          return (diff / totalDisplayDuration) * width;
        }

        final bool isSchedStartOffscreen = getX(schedStart) < 0;

        // Dynamic Staggering Logic:
        // If markers are closer than 50px, we flag the second one to be staggered vertically.
        final bool staggerPlan =
            !isSchedStartOffscreen &&
            (getX(schedEnd) - getX(schedStart)).abs() < 50;

        final bool staggerActual =
            actualStart != null &&
            actualEnd != null &&
            (getX(actualEnd) - getX(actualStart)).abs() < 50;

        return Container(
          height: 70, // Slightly more room for badges
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // 1. Timeline Axis
              Positioned(
                left: 0,
                right: 0,
                top: 35,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EcoColors.clay.withValues(alpha: 0.1),
                        EcoColors.clay,
                        EcoColors.clay.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Scheduled Reference (Ghost Bar)
              Builder(
                builder: (context) {
                  final startX = math.max(0.0, getX(schedStart));
                  final endX = math.max(0.0, getX(schedEnd));

                  return Positioned(
                    left: startX,
                    width: math.max(2.0, endX - startX),
                    top: 32,
                    bottom: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: EcoColors.ink.withValues(alpha: 0.05),
                        borderRadius: isSchedStartOffscreen
                            ? const BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              )
                            : BorderRadius.circular(6),
                        border: Border(
                          top: BorderSide(
                            color: EcoColors.ink.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                          bottom: BorderSide(
                            color: EcoColors.ink.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                          right: BorderSide(
                            color: EcoColors.ink.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                          left: isSchedStartOffscreen
                              ? BorderSide.none
                              : BorderSide(
                                  color: EcoColors.ink.withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                        ),
                      ),
                      child: isSchedStartOffscreen
                          ? CustomPaint(painter: _BrokenEdgePainter())
                          : null,
                    ),
                  );
                },
              ),

              // 3. Actual Progress (Forest Gradient)
              if (actualStart != null) ...[
                Builder(
                  builder: (context) {
                    final endPoint =
                        actualEnd ??
                        (mission.status == 'InProgress' ? now : actualStart);
                    final startX = getX(actualStart);
                    final barWidth = math.max(4.0, getX(endPoint) - startX);

                    return Positioned(
                      left: startX,
                      width: barWidth,
                      top: 33,
                      bottom: 33,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              EcoColors.forest,
                              EcoColors.forest.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: EcoColors.forest.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              // 4. Markers (Needle Design)

              // Planned Markers (Top)
              if (!isSchedStartOffscreen)
                _buildCompactMarker(
                  context,
                  getX(schedStart),
                  time: schedStart,
                  label: 'PLAN',
                  isTop: true,
                  color: EcoColors.ink.withValues(alpha: 0.4),
                ),

              _buildCompactMarker(
                context,
                getX(schedEnd),
                time: schedEnd,
                label: 'END',
                isTop: true,
                color: EcoColors.ink.withValues(alpha: 0.4),
                isStaggered: staggerPlan,
              ),

              // Actual Markers (Bottom)
              if (actualStart != null)
                _buildCompactMarker(
                  context,
                  getX(actualStart),
                  time: actualStart,
                  label: 'START',
                  isTop: false,
                  color: EcoColors.forest,
                  isBold: true,
                ),

              if (actualEnd != null)
                _buildCompactMarker(
                  context,
                  getX(actualEnd),
                  time: actualEnd,
                  label: 'FINAL',
                  isTop: false,
                  color: EcoColors.forest,
                  isBold: true,
                  isStaggered: staggerActual,
                ),

              // Pulsing "NOW" Node
              if (mission.status == 'InProgress')
                Positioned(
                  left: getX(now) - 6,
                  top: 28,
                  child: _buildLiveNode(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveNode() {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: EcoColors.terracotta,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EcoColors.terracotta.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LIVE',
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w900,
            color: EcoColors.terracotta,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMarker(
    BuildContext context,
    double x, {
    required DateTime time,
    required String label,
    required bool isTop,
    required Color color,
    bool isBold = false,
    bool isStaggered = false,
  }) {
    final double connectorHeight = isStaggered ? 24.0 : 6.0;

    return Positioned(
      left: x - 25,
      width: 50,
      // Anchor to the center axis (top: 35 for Bottom items, bottom: 35 for Top items)
      top: isTop ? null : 35,
      bottom: isTop ? 35 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isTop) ...[
            Container(
              height: connectorHeight,
              width: 1,
              color: color.withValues(alpha: 0.3),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: GoogleFonts.fraunces(
                      fontSize: 10,
                      fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isTop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: GoogleFonts.fraunces(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: connectorHeight,
              width: 1,
              color: color.withValues(alpha: 0.3),
            ),
          ],
        ],
      ),
    );
  }
}

// Stylized "Technical Break" for truncated bars (Continuity Symbol)
class _BrokenEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw two professional parallel slants (//) representing a "Section Break"
    final slashPaint = Paint()
      ..color = EcoColors.ink.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // First Slash (Centered)
    const double span = 6.0;
    final double midY = size.height / 2;
    canvas.drawLine(
      Offset(2, midY - span),
      Offset(10, midY + span),
      slashPaint,
    );
    // Second Slash (Centered)
    canvas.drawLine(
      Offset(6, midY - span),
      Offset(14, midY + span),
      slashPaint,
    );

    // 2. Add a soft gradient mask from the left to blend into the background
    final maskPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, Colors.white.withValues(alpha: 0)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, midY - 6, 15, 12));

    canvas.drawRect(Rect.fromLTWH(0, midY - 6, 20, 12), maskPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

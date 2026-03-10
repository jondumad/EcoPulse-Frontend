import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'dart:math' as math;
import '../../utils/map_utils.dart';

class MapOffScreenIndicator extends StatelessWidget {
  final ll.LatLng position;
  final Color color;
  final IconData icon;
  final MapCamera camera;
  final BoxConstraints constraints;
  final double topPadding;
  final double bottomPadding;
  final double leftPadding;
  final double rightPadding;
  final List<Rect>? obstructions;
  final bool isZoomedOut;
  final VoidCallback onTap;
  final bool offsetIfOverlapping;

  final int index;

  const MapOffScreenIndicator({
    super.key,
    required this.position,
    required this.color,
    required this.icon,
    required this.camera,
    required this.constraints,
    required this.onTap,
    this.index = 0,
    this.topPadding = 40.0,
    this.bottomPadding = 40.0,
    this.leftPadding = 45.0,
    this.rightPadding = 45.0,
    this.obstructions,
    this.isZoomedOut = false,
    this.offsetIfOverlapping = false,
  });

  @override
  Widget build(BuildContext context) {
    if (camera.zoom == 0) return const SizedBox.shrink();

    final screenPoint = camera.latLngToScreenOffset(position);

    final safeZone = Rect.fromLTRB(
      leftPadding - 20,
      topPadding - 20,
      constraints.maxWidth - rightPadding + 20,
      constraints.maxHeight - bottomPadding + 20,
    );

    // Only show if outside safe zone
    if (safeZone.contains(screenPoint)) return const SizedBox.shrink();

    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    final rect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      constraints.maxWidth - rightPadding,
      constraints.maxHeight - bottomPadding,
    );

    final edgePoint = MapUtils.calculateIntersection(center, screenPoint, rect);
    final angle = MapUtils.calculateAngle(center, screenPoint);

    Offset finalPos = edgePoint;
    if (offsetIfOverlapping) {
      // Stagger markers based on index to prevent clumping
      finalPos = Offset(edgePoint.dx + (index * 8), edgePoint.dy + (index * 8));
    }

    // --- Precise Selection Refactor: Multidirectional Obstruction Avoidance ---
    if (obstructions != null && obstructions!.isNotEmpty) {
      const double indicatorSize = 44.0;
      const double halfSize = indicatorSize / 2;
      const double buffer = 6.0;
      
      // Predictable handling order
      final sortedObs = List<Rect>.from(obstructions!)
        ..sort((a, b) => a.top.compareTo(b.top));

      for (final obs in sortedObs) {
        Rect indicatorRect = Rect.fromCenter(
          center: finalPos,
          width: indicatorSize + buffer,
          height: indicatorSize + buffer,
        );

        if (obs.overlaps(indicatorRect)) {
          // Calculate potential escape positions in all 4 directions
          // 1. Above the obstruction
          final posTop = Offset(finalPos.dx, obs.top - halfSize - buffer);
          // 2. Below the obstruction
          final posBottom = Offset(finalPos.dx, obs.bottom + halfSize + buffer);
          // 3. To the left of the obstruction
          final posLeft = Offset(obs.left - halfSize - buffer, finalPos.dy);
          // 4. To the right of the obstruction
          final posRight = Offset(obs.right + halfSize + buffer, finalPos.dy);

          // Define candidates with their validity and distance from original edge point
          final candidates = [
            {'pos': posTop, 'dist': (finalPos - posTop).distance, 'valid': posTop.dy >= topPadding},
            {'pos': posBottom, 'dist': (finalPos - posBottom).distance, 'valid': posBottom.dy <= (constraints.maxHeight - bottomPadding)},
            {'pos': posLeft, 'dist': (finalPos - posLeft).distance, 'valid': posLeft.dx >= leftPadding},
            {'pos': posRight, 'dist': (finalPos - posRight).distance, 'valid': posRight.dx <= (constraints.maxWidth - rightPadding)},
          ];

          // Filter for valid moves only
          final validCandidates = candidates.where((c) => c['valid'] == true).toList();
          
          if (validCandidates.isNotEmpty) {
            // Sort by distance (least movement wins)
            validCandidates.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
            finalPos = validCandidates.first['pos'] as Offset;
          }
        }
      }
    }

    return Positioned(
      left: finalPos.dx - 22,
      top: finalPos.dy - 22,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Arrow Indicator
              Transform.translate(
                offset: Offset(math.cos(angle) * 26, math.sin(angle) * 26),
                child: Transform.rotate(
                  angle: angle + (math.pi / 2),
                  child: CustomPaint(
                    size: const Size(12, 8),
                    painter: ArrowPainter(color: color),
                  ),
                ),
              ),
              // Main Circle
              Container(
                width: isZoomedOut ? 24 : 40,
                height: isZoomedOut ? 24 : 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isZoomedOut
                    ? null
                    : Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

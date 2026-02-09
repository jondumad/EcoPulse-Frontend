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
  final double bottomPadding;
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
    this.bottomPadding = 150.0,
    this.isZoomedOut = false,
    this.offsetIfOverlapping = false,
  });

  @override
  Widget build(BuildContext context) {
    if (camera.zoom == 0) return const SizedBox.shrink();

    final screenPoint = camera.latLngToScreenOffset(position);

    const horizontalPadding = 45.0;
    const topPadding = 40.0;

    final safeZone = Rect.fromLTRB(
      0,
      topPadding - 20,
      constraints.maxWidth,
      constraints.maxHeight - bottomPadding + 20,
    );

    // Only show if outside safe zone
    if (safeZone.contains(screenPoint)) return const SizedBox.shrink();

    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    final rect = Rect.fromLTRB(
      horizontalPadding,
      topPadding,
      constraints.maxWidth - horizontalPadding,
      constraints.maxHeight - bottomPadding,
    );

    final edgePoint = MapUtils.calculateIntersection(center, screenPoint, rect);
    final angle = MapUtils.calculateAngle(center, screenPoint);

    Offset finalPos = edgePoint;
    if (offsetIfOverlapping) {
      // Stagger markers based on index to prevent clumping
      finalPos = Offset(edgePoint.dx + (index * 8), edgePoint.dy + (index * 8));
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

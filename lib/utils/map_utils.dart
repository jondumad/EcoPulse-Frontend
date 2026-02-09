import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class MapUtils {
  /// Calculates the intersection point between a line from the center to the target
  /// and the boundary rectangle defined by the safe area.
  static Offset calculateIntersection(Offset center, Offset point, Rect rect) {
    // If the point is actually inside, just return it (though usually called when outside)
    if (rect.contains(point)) return point;

    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // Avoid division by zero
    if (dx == 0 && dy == 0) return center;

    double tMin = double.infinity;

    // Check intersection with left/right
    if (dx > 0) {
      tMin = math.min(tMin, (rect.right - center.dx) / dx);
    } else if (dx < 0) {
      tMin = math.min(tMin, (rect.left - center.dx) / dx);
    }

    // Check intersection with top/bottom
    if (dy > 0) {
      tMin = math.min(tMin, (rect.bottom - center.dy) / dy);
    } else if (dy < 0) {
      tMin = math.min(tMin, (rect.top - center.dy) / dy);
    }

    // If tMin is still infinity, something is wrong, but just return center or point
    if (tMin == double.infinity) return point;

    return Offset(center.dx + tMin * dx, center.dy + tMin * dy);
  }

  /// Calculates the angle in radians between the center of the screen and a point.
  static double calculateAngle(Offset center, Offset point) {
    return math.atan2(point.dy - center.dy, point.dx - center.dx);
  }
}

/// Helper class to handle smooth map animations
class MapAnimationHelper {
  final MapController mapController;
  final TickerProvider vsync;
  AnimationController? _animationController;
  DateTime? _lastStartTime;

  MapAnimationHelper({required this.mapController, required this.vsync});

  bool get isAnimating => _animationController?.isAnimating ?? false;

  void move(ll.LatLng destLocation, double destZoom) {
    // Gracefully stop previous animation if any
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;

    _lastStartTime = DateTime.now();

    final camera = mapController.camera;
    final startLat = camera.center.latitude;
    final startLng = camera.center.longitude;
    final startZoom = camera.zoom;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400), // Slightly longer for the sequence
      vsync: vsync,
    );

    final latTween = Tween<double>(begin: startLat, end: destLocation.latitude);
    final lngTween = Tween<double>(
      begin: startLng,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    // Staggered intervals to avoid the "neurotic" simultaneous jump.
    // Movement starts immediately and reaches 95% completion at 80% of the time.
    final moveAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.0, 0.8, curve: Curves.fastOutSlowIn),
    );

    // Zoom starts later (at 20% progress) and finishes at 100%.
    // This creates the "Pan -> Zoom" feeling the user wants.
    final zoomAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.2, 1.0, curve: Curves.fastOutSlowIn),
    );

    void updateMap() {
      if (_animationController == null) return;
      
      final currentLat = latTween.evaluate(moveAnimation);
      final currentLng = lngTween.evaluate(moveAnimation);
      final currentZoom = zoomTween.evaluate(zoomAnimation);

      mapController.move(
        ll.LatLng(currentLat, currentLng),
        currentZoom,
      );
    }

    _animationController!.addListener(updateMap);

    // Ensure we start exactly at the beginning
    updateMap();

    _animationController!.forward();
  }

  void stop({bool force = false}) {
    if (!force && _lastStartTime != null) {
      final elapsed = DateTime.now().difference(_lastStartTime!).inMilliseconds;
      if (elapsed < 100) return; // Prevent "ghost" gesture cancellations
    }

    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.dispose();
      _animationController = null;
    }
  }

  void dispose() {
    stop();
  }
}

/// Shared painter for the directional arrow on off-screen indicators
class ArrowPainter extends CustomPainter {
  final Color color;
  ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

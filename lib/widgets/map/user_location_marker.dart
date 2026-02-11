import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/location_provider.dart';

// 1. Create Calibration Status Enum
enum CalibrationStatus { excellent, good, fair, poor, unreliable }

class UserLocationMarker extends StatelessWidget {
  final ll.LatLng position;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<double>? rotationNotifier;
  final bool showCone;

  const UserLocationMarker({
    super.key,
    required this.position,
    required this.zoomNotifier,
    this.rotationNotifier,
    this.showCone = true,
  });

  // 3. Helper Methods
  CalibrationStatus _getCalibrationStatus(double? accuracy) {
    if (accuracy == null || accuracy == -1 || accuracy > 45) {
      return CalibrationStatus.unreliable;
    }
    if (accuracy <= 10) return CalibrationStatus.excellent;
    if (accuracy <= 20) return CalibrationStatus.good;
    if (accuracy <= 35) return CalibrationStatus.fair;
    return CalibrationStatus.poor;
  }

  bool _shouldShowCone(CalibrationStatus status) {
    return status != CalibrationStatus.unreliable;
  }

  double _getConeOpacity(CalibrationStatus status) {
    switch (status) {
      case CalibrationStatus.excellent:
        return 0.6;
      case CalibrationStatus.good:
        return 0.4;
      case CalibrationStatus.fair:
        return 0.25;
      case CalibrationStatus.poor:
        return 0.15;
      case CalibrationStatus.unreliable:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final heading = locationProvider.heading;
    final accuracy = locationProvider.headingAccuracy;
    final status = _getCalibrationStatus(accuracy);

    return ValueListenableBuilder<double>(
      valueListenable: zoomNotifier,
      builder: (context, currentZoom, _) {
        // More robust scaling:
        // At zoom 15: size = 80
        // At zoom 5: size = 45 (minimum clamp)
        // At zoom 18: size = 92
        final double size = (currentZoom * 4 + 20).clamp(45.0, 100.0);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 7. Update Cone Rendering
              if (showCone && _shouldShowCone(status))
                Transform.rotate(
                  angle: (heading * (math.pi / 180)),
                  child: CustomPaint(
                    size: Size(size * 3, size * 3),
                    painter: _ConePainter(
                      color: AppTheme.violet,
                      opacity: _getConeOpacity(status),
                    ),
                  ),
                ),

              // 2. Pulsing Dot
              UserLocationPulseWrapper(
                child: Container(
                  width: size * 0.4,
                  height: size * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: rotationNotifier != null
                        ? ValueListenableBuilder<double>(
                            valueListenable: rotationNotifier!,
                            builder: (context, rotation, _) {
                              return Transform.rotate(
                                angle: -rotation * (math.pi / 180),
                                child: _buildCore(size),
                              );
                            },
                          )
                        : _buildCore(size),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCore(double size) {
    return Container(
      width: size * 0.35,
      height: size * 0.35,
      decoration: const BoxDecoration(
        color: AppTheme.violet,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: (size * 0.2).clamp(14.0, 24.0),
      ),
    );
  }
}

class _ConePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _ConePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = RadialGradient(
      colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)],
      stops: const [0.0, 1.0],
      center: Alignment.center,
      radius: 0.8,
    ).createShader(rect);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      -math.pi / 2 - 0.7,
      1.4,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

class UserLocationPulseWrapper extends StatefulWidget {
  final Widget child;
  const UserLocationPulseWrapper({super.key, required this.child});

  @override
  State<UserLocationPulseWrapper> createState() => _PulseState();
}

class _PulseState extends State<UserLocationPulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
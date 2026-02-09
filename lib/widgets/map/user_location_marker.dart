import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

// 1. Create Calibration Status Enum
enum CalibrationStatus { excellent, good, fair, poor, unreliable }

class UserLocationMarker extends StatefulWidget {
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

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker> {
  double? _heading;
  
  // 2. Add State Variables
  double? _headingAccuracy;
  bool _showCalibrationBanner = false;
  DateTime? _lastDismissedBanner;

  @override
  void initState() {
    super.initState();
    if (widget.showCone) {
      // 4. Update Compass Listener
      FlutterCompass.events?.listen((event) {
        if (!mounted) return;

        final status = _getCalibrationStatus(event.accuracy);
        
        setState(() {
          _heading = event.heading;
          _headingAccuracy = event.accuracy;

          // Auto-hide banner when accuracy improves
          if (status == CalibrationStatus.excellent || status == CalibrationStatus.good) {
            _showCalibrationBanner = false;
          } 
          // Show banner based on status and cooldown (5 minutes)
          else if (status == CalibrationStatus.poor || status == CalibrationStatus.unreliable) {
            bool isCooldownOver = _lastDismissedBanner == null || 
                DateTime.now().difference(_lastDismissedBanner!) > const Duration(minutes: 5);
            
            if (isCooldownOver) {
              _showCalibrationBanner = true;
            }
          }
        });
      });
    }
  }

  // 3. Create Helper Methods
  CalibrationStatus _getCalibrationStatus(double? accuracy) {
    if (accuracy == null || accuracy == -1 || accuracy > 45) return CalibrationStatus.unreliable;
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
      case CalibrationStatus.excellent: return 0.6;
      case CalibrationStatus.good: return 0.4;
      case CalibrationStatus.fair: return 0.25;
      case CalibrationStatus.poor: return 0.15;
      case CalibrationStatus.unreliable: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getCalibrationStatus(_headingAccuracy);

    return ValueListenableBuilder<double>(
      valueListenable: widget.zoomNotifier,
      builder: (context, currentZoom, _) {
        final double size = 80 * (currentZoom / 15).clamp(0.5, 1.5);

        // 9. Integrate Banner into UI (Wrapped in Stack)
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Calibration Banner
            if (_showCalibrationBanner)
              Positioned(
                top: -size * 0.8,
                child: CalibrationBanner(
                  onDismiss: () {
                    setState(() {
                      _showCalibrationBanner = false;
                      _lastDismissedBanner = DateTime.now();
                    });
                  },
                ),
              ),

            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 7. Update Cone Rendering
                  if (widget.showCone && _heading != null && _shouldShowCone(status))
                    Transform.rotate(
                      angle: (_heading! * (math.pi / 180)),
                      child: CustomPaint(
                        size: Size(size * 3, size * 3),
                        painter: _ConePainter(
                          color: AppTheme.violet,
                          opacity: _getConeOpacity(status), // 6. Pass dynamic opacity
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
                        child: Stack(
                          children: [
                            widget.rotationNotifier != null
                                ? ValueListenableBuilder<double>(
                                    valueListenable: widget.rotationNotifier!,
                                    builder: (context, rotation, _) {
                                      return Transform.rotate(
                                        angle: -rotation * (math.pi / 180),
                                        child: _buildCore(size),
                                      );
                                    },
                                  )
                                : _buildCore(size),
                            
                            // 8. Add Accuracy Badge
                            if (status == CalibrationStatus.poor || status == CalibrationStatus.unreliable)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCore(double size) {
    return Container(
      width: size * 0.3,
      height: size * 0.3,
      decoration: const BoxDecoration(
        color: AppTheme.violet,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 16),
    );
  }
}

// 5. Create CalibrationBanner Widget
class CalibrationBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const CalibrationBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      tween: Tween(begin: const Offset(0, -20), end: const Offset(0, 0)),
      builder: (context, offset, child) {
        return Transform.translate(
          offset: offset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.compass_calibration, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Calibrate - Move in figure-8",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Colors.white54, size: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConePainter extends CustomPainter {
  final Color color;
  final double opacity; // 6. Add opacity parameter
  
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

class _PulseState extends State<UserLocationPulseWrapper> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
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
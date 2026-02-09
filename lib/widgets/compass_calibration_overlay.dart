import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';

class CompassCalibrationOverlay extends StatefulWidget {
  const CompassCalibrationOverlay({super.key});

  @override
  State<CompassCalibrationOverlay> createState() => _CompassCalibrationOverlayState();
}

class _CompassCalibrationOverlayState extends State<CompassCalibrationOverlay> {
  bool _isVisible = false;
  DateTime? _lastDismissed;

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final accuracy = locationProvider.headingAccuracy;
    
    // Determine visibility based on accuracy and cooldown
    if (accuracy == null || accuracy == -1 || accuracy <= 20) {
      // Good accuracy, hide
      if (_isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isVisible = false);
        });
      }
    } else if (accuracy > 35) {
      // Poor accuracy, check cooldown (5 mins)
      bool isCooldownOver = _lastDismissed == null || 
          DateTime.now().difference(_lastDismissed!) > const Duration(minutes: 5);
      
      if (isCooldownOver && !_isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isVisible = true);
        });
      }
    }

    if (!_isVisible) return const SizedBox.shrink();

    // Calculate progress
    double progress = 0.0;
    if (accuracy != null && accuracy != -1 && accuracy < 45) {
      progress = ((45 - accuracy) / 35.0).clamp(0.0, 1.0);
    }
    final percentage = (progress * 100).toInt();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: TweenAnimationBuilder<Offset>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            tween: Tween(begin: const Offset(0, -100), end: const Offset(0, 0)),
            builder: (context, offset, child) {
              return Transform.translate(
                offset: offset,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.compass_calibration,
                                color: AppTheme.violet, size: 22),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVisible = false;
                                  _lastDismissed = DateTime.now();
                                });
                              },
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Calibrating Compass",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Move your phone in a figure-8",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: AppTheme.violet.withValues(alpha: 0.1),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(AppTheme.violet),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$percentage%",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.violet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';

class CompassCalibrationOverlay extends StatefulWidget {
  const CompassCalibrationOverlay({super.key});

  @override
  State<CompassCalibrationOverlay> createState() =>
      _CompassCalibrationOverlayState();
}

class _CompassCalibrationOverlayState extends State<CompassCalibrationOverlay> {
  bool _isVisible = false;
  bool _isExpanded = false;
  DateTime? _lastDismissed;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final locationProvider = Provider.of<LocationProvider>(context);
    final accuracy = locationProvider.headingAccuracy;

    // Determine visibility based on accuracy and cooldown
    if ((accuracy == null || accuracy == -1 || accuracy <= 10) && _isVisible) {
      // Good accuracy or no data, hide if visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isVisible = false);
      });
    } else if (accuracy == null || accuracy > 10) {
      // Poor accuracy or null (unreliable), check cooldown (5 mins)
      bool isCooldownOver =
          _lastDismissed == null ||
          DateTime.now().difference(_lastDismissed!) >
              const Duration(minutes: 5);

      if (isCooldownOver && !_isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isVisible = true);
        });
      }
    }

    if (!_isVisible) return const SizedBox.shrink();

    return SafeArea(
      child: _isExpanded
          ? _buildExpandedView(accuracy)
          : _buildCompactView(accuracy),
    );
  }

  Widget _buildCompactView(double? accuracy) {
    // Calculate progress
    double progress = 0.0;
    if (accuracy != null && accuracy != -1 && accuracy < 45) {
      progress = ((45 - accuracy) / 35.0).clamp(0.0, 1.0);
    }
    final percentage = (progress * 100).toInt();

    return Align(
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
              child: GestureDetector(
                onTap: () => setState(() => _isExpanded = true),
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
                            const Icon(
                              Icons.compass_calibration,
                              color: AppTheme.violet,
                              size: 22,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVisible = false;
                                  _lastDismissed = DateTime.now();
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
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
                            backgroundColor: AppTheme.violet.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.violet,
                            ),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandedView(double? accuracy) {
    // Calculate progress
    double progress = 0.0;
    if (accuracy != null && accuracy != -1 && accuracy < 45) {
      progress = ((45 - accuracy) / 35.0).clamp(0.0, 1.0);
    }
    final percentage = (progress * 100).toInt();

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.compass_calibration,
                        color: AppTheme.violet,
                        size: 32,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isVisible = false;
                            _lastDismissed = DateTime.now();
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Compass Calibration Needed",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your compass needs calibration for accurate navigation. Follow these steps:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "1. Hold your phone flat",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "2. Move it in a figure-8 pattern slowly",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "3. Rotate it around all axes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "4. Keep moving until calibration completes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 15,
                      backgroundColor: AppTheme.violet.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Calibration Progress: $percentage%",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.violet,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Tap anywhere to minimize",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

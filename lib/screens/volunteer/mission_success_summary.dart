import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/formatters.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/atoms/eco_card.dart';

class MissionSuccessSummaryScreen extends StatefulWidget {
  final String missionTitle;
  final Duration duration;
  final int pointsEarned;

  const MissionSuccessSummaryScreen({
    super.key,
    required this.missionTitle,
    required this.duration,
    required this.pointsEarned,
  });

  @override
  State<MissionSuccessSummaryScreen> createState() =>
      _MissionSuccessSummaryScreenState();
}

class _MissionSuccessSummaryScreenState
    extends State<MissionSuccessSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final Animation<double> _scaleAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
        ),
      );

  late final Animation<double> _fadeAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
        ),
      );

  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.forest,
      body: Stack(
        children: [
          // Background decorative elements (optional subtle gradients)
          Positioned(
            top: -100,
            right: -100,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Success Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.violet,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.violet.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Texts
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            'MISSION COMPLETE!',
                            style: EcoText.displayLG(context).copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 28, // Slightly adjusted for fit
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.missionTitle,
                              style: EcoText.bodyMD(context).copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Stats Card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: EcoPulseCard(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            // Card Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.clay,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.clay,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '✨',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'IMPACT SUMMARY',
                                          style: EcoText.monoSM(context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Great work, Volunteer!',
                                          style: EcoText.bodySM(context)
                                              .copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stats Grid
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: EcoStatItem(
                                      label: 'DURATION',
                                      value:
                                          EcoFormatters.formatSummaryDuration(
                                            widget.duration,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: AppTheme.clay,
                                  ),
                                  Expanded(
                                    child: EcoAnimatedStatItem(
                                      label: 'POINTS EARNED',
                                      value: widget.pointsEarned.toDouble(),
                                      color: AppTheme.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Footer / Note
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              decoration: const BoxDecoration(
                                color: AppTheme.clay,
                              ),
                              child: Text(
                                'Points pending final verification by coordinator',
                                style: EcoText.monoSM(context).copyWith(
                                  fontSize: 9,
                                  color: AppTheme.ink.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Done Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: EcoPulseButton(
                        label: 'BACK TO DASHBOARD',
                        variant: EcoButtonVariant.secondary,
                        // White button with Forest text for contrast against Forest BG
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.forest,
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

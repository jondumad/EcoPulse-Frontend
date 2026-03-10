import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../widgets/atoms/eco_button.dart';

class CheckInContextualPanel extends StatelessWidget {
  final bool isScanning;
  final bool isInRange;
  final bool isNavExpanded;
  final int distance;
  final String missionGps;
  final VoidCallback onToggleNav;
  final Function(ll.LatLng, double) onAnimatedMapMove;
  final Function(String, IconData, VoidCallback, {bool isFullWidth})
  buildActionButton;
  final Function(String, String, bool, {required IconData icon}) buildStepItem;
  final VoidCallback onStartVerification;
  final Widget scannerWidget;

  const CheckInContextualPanel({
    super.key,
    required this.isScanning,
    required this.isInRange,
    required this.isNavExpanded,
    required this.distance,
    required this.missionGps,
    required this.onToggleNav,
    required this.onAnimatedMapMove,
    required this.buildActionButton,
    required this.buildStepItem,
    required this.onStartVerification,
    required this.scannerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _getCurrentStateWidget(context),
        ),
      ),
    );
  }

  Widget _getCurrentStateWidget(BuildContext context) {
    if (isScanning) {
      return scannerWidget;
    } else if (isInRange) {
      return _buildProximityState();
    } else {
      return _buildNavigationState(context);
    }
  }

  Widget _buildNavigationState(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleNav,
        child: Container(
          key: const ValueKey('nav_state'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EcoColors.terracotta.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: EcoColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'APPROACH SITE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: EcoColors.ink.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '$distance meters away',
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isNavExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: EcoColors.ink.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              if (isNavExpanded) ...[
                const SizedBox(height: 24),
                _SectionHeader(title: 'YOUR PROGRESS'),
                const SizedBox(height: 12),
                buildStepItem(
                  'Reach Site',
                  'Walk to the coordinate point',
                  isInRange,
                  icon: Icons.directions_walk,
                ),
                if (!isInRange)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48,
                      top: 4,
                      bottom: 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (1000 - distance.clamp(0, 1000)) / 900,
                        backgroundColor: EcoColors.ink.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation(
                          EcoColors.terracotta,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                buildStepItem(
                  'Locate Coordinator',
                  'Find the mission flag/QR code',
                  false,
                  icon: Icons.qr_code_scanner,
                ),
                buildStepItem(
                  'Verify Scan',
                  'Scanner unlocks automatically',
                  false,
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'QUICK ACTIONS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: buildActionButton(
                        'Directions',
                        Icons.map_outlined,
                        () {}, // Handled by parent
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildActionButton(
                        'Locate Flag',
                        Icons.flag_outlined,
                        () {
                          final parts = missionGps.split(',');
                          if (parts.length == 2) {
                            onAnimatedMapMove(
                              ll.LatLng(
                                double.tryParse(parts[0]) ?? 0,
                                double.tryParse(parts[1]) ?? 0,
                              ),
                              16.0,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildActionButton(
                  'Need Help? Contact Coordinator',
                  Icons.support_agent,
                  () {}, // Handled by parent
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProximityState() {
    return Container(
      key: const ValueKey('prox_state'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EcoColors.forest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: EcoColors.forest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You have arrived!',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: EcoColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are within range of the coordination point. Ready to verify?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: EcoColors.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: EcoPulseButton(
              label: 'START VERIFICATION',
              onPressed: onStartVerification,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: EcoColors.ink.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: EcoColors.ink.withValues(alpha: 0.1))),
      ],
    );
  }
}

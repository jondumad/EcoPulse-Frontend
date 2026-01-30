import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/grain_overlay.dart';

class MissionSuccessSummaryScreen extends StatelessWidget {
  final String missionTitle;
  final Duration duration;
  final int pointsEarned;

  const MissionSuccessSummaryScreen({
    super.key,
    required this.missionTitle,
    required this.duration,
    required this.pointsEarned,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.forest,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.violet,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.violet.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'MISSION COMPLETE!',
                    style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    missionTitle,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(4, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'DURATION',
                          value: _formatDuration(duration),
                        ),
                        const Divider(height: 32, color: AppTheme.borderSubtle),
                        _SummaryRow(
                          label: 'POINTS EARNED',
                          value: '+$pointsEarned',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Points pending verification',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pop until we are back at the main shell
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.terracotta,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      child: const Text('BACK TO DASHBOARD'),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: AppTheme.ink.withValues(alpha: 0.5),
            fontFamily: 'JetBrains Mono',
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: isHighlight ? AppTheme.forest : AppTheme.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

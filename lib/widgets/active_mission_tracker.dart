import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/attendance_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import 'atoms/eco_button.dart';
import 'atoms/eco_card.dart';
import '../screens/volunteer/mission_success_summary.dart';
import '../screens/volunteer/mission_detail_screen.dart';
import 'package:frontend/theme/app_theme.dart';
import '../models/mission_model.dart';
import '../utils/formatters.dart';

class ActiveMissionTracker extends StatefulWidget {
  const ActiveMissionTracker({super.key});

  @override
  State<ActiveMissionTracker> createState() => _ActiveMissionTrackerState();
}

class _ActiveMissionTrackerState extends State<ActiveMissionTracker> {
  Timer? _timer;
  Timer? _inactivityTimer;
  Duration _elapsed = Duration.zero;
  bool _isCheckingOut = false;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    int secondsRemaining = 8;
    debugPrint(
      'Inactivity timer started: $secondsRemaining seconds until collapsed',
    );

    // Collapse after 8 seconds of inactivity
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;
      if (secondsRemaining > 0) {
        debugPrint('Inactivity: $secondsRemaining seconds until collapsed');
      } else {
        timer.cancel();
        debugPrint('Inactivity timer reached 0, collapsing widget.');
        if (mounted && !_isCollapsed) {
          setState(() {
            _isCollapsed = true;
          });
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final attendance = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).currentAttendance;
      if (attendance != null && attendance['checkInTime'] != null) {
        final checkInTime = DateTime.parse(attendance['checkInTime']);
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(checkInTime);
          });
        }
      }
    });
  }

  void _handleInteraction() {
    if (_isCollapsed) {
      setState(() => _isCollapsed = false);
    }
    _resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final attendance = attendanceProvider.currentAttendance;

        if (attendance == null) return const SizedBox.shrink();

        final mission = attendance['mission'];

        // Hide tracker if mission is completed, cancelled, or has ended
        if (mission != null) {
          final missionStatus = mission['status'];
          final missionEndTime = mission['endTime'] != null
              ? DateTime.parse(mission['endTime'])
              : null;
          final now = DateTime.now();

          if (missionStatus == 'Completed' ||
              missionStatus == 'Cancelled' ||
              (missionStatus != 'InProgress' &&
                  missionEndTime != null &&
                  missionEndTime.isBefore(now))) {
            return const SizedBox.shrink();
          }
        }

        final missionTitle = mission?['title'] ?? 'Mission';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: EcoPulseCard(
            variant: CardVariant.paper,
            padding: const EdgeInsets.all(20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleInteraction,
                onPanDown: (_) => _handleInteraction(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.clay,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.record_voice_over_outlined,
                            color: AppTheme.forest,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE SESSION',
                                style: EcoText.monoSM(context).copyWith(
                                  color: AppTheme.ink.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  _handleInteraction();
                                  if (mission != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MissionDetailScreen(
                                              mission: Mission.fromJson(
                                                mission,
                                              ),
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  missionTitle,
                                  style: EcoText.displayMD(context).copyWith(
                                    fontSize: 18,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.forest
                                        .withValues(alpha: 0.3),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!_isCollapsed &&
                                  mission?['locationName'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  mission?['locationName'],
                                  style: EcoText.bodySM(context).copyWith(
                                    color: AppTheme.ink.withValues(alpha: 0.4),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_isCollapsed &&
                            mission?['creator']?['email'] != null) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.contact_mail_outlined,
                              size: 20,
                            ),
                            color: AppTheme.forest.withValues(alpha: 0.7),
                            tooltip: 'Contact Coordinator',
                            onPressed: () async {
                              _handleInteraction();
                              final email = mission!['creator']['email'];
                              final uri = Uri.parse(
                                'mailto:$email?subject=Question regarding ${mission['title']}',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          EcoFormatters.formatTimerDuration(_elapsed),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forest,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (!_isCollapsed) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: EcoPulseButton(
                          isLoading: _isCheckingOut,
                          onPressed: _isCheckingOut
                              ? null
                              : () async {
                                  _handleInteraction();
                                  setState(() => _isCheckingOut = true);
                                  try {
                                    await attendanceProvider.checkOut(
                                      attendance['missionId'],
                                    );
                                    if (context.mounted) {
                                      final points =
                                          mission?['pointsValue'] ?? 100;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MissionSuccessSummaryScreen(
                                                missionTitle: missionTitle,
                                                duration: _elapsed,
                                                pointsEarned: points,
                                              ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: AppTheme.terracotta,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isCheckingOut = false);
                                    }
                                  }
                                },
                          label: 'COMPLETE MISSION',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

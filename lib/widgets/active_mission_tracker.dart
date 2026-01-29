import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/eco_pulse_widgets.dart';

class ActiveMissionTracker extends StatefulWidget {
  const ActiveMissionTracker({super.key});

  @override
  State<ActiveMissionTracker> createState() => _ActiveMissionTrackerState();
}

class _ActiveMissionTrackerState extends State<ActiveMissionTracker> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final attendance = attendanceProvider.currentAttendance;

        if (attendance == null) return const SizedBox.shrink();

        final mission = attendance['mission'];
        final missionTitle = mission?['title'] ?? 'Mission';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: EcoPulseCard(
            variant: CardVariant.hero, // Using hero variant for high visibility
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.record_voice_over,
                        color: Colors.white,
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
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            missionTitle,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: EcoColors.violet,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await attendanceProvider.checkOut(
                          attendance['missionId'],
                        );
                        if (context.mounted) {
                          // TODO: Implement MissionSuccessSummary screen showing hours worked and pending points
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mission Complete. Logging out.'),
                              backgroundColor: EcoColors.forest,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text('COMPLETE MISSION'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

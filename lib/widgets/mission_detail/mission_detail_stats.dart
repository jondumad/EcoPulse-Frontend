import 'package:flutter/material.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';

/// Horizontal row of four key mission stats: Points, Duration, Spots, Priority.
class MissionDetailStats extends StatelessWidget {
  final Mission mission;

  const MissionDetailStats({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final duration = mission.endTime.toLocal().difference(
      mission.startTime.toLocal(),
    );
    final hours = duration.inHours;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('POINTS', '${mission.pointsValue}', Icons.star_border),
          _buildStatItem('DURATION', '$hours hrs', Icons.access_time),
          _buildStatItem(
            'SPOTS',
            '${mission.maxVolunteers != null ? mission.maxVolunteers! - mission.currentVolunteers : "Open"}',
            Icons.people_outline,
          ),
          _buildStatItem('PRIORITY', mission.priority, Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.forest, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.ink.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

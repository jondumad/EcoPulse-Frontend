import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../screens/volunteer/mission_detail_screen.dart';
import '../widgets/eco_pulse_widgets.dart';

class MissionList extends StatelessWidget {
  final List<Mission> missions;
  final bool isHistory;

  const MissionList({
    super.key,
    required this.missions,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: missions.map((mission) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MissionListItem(mission: mission, isHistory: isHistory),
        );
      }).toList(),
    );
  }
}

class _MissionListItem extends StatelessWidget {
  final Mission mission;
  final bool isHistory;

  const _MissionListItem({required this.mission, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailScreen(mission: mission),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isHistory
                    ? EcoColors.ink.withValues(alpha: 0.05)
                    : EcoColors.forest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  mission.categories.isNotEmpty
                      ? mission.categories.first.icon
                      : '🌱',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isHistory
                          ? EcoColors.ink.withValues(alpha: 0.7)
                          : EcoColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10,
                        color: EcoColors.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(mission.startTime),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          height: 1.1,
                          color: EcoColors.ink.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status/Action
            if (!isHistory) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: EcoColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: EcoColors.forest,
                  ),
                ),
              ),
            ] else ...[
              if (mission.registrationStatus == 'Cancelled')
                const Icon(
                  Icons.cancel_outlined,
                  color: EcoColors.terracotta,
                  size: 18,
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: EcoColors.forest,
                  size: 18,
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, can use intl but basic is fine to avoid deps if not avail
    return '${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

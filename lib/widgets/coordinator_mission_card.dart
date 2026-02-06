import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/mission_model.dart';
import 'eco_pulse_widgets.dart';

class CoordinatorMissionCard extends StatefulWidget {
  final Mission mission;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onVolunteerTap;

  const CoordinatorMissionCard({
    super.key,
    required this.mission,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onVolunteerTap,
  });

  @override
  State<CoordinatorMissionCard> createState() => _CoordinatorMissionCardState();
}

class _CoordinatorMissionCardState extends State<CoordinatorMissionCard> {
  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final isSelected = widget.isSelected;
    final isSelectionMode = widget.isSelectionMode;

    // Use EcoPulseCard pattern
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: EcoColors.forest, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: Stack(
          children: [
            EcoPulseCard(
              onTap: widget.onTap,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mission Icon/Type Indicator (could be dynamic based on type)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: EcoColors.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.forest_outlined,
                          color: EcoColors.forest,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: EcoText.bodyBoldMD(
                                context,
                              ).copyWith(fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Date
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: EcoColors.ink.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(mission.startTime),
                                  style: EcoText.bodySM(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: EcoColors.ink.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    mission.locationName,
                                    style: EcoText.bodySM(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (mission.isEmergency)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: EcoPulseTag(label: 'URGENT', isRotated: false),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  // Footer: Stats & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Volunteer Count / Fill Rate
                      InkWell(
                        onTap: widget.onVolunteerTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 16,
                                color: EcoColors.ink.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${mission.currentVolunteers}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        color: EcoColors.ink,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/${mission.maxVolunteers}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        color: EcoColors.ink.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            mission.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mission.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(mission.status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelectionMode)
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: EcoColors.forest,
                      size: 28,
                    ),
                  ),
                ),
              ),
            // Unselected radio circle hint if desired, or just rely on border
            if (isSelectionMode && !isSelected)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EcoColors.ink.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return EcoColors.forest;
      case 'inprogress':
        return EcoColors.violet;
      case 'completed':
        return EcoColors.ink;
      case 'cancelled':
        return EcoColors.terracotta;
      default:
        return EcoColors.ink.withValues(alpha: 0.5);
    }
  }
}

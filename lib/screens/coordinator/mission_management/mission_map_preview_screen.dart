import 'package:flutter/material.dart';
import '../../../models/mission_model.dart';
import '../../volunteer/mission_map.dart';
import '../../../widgets/eco_pulse_widgets.dart';
import '../../../widgets/atoms/eco_card.dart';
import '../../../theme/app_theme.dart';

class MissionMapPreviewScreen extends StatelessWidget {
  final Mission mission;

  const MissionMapPreviewScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.ink,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MissionMap(
            selectedMission: mission,
            centerOnMission: true,
            missionsOverride: [mission],
          ),

          // Floating Mission Info Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: EcoPulseCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mission.categories.firstOrNull?.icon ?? '📍',
                          style: const TextStyle(fontSize: 20),
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
                              ).copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mission.locationName,
                              style: EcoText.bodySM(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeta(
                          context,
                          Icons.gps_fixed_rounded,
                          'Coordinates',
                          mission.locationGps ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppTheme.forest.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 10,
                              color: AppTheme.forest,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'MEETING POINT',
                              style: EcoText.monoSM(context).copyWith(
                                color: AppTheme.forest,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.ink.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: EcoText.monoSM(
                  context,
                ).copyWith(fontSize: 8, letterSpacing: 0.5),
              ),
              Text(
                value,
                style: EcoText.bodyBoldMD(context).copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

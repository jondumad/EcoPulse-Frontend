import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';
import '../../models/mission_model.dart';
import '../../components/mission_list.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';

class MissionHistoryScreen extends StatelessWidget {
  final List<Mission> missions;

  const MissionHistoryScreen({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.clay,
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mission History',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      body: missions.isEmpty
          ? Center(
              child: Text(
                'No mission history found',
                style: EcoText.bodyMD(
                  context,
                ).copyWith(color: EcoColors.ink.withValues(alpha: 0.5)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: MissionList(missions: missions, isHistory: true),
            ),
    );
  }
}

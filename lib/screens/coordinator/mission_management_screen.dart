import 'package:flutter/material.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_management/collaboration_tab.dart';
import 'mission_management/logistics_tab.dart';
import 'mission_management/overview_tab.dart';
import 'mission_management/volunteers_tab.dart';

class MissionManagementScreen extends StatefulWidget {
  final Mission mission;

  const MissionManagementScreen({super.key, required this.mission});

  @override
  State<MissionManagementScreen> createState() =>
      _MissionManagementScreenState();
}

class _MissionManagementScreenState extends State<MissionManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: EcoPulseLayout(
        appBar: EcoAppBar(
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MISSION HUB',
                style: EcoText.monoSM(context).copyWith(
                  color: EcoColors.ink.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.mission.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EcoText.displayMD(context).copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: EcoColors.clay,
                border: Border(
                  bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 1),
                ),
              ),
              child: TabBar(
                isScrollable: true,
                indicatorColor: EcoColors.forest,
                labelColor: EcoColors.forest,
                unselectedLabelColor: EcoColors.ink.withValues(alpha: 0.4),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'VOLUNTEERS'),
                  Tab(text: 'COLLABORATION'),
                  Tab(text: 'LOGISTICS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OverviewTab(mission: widget.mission),
                  VolunteersTab(mission: widget.mission),
                  CollaborationTab(mission: widget.mission),
                  LogisticsTab(mission: widget.mission),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

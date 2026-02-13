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
          height: 140,
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MISSION HUB', style: EcoText.monoSM(context)),
              const SizedBox(height: 4),
              Text(
                widget.mission.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EcoText.displayMD(context),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: EcoColors.forest,
            labelColor: EcoColors.forest,
            unselectedLabelColor: Colors.black38,
            tabs: [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'VOLUNTEERS'),
              Tab(text: 'COLLABORATION'),
              Tab(text: 'LOGISTICS'),
            ],
          ),
        ),
        child: TabBarView(
          children: [
            OverviewTab(mission: widget.mission),
            VolunteersTab(mission: widget.mission),
            CollaborationTab(mission: widget.mission),
            LogisticsTab(mission: widget.mission),
          ],
        ),
      ),
    );
  }
}

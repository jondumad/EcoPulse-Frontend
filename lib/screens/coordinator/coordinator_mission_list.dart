import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'qr_display.dart';
import 'mission_management_screen.dart';

class CoordinatorMissionListScreen extends StatefulWidget {
  const CoordinatorMissionListScreen({super.key});

  @override
  State<CoordinatorMissionListScreen> createState() =>
      _CoordinatorMissionListScreenState();
}

class _CoordinatorMissionListScreenState
    extends State<CoordinatorMissionListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: Consumer<MissionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final missions = provider.missions;

          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Management Overview Card
                  _buildOverview(missions),

                  // VISUAL DIVIDER
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.ink.withValues(alpha: 0.1),
                    ),
                  ),

                  if (missions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          'No missions found.',
                          style: AppTheme.lightTheme.textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.5),
                              ),
                        ),
                      ),
                    )
                  else
                    ...missions.map((mission) {
                      return Padding(
                        key: ValueKey('mission_${mission.id}'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CoordinatorMissionCard(mission: mission),
                      );
                    }),

                  const SizedBox(height: 100), // Bottom nav padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(List<Mission> missions) {
    final activeCount = missions
        .where((m) => m.status == 'Open' || m.status == 'InProgress')
        .length;
    final criticalCount = missions.where((m) => m.isEmergency).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'COORDINATOR OVERVIEW',
            style: AppTheme.lightTheme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OverviewStat(
                label: 'ACTIVE',
                value: activeCount.toString(),
                color: AppTheme.forest,
              ),
              const SizedBox(width: 40),
              _OverviewStat(
                label: 'CRITICAL',
                value: criticalCount.toString(),
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 40),
              _OverviewStat(
                label: 'TOTAL',
                value: missions.length.toString(),
                color: AppTheme.ink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
            color: color,
            height: 1,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: AppTheme.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _CoordinatorMissionCard extends StatelessWidget {
  final Mission mission;

  const _CoordinatorMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final isUrgent = mission.isEmergency;
    final volunteerProgress =
        (mission.maxVolunteers != null && mission.maxVolunteers! > 0)
        ? mission.currentVolunteers / mission.maxVolunteers!
        : 0.1;

    return EcoPulseCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (isUrgent)
            Positioned(
              left: 0,
              top: 20,
              bottom: 20,
              width: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.terracotta,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.clay,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          mission.categories.isNotEmpty
                              ? mission.categories.first.icon
                              : '📋',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: AppTheme.lightTheme.textTheme.headlineMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // --- FIXED SECTION ---
                          Row(
                            children: [
                              Expanded(
                                child: _MetaItem(
                                  icon: Icons.location_on_outlined,
                                  label: mission.locationName,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetaItem(
                                  icon: Icons.access_time,
                                  label: DateFormat(
                                    'MMM dd, HH:mm',
                                  ).format(mission.startTime),
                                ),
                              ),
                            ],
                          ),
                          // ---------------------
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VOLUNTEERS',
                          style: AppTheme.lightTheme.textTheme.labelLarge,
                        ),
                        Text(
                          '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(color: AppTheme.forest),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.clay,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: volunteerProgress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.forest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: EcoPulseButton(
                        label: 'Manage',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MissionManagementScreen(mission: mission),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QRDisplayScreen(
                                missionId: mission.id,
                                missionTitle: mission.title,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.clay,
                          foregroundColor: AppTheme.ink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color.fromRGBO(0, 0, 0, 0.06),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Constrain row to its children
      children: [
        Icon(icon, size: 12, color: AppTheme.ink.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

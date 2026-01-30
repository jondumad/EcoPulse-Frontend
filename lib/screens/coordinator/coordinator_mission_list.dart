import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/paper_card.dart';
import 'qr_display.dart'; // Ensure this import is correct based on folder structure

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
      // Fetch all missions. In a real app, this might be a specific endpoint for coordinator's managed missions.
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: AppBar(
        title: Text(
          'MISSION HUB',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontFamily: 'JetBrains Mono',
            letterSpacing: 2,
            color: AppTheme.ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<MissionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final missions = provider.missions; // Displaying all fetched missions

          if (missions.isEmpty) {
            return Center(
              child: Text(
                'No missions found.',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.5),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              return _CoordinatorMissionCard(mission: missions[index]);
            },
          );
        },
      ),
    );
  }
}

class _CoordinatorMissionCard extends StatelessWidget {
  final Mission mission;

  const _CoordinatorMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      child: Padding(
        padding: const EdgeInsets.all(
          4.0,
        ), // PaperCard has its own padding usually, but adding a bit if needed or relying on child
        // Actually PaperCard doesn't enforce padding on child, so let's check PaperCard usage.
        // Assuming PaperCard wraps content nicely.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(mission.startTime),
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.6),
                              fontFamily: 'JetBrains Mono',
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: mission.isEmergency
                        ? AppTheme.terracotta.withValues(alpha: 0.1)
                        : AppTheme.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: mission.isEmergency
                          ? AppTheme.terracotta.withValues(alpha: 0.5)
                          : AppTheme.forest.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    mission.status.toUpperCase(),
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: mission.isEmergency
                          ? AppTheme.terracotta
                          : AppTheme.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'VOLUNTEERS',
                        value:
                            '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
                      ),
                      const SizedBox(height: 8),
                      _StatRow(label: 'LOCATION', value: mission.locationName),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.qr_code, size: 20),
                    label: const Text('QR CODE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.ink.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

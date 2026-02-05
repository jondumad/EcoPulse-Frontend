import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mission_model.dart';
import '../providers/mission_provider.dart';
import '../providers/location_provider.dart';

import '../theme/app_theme.dart';
import '../screens/volunteer/mission_detail_screen.dart';
import '../widgets/eco_pulse_widgets.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;

  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final bool isEmergency =
        mission.isEmergency ||
        mission.priority == 'Critical' ||
        mission.priority == 'High';
    final double progress = mission.maxVolunteers != null
        ? mission.currentVolunteers / mission.maxVolunteers!
        : 0.1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        EcoPulseCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MissionDetailScreen(mission: mission),
              ),
            );
          },
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
                            : '🌱',
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
                        Row(
                          children: [
                            Consumer<LocationProvider>(
                              builder: (context, locationProvider, _) {
                                return _MetaItem(
                                  icon: Icons.location_on_outlined,
                                  label: locationProvider.getDistanceLabel(
                                    mission.locationGps,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _MetaItem(
                              icon: Icons.access_time,
                              label: _formatTimeLeft(
                                mission.startTime.toLocal(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESS',
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTheme.lightTheme.textTheme.displaySmall
                            ?.copyWith(fontSize: 18, color: AppTheme.forest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.clay,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.forest, Color(0xFF2D6A4F)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Consumer<MissionProvider>(
                      builder: (context, provider, _) {
                        return EcoPulseButton(
                          label: mission.isRegistered ? 'Continue' : 'Start',
                          icon: Icons.play_arrow_rounded,
                          isLoading: provider.isLoading,
                          onPressed: () async {
                            if (mission.isRegistered) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MissionDetailScreen(mission: mission),
                                ),
                              );
                            } else {
                              try {
                                await provider.toggleRegistration(
                                  mission.id,
                                  false,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully registered!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EcoPulseButton(
                      label: '',
                      icon: Icons.map_outlined,
                      isPrimary: false,
                      onPressed: () async {
                        if (mission.locationGps != null &&
                            mission.locationGps!.contains(',')) {
                          final coords = mission.locationGps!.split(',');
                          final lat = coords[0].trim();
                          final lng = coords[1].trim();
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not launch map'),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isEmergency)
          Positioned(
            left: 0,
            top: 24,
            bottom: 24,
            width: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.terracotta,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),
        if (mission.isRegistered)
          Positioned(
            top: -6,
            right: -6,
            child: EcoPulseTag(
              label: mission.registrationStatus ?? 'Registered',
              isRotated: true,
            ),
          ),
      ],
    );
  }

  String _formatTimeLeft(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.ink.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.lightTheme.textTheme.bodySmall),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';

class MissionDetailScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Image/Color block
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    mission.categories.isNotEmpty
                        ? _getIconForCategory(mission.categories.first.name)
                        : Icons.volunteer_activism,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title and Tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    Text(
                      '+${mission.pointsValue}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: mission.categories
                      .map((cat) => _CategoryBadge(category: cat))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Key Info Card
                EcoPulseCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date & Time',
                        subtitle: DateFormat(
                          'EEEE, MMM dd • HH:mm',
                        ).format(mission.startTime),
                      ),
                      const Divider(height: 32),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        subtitle: mission.locationName,
                      ),
                      const Divider(height: 32),
                      _InfoRow(
                        icon: Icons.people_outline,
                        title: 'Availability',
                        subtitle:
                            '${mission.currentVolunteers} / ${mission.maxVolunteers ?? "∞"} spots filled',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  mission.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 100), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Consumer<MissionProvider>(
          builder: (context, provider, _) {
            final isFull =
                mission.maxVolunteers != null &&
                mission.currentVolunteers >= mission.maxVolunteers!;

            return EcoPulseButton(
              label: mission.isRegistered
                  ? 'Cancel Registration'
                  : (isFull ? 'Mission Full' : 'Register Now'),
              isPrimary: !mission.isRegistered,
              onPressed: isFull && !mission.isRegistered
                  ? () {} // Disabled
                  : () async {
                      try {
                        await provider.toggleRegistration(
                          mission.id,
                          mission.isRegistered,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                mission.isRegistered
                                    ? 'Registration cancelled'
                                    : 'Successfully registered!',
                              ),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                          Navigator.pop(context); // Go back to list
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name) {
      case 'Environmental':
        return Icons.eco;
      case 'Social':
        return Icons.people;
      case 'Educational':
        return Icons.school;
      case 'Health':
        return Icons.medical_services;
      default:
        return Icons.volunteer_activism;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final Category category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final Color color = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon),
          const SizedBox(width: 6),
          Text(
            category.name,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

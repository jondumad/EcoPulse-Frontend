import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class VolunteerBottomSheet extends StatefulWidget {
  final int missionId;
  final String missionTitle;
  final int? maxVolunteers;

  const VolunteerBottomSheet({
    super.key,
    required this.missionId,
    required this.missionTitle,
    this.maxVolunteers,
  });

  @override
  State<VolunteerBottomSheet> createState() => _VolunteerBottomSheetState();
}

class _VolunteerBottomSheetState extends State<VolunteerBottomSheet> {
  late Future<List<Map<String, dynamic>>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _registrationsFuture = Provider.of<MissionProvider>(
      context,
      listen: false,
    ).fetchRegistrations(widget.missionId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteers',
                        style: AppTheme.lightTheme.textTheme.headlineSmall,
                      ),
                      Text(
                        widget.missionTitle,
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.5),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                EcoPulseButton(
                  label: 'Invite',
                  onPressed: () {
                    // TODO: Implement invite flow (e.g. share link)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite feature coming soon!'),
                      ),
                    );
                  },
                  isSmall: true,
                  backgroundColor: AppTheme.clay,
                  foregroundColor: AppTheme.ink,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _registrationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final volunteers = snapshot.data ?? [];

                if (volunteers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text('No volunteers yet'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: volunteers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final vol = volunteers[index];
                    // Accessing user data safely
                    final user = vol['user'] ?? {};
                    final name = user['name'] ?? 'Unknown Volunteer';
                    final status = vol['status'] ?? 'Registered';
                    final email = user['email'];

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.clay,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.ink),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTheme.lightTheme.textTheme.bodyLarge,
                              ),
                              if (email != null)
                                Text(
                                  email,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
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
                            color: status == 'CheckedIn'
                                ? AppTheme.forest.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: status == 'CheckedIn'
                                  ? AppTheme.forest
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.message_outlined, size: 20),
                          onPressed: () {
                            // TODO: Implement contact
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message feature coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

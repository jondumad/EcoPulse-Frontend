import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/mission_provider.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class VolunteerListModal extends StatefulWidget {
  final int missionId;
  final String missionTitle;
  final int? maxVolunteers;

  const VolunteerListModal({
    super.key,
    required this.missionId,
    required this.missionTitle,
    this.maxVolunteers,
  });

  static Future<void> show(
    BuildContext context, {
    required int missionId,
    required String missionTitle,
    int? maxVolunteers,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VolunteerListModal(
        missionId: missionId,
        missionTitle: missionTitle,
        maxVolunteers: maxVolunteers,
      ),
    );
  }

  @override
  State<VolunteerListModal> createState() => _VolunteerListModalState();
}

class _VolunteerListModalState extends State<VolunteerListModal> {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: EcoColors.clay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EcoColors.ink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missions Squad',
                          style: GoogleFonts.fraunces(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: EcoColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.missionTitle.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: EcoColors.ink.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  EcoPulseButton(
                    label: 'INVITE',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite feature coming soon!'),
                        ),
                      );
                    },
                    isSmall: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _registrationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.terracotta),
                        ),
                      ),
                    );
                  }

                  final volunteers = snapshot.data ?? [];

                  if (volunteers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 64,
                            color: EcoColors.ink.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No volunteers joined yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: EcoColors.ink.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: volunteers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vol = volunteers[index];
                      final user = vol['user'] ?? {};
                      final name = user['name'] ?? 'Anonymous';
                      final status = vol['status'] ?? 'Registered';
                      final email = user['email'] ?? 'No email provided';

                      final isCheckedIn = status == 'CheckedIn';

                      return EcoPulseCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isCheckedIn
                                    ? EcoColors.forest.withValues(alpha: 0.1)
                                    : EcoColors.clay,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: GoogleFonts.fraunces(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isCheckedIn
                                        ? EcoColors.forest
                                        : EcoColors.ink,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: EcoColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: EcoColors.ink.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(status: status),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 20,
                                color: EcoColors.ink,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Message feature coming soon!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = status == 'CheckedIn';
    final color = isCheckedIn ? EcoColors.forest : EcoColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

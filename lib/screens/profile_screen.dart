import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/mission_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final now = DateTime.now();
    return EcoPulseLayout(
      child: Consumer2<AuthProvider, MissionProvider>(
        builder: (context, auth, missionProvider, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final activeMissions = missionProvider.missions
              .where((m) => m.isRegistered && m.registrationStatus != 'Completed')
              .toList();

          final completedMissions = missionProvider.missions
              .where((m) => m.registrationStatus == 'Completed')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Date & Greeting)
                Text(
                  DateFormat('MMM dd, yyyy').format(now).toUpperCase(),
                  style: EcoText.monoSM(context),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello,\n${user.name.split(' ').first}',
                        style: EcoText.displayLG(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_outlined,
                        color: EcoColors.ink,
                      ),
                      onPressed: () {
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                      },
                      tooltip: 'Logout',
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: EcoColors.forest,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Hero Card (Profile & Role)
                EcoPulseCard(
                  variant: CardVariant.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.fingerprint, color: Colors.white54),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Volunteer Stats & Gamification
                if (user.role == 'Volunteer') ...[
                  Text('Field Statistics', style: EcoText.displayMD(context)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: EcoPulseCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL POINTS',
                                style: EcoText.monoSM(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${user.totalPoints}',
                                style: EcoText.displayMD(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: EcoPulseCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RANK', style: EcoText.monoSM(context)),
                              const SizedBox(height: 8),
                              Text(
                                _calculateLevel(user.totalPoints),
                                style: EcoText.displayMD(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress
                  EcoPulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NEXT MILESTONE',
                              style: EcoText.monoSM(context),
                            ),
                            Text(
                              '${user.totalPoints} / 1000',
                              style: EcoText.monoSM(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: user.totalPoints / 1000,
                            minHeight: 8,
                            backgroundColor: EcoColors.clay,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              EcoColors.forest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Earn ${1000 - user.totalPoints} more points to reach Community Hero status.',
                          style: EcoText.bodyMD(context).copyWith(
                            color: EcoColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registered Missions Section
                  Text(
                    'My Active Missions',
                    style: EcoText.displayMD(context),
                  ),
                  const SizedBox(height: 16),
                  if (missionProvider.isLoading && activeMissions.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (activeMissions.isEmpty)
                    _buildEmptyState(
                      'No active missions.\nStart your journey in the missions tab!',
                    )
                  else
                    ...activeMissions.map(
                      (mission) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MissionCard(mission: mission),
                      ),
                    ),

                  if (completedMissions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('Mission History', style: EcoText.displayMD(context)),
                    const SizedBox(height: 16),
                    ...completedMissions.map(
                      (mission) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MissionCard(mission: mission),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 100), // Spacing for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return EcoPulseCard(
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: EcoColors.ink.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EcoText.bodyMD(
              context,
            ).copyWith(color: EcoColors.ink.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  String _calculateLevel(int points) {
    if (points < 100) return 'Newbie';
    if (points < 500) return 'Active';
    if (points < 1000) return 'Hero';
    return 'Legend';
  }
}

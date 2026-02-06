import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/mission_list.dart';
import '../components/hero_card.dart';
import './volunteer/mission_history_screen.dart';
import 'volunteer/badges_modal.dart';

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
      Provider.of<AuthProvider>(context, listen: false).fetchUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      child: Consumer2<AuthProvider, MissionProvider>(
        builder: (context, auth, missionProvider, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final activeMissions = missionProvider.missions
              .where(
                (m) => m.isRegistered && m.registrationStatus != 'Completed',
              )
              .toList();

          final historyMissions = missionProvider.missions
              .where(
                (m) =>
                    m.registrationStatus == 'Completed' ||
                    m.registrationStatus == 'Cancelled',
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Hero Card (Profile & Role)
                HeroCard(user: user),
                const SizedBox(height: 32),

                // Weekly Impact Chart
                if (user.role == 'Volunteer') ...[
                  _buildWeeklyImpact(context),
                  const SizedBox(height: 32),
                ],

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
                  GestureDetector(
                    onTap: () => BadgesModal.show(context),
                    child: EcoPulseCard(
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
                              GestureDetector(
                                onTap: () => BadgesModal.show(context),
                                child: Row(
                                  children: [
                                    Text(
                                      'SEE ALL',
                                      style: EcoText.bodyBoldMD(context)
                                          .copyWith(
                                            color: EcoColors.violet,
                                            fontSize: 11,
                                            letterSpacing: 1,
                                          ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: EcoColors.violet,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level Progress',
                                style: EcoText.bodyMD(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${user.totalPoints} / 1000 XP',
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
                  ),
                  const SizedBox(height: 32),

                  // Registered Missions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Active Missions',
                        style: EcoText.displayMD(context),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MissionHistoryScreen(
                                missions: historyMissions,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See History',
                          style: EcoText.bodyBoldMD(
                            context,
                          ).copyWith(color: EcoColors.forest, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (missionProvider.isLoading && activeMissions.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (activeMissions.isEmpty)
                    _buildEmptyState(
                      'No active missions.\nStart your journey in the missions tab!',
                    )
                  else
                    MissionList(missions: activeMissions),

                  if (historyMissions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('Mission History', style: EcoText.displayMD(context)),
                    const SizedBox(height: 16),
                    MissionList(
                      missions: historyMissions
                          .take(3)
                          .toList(), // Show preview
                      isHistory: true,
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

  Widget _buildWeeklyImpact(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final stats = auth.userStats;

    final actionsCompleted = stats?['actionsCompleted']?.toString() ?? '0';
    final rank = stats?['rank']?.toString() ?? '-';
    final totalVolunteers = stats?['totalVolunteers']?.toString() ?? '-';
    final weeklyActivity = (stats?['weeklyActivity'] as List?) ?? [];

    return EcoPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEKLY IMPACT', style: EcoText.monoSM(context)),
          const SizedBox(height: 8),
          Text(
            actionsCompleted,
            style: EcoText.displayXL(
              context,
            ).copyWith(fontSize: 56, color: EcoColors.forest),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Actions Completed · Rank #$rank of $totalVolunteers',
            style: EcoText.bodyMD(
              context,
            ).copyWith(color: EcoColors.ink.withValues(alpha: 0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color.fromRGBO(0, 0, 0, 0.06)),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxActivity = weeklyActivity.isEmpty
                    ? 1.0
                    : weeklyActivity
                          .map(
                            (dayData) => (dayData['value'] as num).toDouble(),
                          )
                          .fold(0.0, (prev, curr) => math.max(prev, curr));

                final scaleFactor = maxActivity > 0 ? maxActivity : 100.0;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weeklyActivity.isEmpty
                      ? [
                          _buildDayBar(context, 'M', 0, 100),
                          _buildDayBar(context, 'T', 0, 100),
                          _buildDayBar(context, 'W', 0, 100),
                          _buildDayBar(context, 'T', 0, 100),
                          _buildDayBar(context, 'F', 0, 100),
                          _buildDayBar(context, 'S', 0, 100),
                          _buildDayBar(context, 'S', 0, 100),
                        ]
                      : weeklyActivity.map((dayData) {
                          return _buildDayBar(
                            context,
                            dayData['day'],
                            (dayData['value'] as num).toDouble(),
                            scaleFactor,
                            isToday: dayData['isToday'] ?? false,
                            isActive: (dayData['value'] as num) > 0,
                          );
                        }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(
    BuildContext context,
    String day,
    double value,
    double maxValue, {
    bool isActive = false,
    bool isToday = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: math.max(
                4.0,
                (value / maxValue) * 40,
              ), // Scale factor with min height
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: isToday
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [EcoColors.terracotta, Color(0xFFC25A47)],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isActive ? EcoColors.forest : EcoColors.clay,
                          isActive ? const Color(0xFF2D6A4F) : EcoColors.clay,
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(day, style: EcoText.monoSM(context).copyWith(fontSize: 9)),
          ],
        ),
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

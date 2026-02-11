import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../models/user_model.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/mission_list.dart';
import './volunteer/mission_history_screen.dart';
import 'volunteer/badges_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
                // Premium Modular Profile Header
                _ProfileHero(user: user),
                const SizedBox(height: 32),

                // Weekly Impact Chart
                _buildWeeklyImpact(context),
                const SizedBox(height: 32),

                // Role-Specific Sections
                if (user.role == 'Volunteer') ...[
                  Text('Field Statistics', style: EcoText.displayMD(context)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'TOTAL IMPACT',
                          value: '${user.totalPoints}',
                          icon: Icons.bolt_rounded,
                          color: AppTheme.forest,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatTile(
                          label: 'FIELD RANK',
                          value: _calculateLevel(user.totalPoints),
                          icon: Icons.shield_rounded,
                          color: AppTheme.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Section Refined
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
                                'CERTIFICATION PROGRESS',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink.withValues(alpha: 0.4),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.forest.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LVL ${user.totalPoints ~/ 500 + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Next Milestone',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                '${user.totalPoints % 500} / 500 PTS',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.forest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.clay,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (user.totalPoints % 500) / 500,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.forest,
                                        Color(0xFF2D6A4F), // Darker forest
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppTheme.ink.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Earn ${500 - (user.totalPoints % 500)} more points to unlock the next community badge.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.ink.withValues(alpha: 0.5),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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
                ] else if (user.role == 'Coordinator') ...[
                  Text(
                    'Coordination Metrics',
                    style: EcoText.displayMD(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'MISSIONS MANAGED',
                          value: '${auth.userStats?['missionsManaged'] ?? 0}',
                          icon: Icons.assignment_rounded,
                          color: AppTheme.violet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatTile(
                          label: 'VOLUNTEERS VERIFIED',
                          value:
                              '${auth.userStats?['totalVerifications'] ?? 0}',
                          icon: Icons.verified_user_rounded,
                          color: AppTheme.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Managed Missions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Missions I Manage',
                        style: EcoText.displayMD(context),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<MissionProvider>(
                            context,
                            listen: false,
                          ).fetchMissions(forceRefresh: true);
                        },
                        child: Text(
                          'Refresh List',
                          style: EcoText.bodyBoldMD(
                            context,
                          ).copyWith(color: EcoColors.forest, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (missionProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (missionProvider.missions
                      .where((m) => m.createdBy == user.id)
                      .isEmpty)
                    _buildEmptyState(
                      'You haven\'t created any missions yet.\nHead to the Mission Hub to start one!',
                    )
                  else
                    MissionList(
                      missions: missionProvider.missions
                          .where((m) => m.createdBy == user.id)
                          .toList(),
                    ),
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

    final weeklyActivity = (stats?['weeklyActivity'] as List?) ?? [];
    final isCoordinator = stats?['role'] == 'Coordinator';
    final rank = stats?['rank']?.toString() ?? '-';
    final totalVolunteers = stats?['totalVolunteers']?.toString() ?? '-';

    return EcoPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCoordinator ? 'WEEKLY CO-ORDINATION' : 'WEEKLY IMPACT',
            style: EcoText.monoSM(context),
          ),
          const SizedBox(height: 8),
          Text(
            isCoordinator
                ? (stats?['totalVerifications']?.toString() ?? '0')
                : (stats?['actionsCompleted']?.toString() ?? '0'),
            style: EcoText.displayXL(
              context,
            ).copyWith(fontSize: 56, color: EcoColors.forest),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isCoordinator
                ? 'Volunteers Verified'
                : 'Actions Completed · Rank #$rank of $totalVolunteers',
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
    if (points < 100) return 'NOVICE';
    if (points < 500) return 'ACTIVE';
    if (points < 1000) return 'HERO';
    return 'LEGEND';
  }
}

class _ProfileHero extends StatelessWidget {
  final User user;

  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.1),
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    "https://api.dicebear.com/7.x/avataaars/png?seed=${user.name}",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.forest,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.ink.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.borderSubtle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroMetaItem(
                label: "MEMBER SINCE",
                value: user.createdAt != null
                    ? "${user.createdAt!.year}"
                    : "${DateTime.now().year}",
                icon: Icons.calendar_today_rounded,
                color: AppTheme.ink,
              ),
              _HeroMetaItem(
                label: "STATUS",
                value: "VERIFIED",
                icon: Icons.verified_user_rounded,
                color: AppTheme.forest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _HeroMetaItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color ?? AppTheme.ink.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EcoPulseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

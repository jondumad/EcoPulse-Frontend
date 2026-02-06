import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/user_model.dart';

class BadgesModal extends StatefulWidget {
  const BadgesModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BadgesModal(),
    );
  }

  @override
  State<BadgesModal> createState() => _BadgesModalState();
}

class _BadgesModalState extends State<BadgesModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().fetchAllBadges();
      context.read<AuthProvider>().refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final badgeProvider = context.watch<BadgeProvider>();

    final user = auth.user;
    final totalPoints = user?.totalPoints ?? 0;

    // Level calculation (500 pts per level)
    final currentLevel = (totalPoints / 500).floor() + 1;
    final pointsInCurrentLevel = totalPoints % 500;
    final progressToNextLevel = pointsInCurrentLevel / 500;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: EcoColors.clay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EcoColors.ink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: EcoColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep it up, you\'re doing great!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: EcoColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Level Progress Card
                    _buildProgressCard(
                      context,
                      currentLevel,
                      progressToNextLevel.toDouble(),
                      pointsInCurrentLevel,
                    ),
                    const SizedBox(height: 32),

                    // Stats Row
                    const EcoSectionHeader(title: 'FIELD STATISTICS'),
                    const SizedBox(height: 16),
                    _buildStatsGrid(context, auth),
                    const SizedBox(height: 40),

                    // Badges Section
                    const EcoSectionHeader(title: 'MILESTONE BADGES'),
                    const SizedBox(height: 16),
                    if (badgeProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildBadgeGrid(
                        context,
                        badgeProvider.allBadges,
                        user?.userBadges ?? [],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    int level,
    double progress,
    int points,
  ) {
    return EcoPulseCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL $level',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: EcoColors.violet,
                    ),
                  ),
                  Text(
                    _getLevelTitle(level),
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: EcoColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EcoColors.violet.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: EcoColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: EcoColors.clay,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.05, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [EcoColors.violet, Color(0xFFA370FF)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: EcoColors.violet.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points / 500 XP',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EcoColors.ink.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: EcoColors.violet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AuthProvider auth) {
    final stats = auth.userStats;
    final points = auth.user?.totalPoints ?? 0;
    final missions = stats?['actionsCompleted'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: EcoPulseCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: EcoStatItem(
              label: 'Points',
              value: '$points',
              color: AppTheme.terracotta,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EcoPulseCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: EcoStatItem(
              label: 'Missions',
              value: '$missions',
              color: AppTheme.forest,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EcoPulseCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: EcoStatItem(
              label: 'Impact',
              value: '${(points * 1.5).toInt()}',
              color: EcoColors.violet,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid(
    BuildContext context,
    List<BadgeInfo> allBadges,
    List<UserBadge> earnedBadges,
  ) {
    if (allBadges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No badges available yet.',
            style: GoogleFonts.inter(
              color: EcoColors.ink.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.75,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final bool unlocked = earnedBadges.any((eb) => eb.badgeId == badge.id);

        return GestureDetector(
          onTap: () => _showBadgeDetail(context, badge, unlocked),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: unlocked
                          ? EcoColors.violet.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (unlocked)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EcoColors.violet.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Icon(
                        _getIconForBadge(badge.name),
                        size: 32,
                        color: unlocked
                            ? EcoColors.violet
                            : EcoColors.ink.withValues(alpha: 0.2),
                      ),
                      if (unlocked)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: EcoColors.forest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: unlocked
                      ? EcoColors.ink
                      : EcoColors.ink.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeInfo badge, bool unlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: unlocked
                    ? EcoColors.violet.withValues(alpha: 0.1)
                    : EcoColors.clay,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForBadge(badge.name),
                size: 40,
                color: unlocked
                    ? EcoColors.violet
                    : EcoColors.ink.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              badge.name,
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: EcoColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: EcoColors.ink.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            EcoPulseButton(
              label: unlocked ? 'GOT IT' : 'CLOSE',
              isPrimary: unlocked,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForBadge(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('rookie') || lowerName.contains('first')) {
      return Icons.eco;
    }
    if (lowerName.contains('warrior')) {
      return Icons.shield;
    }
    if (lowerName.contains('hero')) {
      return Icons.location_on;
    }
    if (lowerName.contains('water')) {
      return Icons.water_drop;
    }
    if (lowerName.contains('recycle')) {
      return Icons.recycling;
    }
    if (lowerName.contains('leader')) {
      return Icons.groups;
    }
    return Icons.workspace_premium;
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Nature Novice';
    if (level < 10) return 'Park Protector';
    if (level < 15) return 'Forest Guardian';
    return 'Eco Legend';
  }
}

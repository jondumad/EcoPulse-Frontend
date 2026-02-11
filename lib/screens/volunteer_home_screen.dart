import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../providers/nav_provider.dart';
import '../models/mission_model.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/mission_card.dart';
import 'volunteer/mission_detail_screen.dart';
import 'volunteer/badges_modal.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  final PageController _upcomingPageController = PageController();
  int _currentUpcomingPage = 0;

  @override
  void dispose() {
    _upcomingPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = context.read<AuthProvider>();
          final missionProvider = context.read<MissionProvider>();
          await Future.wait([
            authProvider.refreshProfile(),
            authProvider.fetchUserStats(),
            missionProvider.fetchMissions(forceRefresh: true),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildStatCards(context),
              const SizedBox(height: 32),
              _buildUpcomingMission(context),
              const SizedBox(height: 32),
              _buildRecommendedMissions(context),
              const SizedBox(height: 120), // Support floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Selector<
      AuthProvider,
      ({String name, int totalPoints, bool hasUser})
    >(
      selector: (context, provider) => (
        name: provider.user?.name ?? '',
        totalPoints: provider.user?.totalPoints ?? 0,
        hasUser: provider.user != null,
      ),
      builder: (context, data, child) {
        if (!data.hasUser) return const SizedBox.shrink();

        final firstName = data.name.split(' ').first;
        final now = DateTime.now();
        String greeting = "Good Morning";
        if (now.hour >= 12 && now.hour < 17) {
          greeting = "Good Afternoon";
        } else if (now.hour >= 17) {
          greeting = "Good Evening";
        }

        final totalPoints = data.totalPoints;
        final currentLevel = (totalPoints / 500).floor() + 1;
        final pointsInCurrentLevel = totalPoints % 500;
        final progressToNextLevel = pointsInCurrentLevel / 500;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    firstName,
                    style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => BadgesModal.show(context),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progressToNextLevel,
                      backgroundColor: AppTheme.clay,
                      color: AppTheme.violet,
                      strokeWidth: 4,
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'Lvl\n$currentLevel',
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 10,
                              height: 1.1,
                              color: AppTheme.violet,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return Selector<
      AuthProvider,
      ({Map<String, dynamic>? stats, int totalPoints})
    >(
      selector: (context, provider) => (
        stats: provider.userStats,
        totalPoints: provider.user?.totalPoints ?? 0,
      ),
      builder: (context, data, child) {
        final hours = data.stats?['totalHours'] ?? 0;
        final completed = data.stats?['actionsCompleted'] ?? 0;
        final impact = (data.totalPoints * 1.5).toInt();

        return EcoPulseCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: EcoStatItem(
                  label: "Hours",
                  value: "$hours",
                  color: AppTheme.forest,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderSubtle.withValues(alpha: 0.5),
              ),
              Expanded(
                child: EcoStatItem(
                  label: "Missions",
                  value: "$completed",
                  color: AppTheme.violet,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderSubtle.withValues(alpha: 0.5),
              ),
              Expanded(
                child: EcoStatItem(
                  label: "Impact",
                  value: "$impact",
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingMission(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const EcoSectionHeader(title: "Active Deployment"),
            Selector<MissionProvider, int>(
              selector: (context, provider) => provider.upcomingMissions.length,
              builder: (context, count, child) {
                if (count <= 1) return const SizedBox.shrink();
                return Row(
                  children: List.generate(
                    count,
                    (index) => Container(
                      width: _currentUpcomingPage == index ? 16 : 4,
                      height: 4,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: _currentUpcomingPage == index
                            ? AppTheme.forest
                            : AppTheme.forest.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Selector<MissionProvider, ({bool isLoading, List<Mission> missions})>(
          selector: (context, provider) => (
            isLoading: provider.isLoading,
            missions: provider.upcomingMissions,
          ),
          builder: (context, data, child) {
            if (data.isLoading && data.missions.isEmpty) {
              return const EcoPulseSkeleton(height: 180, radius: 24);
            }

            if (data.missions.isNotEmpty) {
              return SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _upcomingPageController,
                  onPageChanged: (index) {
                    setState(() => _currentUpcomingPage = index);
                  },
                  itemCount: data.missions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _UpcomingMissionCard(
                        mission: data.missions[index],
                      ),
                    );
                  },
                ),
              );
            }

            return EcoPulseCard(
              variant: CardVariant.paper,
              onTap: () => context.read<NavProvider>().setIndex(0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.clay,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sensors_off_rounded,
                        size: 32,
                        color: AppTheme.ink.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "NO ACTIVE MISSIONS",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan for opportunities in the Mission Hub",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedMissions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcoSectionHeader(
          title: "RECOMMENDED FOR YOU",
          trailing: TextButton(
            onPressed: () {
              context.read<NavProvider>().setIndex(0);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SEE ALL",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppTheme.forest,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child:
              Selector<
                MissionProvider,
                ({bool isLoading, List<Mission> missions})
              >(
                selector: (context, provider) => (
                  isLoading: provider.isLoading,
                  missions: provider.recommendedMissions,
                ),
                builder: (context, data, child) {
                  if (data.isLoading && data.missions.isEmpty) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      padding: const EdgeInsets.only(left: 4),
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: EcoPulseSkeleton(
                          width: 200,
                          height: 240,
                          radius: 24,
                        ),
                      ),
                    );
                  }

                  if (data.missions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: 40,
                            color: AppTheme.ink.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No missions available nearby",
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.ink.withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    itemCount: data.missions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == data.missions.length) {
                        return _buildSeeAllCard(context);
                      }
                      return _CompactMissionCard(mission: data.missions[index]);
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSeeAllCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavProvider>().setIndex(0),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.forest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forest.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "EXPLORE ALL",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingMissionCard extends StatelessWidget {
  final Mission mission;

  const _UpcomingMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final bool isEmergency =
        mission.isEmergency ||
        mission.priority == 'Critical' ||
        mission.priority == 'High';
    final String categoryIcon = mission.categories.isNotEmpty
        ? mission.categories.first.icon
        : '🌿';

    return EcoPulseCard(
      padding: const EdgeInsets.all(16),
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
              // Technical Status Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DEPLOYMENT STATUS",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink.withValues(alpha: 0.4),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.forest,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ACTIVE",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Points Shield
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppTheme.violet,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${mission.pointsValue} PTS",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mission.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? AppTheme.terracotta.withValues(alpha: 0.1)
                      : AppTheme.forest.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEmergency
                      ? Icons.priority_high_rounded
                      : Icons.location_on_rounded,
                  size: 12,
                  color: isEmergency ? AppTheme.terracotta : AppTheme.forest,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(categoryIcon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTemporalProgress(mission),
          const SizedBox(height: 12),
          CoordinatedActionButtons(mission: mission),
        ],
      ),
    );
  }

  Widget _buildTemporalProgress(Mission mission) {
    final now = DateTime.now();
    final start = mission.startTime;
    final end = mission.endTime;

    double progress = 0.0;
    String statusLabel = "PRE-DEPLOYMENT"; // Default status

    if (now.isAfter(end)) {
      progress = 1.0;
      statusLabel = "DEPLOYMENT COMPLETE";
    } else if (now.isAfter(start)) {
      final total = end.difference(start).inSeconds;
      final elapsed = now.difference(start).inSeconds;
      progress = (elapsed / total).clamp(0.0, 1.0);
      statusLabel = "DEPLOYMENT ACTIVE";
    } else if (mission.registeredAt != null) {
      // Pre-deployment progress based on registration time
      final totalWait = start.difference(mission.registeredAt!).inSeconds;
      final elapsedWait = now.difference(mission.registeredAt!).inSeconds;
      if (totalWait > 0) {
        progress = (elapsedWait / totalWait).clamp(0.0, 1.0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusLabel,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppTheme.forest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.clay,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.forest,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMissionCard extends StatelessWidget {
  final Mission mission;

  const _CompactMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final bool isUrgent = mission.isEmergency || mission.priority == 'Critical';
    final String categoryIcon = mission.categories.isNotEmpty
        ? mission.categories.first.icon
        : '🌿';

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: EcoPulseCard(
        padding: EdgeInsets.zero,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled Visual Header (Modular Aesthetic)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppTheme.terracotta.withValues(alpha: 0.05)
                    : AppTheme.clay,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Abstract Background Pulse/Pattern
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Opacity(
                      opacity: 0.08,
                      child: Text(
                        categoryIcon,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  // Foreground Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? AppTheme.terracotta
                                    : AppTheme.forest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                mission.priority.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                categoryIcon,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppTheme.violet,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${mission.pointsValue} PTS",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Progress Bar Scanline Aspect
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            (isUrgent ? AppTheme.terracotta : AppTheme.forest)
                                .withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppTheme.ink.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mission.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.ink.withValues(alpha: 0.5),
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
      ),
    );
  }
}

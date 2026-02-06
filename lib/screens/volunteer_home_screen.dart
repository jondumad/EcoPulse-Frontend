import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../providers/nav_provider.dart';
import '../models/mission_model.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/mission_card.dart';
import 'volunteer/mission_detail_screen.dart';
import 'volunteer/badges_modal.dart';

class VolunteerHomeScreen extends StatelessWidget {
  const VolunteerHomeScreen({super.key});

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
        final hours = 24;
        final completed = data.stats?['actionsCompleted'] ?? 12;
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
        const EcoSectionHeader(title: "UPCOMING MISSION"),
        const SizedBox(height: 12),
        Selector<MissionProvider, ({bool isLoading, List<Mission> missions})>(
          selector: (context, provider) => (
            isLoading: provider.isLoading,
            missions: provider.upcomingMissions,
          ),
          builder: (context, data, child) {
            if (data.isLoading && data.missions.isEmpty) {
              return const EcoPulseSkeleton(height: 160, radius: 20);
            }

            if (data.missions.isNotEmpty) {
              return MissionCard(mission: data.missions.first);
            }

            return EcoPulseCard(
              onTap: () {
                context.read<NavProvider>().setIndex(0); // Mission Hub
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 48,
                        color: AppTheme.ink.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No upcoming missions",
                        style: AppTheme.lightTheme.textTheme.bodyLarge
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Find Your First Mission",
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                              color: AppTheme.forest,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ],
                  ),
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
      children: [
        EcoSectionHeader(
          title: "RECOMMENDED FOR YOU",
          trailing: TextButton(
            onPressed: () {
              context.read<NavProvider>().setIndex(0);
            },
            child: Text(
              "See All",
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.forest,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
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
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: EcoPulseSkeleton(
                          width: 180,
                          height: 220,
                          radius: 20,
                        ),
                      ),
                    );
                  }

                  if (data.missions.isEmpty) {
                    return Center(
                      child: Text(
                        "No missions available nearby",
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.4),
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ), // Room for shadow
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
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.clay,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.forest),
              const SizedBox(height: 8),
              Text(
                "See All",
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMissionCard extends StatelessWidget {
  final Mission mission;

  const _CompactMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
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
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=300&h=200&fit=crop", // Placeholder
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.clay,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.clay,
                  child: const Icon(Icons.eco, color: AppTheme.forest),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mission.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: AppTheme.ink.withValues(alpha: 0.5),
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

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
import 'level_details_screen.dart';

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return const SizedBox.shrink();

    final firstName = user.name.split(' ').first;
    final now = DateTime.now();
    String greeting = "Good Morning";
    if (now.hour >= 12 && now.hour < 17) {
      greeting = "Good Afternoon";
    } else if (now.hour >= 17) {
      greeting = "Good Evening";
    }

    final totalPoints = user.totalPoints;
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LevelDetailsScreen(),
              ),
            );
          },
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
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
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
  }

  Widget _buildStatCards(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final stats = authProvider.userStats;
    final user = authProvider.user;

    // Real values or mock as requested
    final hours = 24; // Mock until backend ready
    final completed = stats?['actionsCompleted'] ?? 12; // Real or Mock
    final impact =
        (user?.totalPoints ?? 0) * 1.5.round(); // Formula based impact

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Hours",
            value: "$hours",
            semanticLabel: "$hours hours volunteered",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: "Missions",
            value: "$completed",
            semanticLabel: "$completed missions completed",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: "Impact",
            value: "${impact.toInt()}",
            semanticLabel: "Impact score ${impact.toInt()}",
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMission(BuildContext context) {
    final missionProvider = context.watch<MissionProvider>();
    final upcomingMissions =
        missionProvider.missions
            .where((m) => m.isRegistered && m.status == 'Open')
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UPCOMING MISSION",
          style: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        if (upcomingMissions.isNotEmpty)
          MissionCard(mission: upcomingMissions.first)
        else
          EcoPulseCard(
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
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Find Your First Mission",
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.forest,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedMissions(BuildContext context) {
    final missionProvider = context.watch<MissionProvider>();
    final openMissions = missionProvider.missions
        .where((m) => m.status == 'Open' && !m.isRegistered)
        .take(10)
        .toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RECOMMENDED FOR YOU",
              style: AppTheme.lightTheme.textTheme.labelLarge,
            ),
            TextButton(
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
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: openMissions.isEmpty
              ? Center(
                  child: Text(
                    "No missions available nearby",
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: openMissions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == openMissions.length) {
                      return _buildSeeAllCard(context);
                    }
                    return _CompactMissionCard(mission: openMissions[index]);
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String semanticLabel;

  const _StatCard({
    required this.label,
    required this.value,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: EcoPulseCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                  fontSize: 20,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
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

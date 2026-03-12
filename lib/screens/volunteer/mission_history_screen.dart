import 'package:flutter/material.dart';
import 'package:frontend/widgets/empty_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/atoms/eco_card.dart';
import '../../screens/volunteer/mission_detail_screen.dart';

class MissionHistoryScreen extends StatefulWidget {
  final List<Mission> missions;

  const MissionHistoryScreen({super.key, required this.missions});

  @override
  State<MissionHistoryScreen> createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStatus = 'All';
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Map<String, List<Mission>> _groupMissions(List<Mission> missions) {
    final Map<String, List<Mission>> grouped = {};
    for (var m in missions) {
      final month = DateFormat('MMMM yyyy').format(m.startTime);
      if (!grouped.containsKey(month)) {
        grouped[month] = [];
      }
      grouped[month]!.add(m);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final stats = auth.userStats;

    final now = DateTime.now();
    final filteredHistory = widget.missions.where((m) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          m.title.toLowerCase().contains(query) ||
          m.locationName.toLowerCase().contains(query) ||
          m.categories.any((c) => c.name.toLowerCase().contains(query));

      final matchesStatus =
          _filterStatus == 'All' || m.registrationStatus == _filterStatus;

      final isActuallyEnded =
          m.registrationStatus == 'Completed' ||
          m.registrationStatus == 'Cancelled' ||
          (m.registrationStatus == 'Registered' && m.endTime.isBefore(now));

      return matchesSearch && matchesStatus && isActuallyEnded;
    }).toList();

    // Sort by most recent first
    filteredHistory.sort((a, b) => b.startTime.compareTo(a.startTime));
    final groupedMissions = _groupMissions(filteredHistory);

    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: EcoAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mission History',
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            Text(
              'Your legacy of environmental impact',
              style: EcoText.bodySM(context).copyWith(
                color: AppTheme.ink.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _entranceController,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildHistoryStats(stats, auth.user?.totalPoints ?? 0),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildFilterChips(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (filteredHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: EmptyState(
                  icon: _searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.history_toggle_off_rounded,
                  title: _searchQuery.isNotEmpty
                      ? 'NO MATCHES FOUND'
                      : 'NO HISTORY YET',
                  description: _searchQuery.isNotEmpty
                      ? 'Try adjusting your search or filters to find what you\'re looking for.'
                      : 'Your environmental impact will appear here once you complete your first mission.',
                  action: _searchQuery.isNotEmpty
                      ? EcoPulseButton(
                          label: 'Clear Search',
                          isSmall: true,
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
            )
          else
            ...groupedMissions.entries.map((entry) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 8),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.ink.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: entry.value.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _HistoryMissionCard(
                            mission: entry.value[index],
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            }),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHistoryStats(Map<String, dynamic>? stats, int totalPoints) {
    final completedCount =
        stats?['actionsCompleted'] ??
        widget.missions
            .where((m) => m.registrationStatus == 'Completed')
            .length;

    return EcoPulseCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: EcoStatItem(
              label: 'COMPLETED',
              value: '$completedCount',
              color: AppTheme.forest,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppTheme.ink.withValues(alpha: 0.08),
          ),
          Expanded(
            child: EcoStatItem(
              label: 'POINTS EARNED',
              value: '$totalPoints',
              color: AppTheme.violet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.ink),
        decoration: InputDecoration(
          hintText: 'Search the archives...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.ink.withValues(alpha: 0.2),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: AppTheme.forest.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: ['All', 'Completed', 'Cancelled'].map((status) {
        final isSelected = _filterStatus == status;
        return Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: InkWell(
            onTap: () => setState(() => _filterStatus = status),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.ink : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.ink : AppTheme.ink.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryMissionCard extends StatelessWidget {
  final Mission mission;

  const _HistoryMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = mission.registrationStatus == 'Cancelled';
    final bool isCompleted = mission.registrationStatus == 'Completed';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailScreen(mission: mission),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon / Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCancelled 
                        ? AppTheme.terracotta.withValues(alpha: 0.08)
                        : (isCompleted 
                            ? AppTheme.forest.withValues(alpha: 0.08)
                            : AppTheme.violet.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      mission.categories.isNotEmpty ? mission.categories.first.icon : '🌱',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      isCancelled 
                          ? Icons.cancel_rounded 
                          : (isCompleted ? Icons.check_circle_rounded : Icons.history_rounded),
                      size: 18,
                      color: isCancelled 
                          ? AppTheme.terracotta 
                          : (isCompleted ? AppTheme.forest : AppTheme.violet),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isCancelled ? AppTheme.ink.withValues(alpha: 0.4) : AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: AppTheme.ink.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mission.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.ink.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.clay,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(mission.startTime),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted)
                        Text(
                          '+${mission.pointsValue} PTS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forest,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right_rounded, 
              color: AppTheme.ink.withValues(alpha: 0.1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

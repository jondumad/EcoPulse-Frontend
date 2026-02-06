import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../components/mission_list.dart';

class MissionHistoryScreen extends StatefulWidget {
  final List<Mission> missions;

  const MissionHistoryScreen({super.key, required this.missions});

  @override
  State<MissionHistoryScreen> createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Completed, Cancelled

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final stats = auth.userStats;

    // Filter logic
    final filteredHistory = widget.missions.where((m) {
      final matchesSearch = m.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _filterStatus == 'All' || m.registrationStatus == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: EcoColors.clay,
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mission History',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Stats Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildHistoryStats(stats, auth.user?.totalPoints ?? 0),
            ),
          ),

          // 2. Search & Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Mission List
          if (filteredHistory.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverToBoxAdapter(
                child: MissionList(missions: filteredHistory, isHistory: true),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
      variant: CardVariant.hero,
      child: Row(
        children: [
          _StatItem(
            label: 'COMPLETED',
            value: '$completedCount',
            icon: Icons.check_circle_outline,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          _StatItem(
            label: 'POINTS EARNED',
            value: '$totalPoints',
            icon: Icons.stars_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search past missions...',
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: ['All', 'Completed', 'Cancelled'].map((status) {
        final isSelected = _filterStatus == status;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () => setState(() => _filterStatus = status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? EcoColors.forest : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? EcoColors.forest
                      : const Color.fromRGBO(0, 0, 0, 0.1),
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : EcoColors.ink,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: EcoColors.ink.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No history found matching your filters',
            style: EcoText.bodyMD(
              context,
            ).copyWith(color: EcoColors.ink.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

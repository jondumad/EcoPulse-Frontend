import 'package:flutter/material.dart';
import 'package:frontend/widgets/empty_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/atoms/eco_card.dart';
import '../../components/mission_list.dart';

class MissionHistoryScreen extends StatefulWidget {
  final List<Mission> missions;

  const MissionHistoryScreen({super.key, required this.missions});

  @override
  State<MissionHistoryScreen> createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';

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

    return Scaffold(
      backgroundColor: EcoColors.clay,
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
                color: EcoColors.ink,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            Text(
              'Your past environmental impact',
              style: EcoText.bodySM(context).copyWith(
                color: EcoColors.ink.withValues(alpha: 0.4),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _buildHistoryStats(stats, auth.user?.totalPoints ?? 0),
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
                  const SizedBox(height: 24),
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList.builder(
                itemCount: filteredHistory.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MissionListItem(
                      mission: filteredHistory[index],
                      isHistory: true,
                    ),
                  );
                },
              ),
            ),
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
              color: EcoColors.forest,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: EcoColors.ink.withValues(alpha: 0.08),
          ),
          Expanded(
            child: EcoStatItem(
              label: 'POINTS EARNED',
              value: '$totalPoints',
              color: EcoColors.violet,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EcoColors.ink.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: EcoColors.ink.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: EcoText.bodyMD(context).copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search the archives...',
          hintStyle: EcoText.bodyMD(
            context,
          ).copyWith(color: EcoColors.ink.withValues(alpha: 0.2)),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              size: 22,
              color: EcoColors.forest.withValues(alpha: 0.8),
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ['All', 'Completed', 'Cancelled'].map((status) {
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? EcoColors.forest : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? EcoColors.forest
                        : EcoColors.ink.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: EcoColors.forest.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  status,
                  style: EcoText.bodySM(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : EcoColors.ink.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

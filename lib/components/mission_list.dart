import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../screens/volunteer/mission_detail_screen.dart';
import '../widgets/eco_pulse_widgets.dart';

class MissionList extends StatefulWidget {
  final List<Mission> missions;
  final bool isHistory;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool showSearch;
  final String? emptyMessage;

  const MissionList({
    super.key,
    required this.missions,
    this.isHistory = false,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.showSearch = false,
    this.emptyMessage,
  });

  @override
  State<MissionList> createState() => _MissionListState();
}

class _MissionListState extends State<MissionList> {
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mission> get _filteredMissions {
    if (_searchQuery.isEmpty) return widget.missions;
    final query = _searchQuery.toLowerCase();
    return widget.missions.where((m) {
      return m.title.toLowerCase().contains(query) ||
          m.locationName.toLowerCase().contains(query) ||
          m.categories.any((c) => c.name.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSearch) ...[
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildResultsCount(filtered.length),
          const SizedBox(height: 12),
        ],
        if (filtered.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: widget.shrinkWrap,
            physics: widget.physics,
            itemCount: filtered.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final mission = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MissionListItem(
                  mission: mission,
                  isHistory: widget.isHistory,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.ink.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search missions, locations, or categories...',
          hintStyle: TextStyle(
            color: EcoColors.ink.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: EcoColors.ink.withValues(alpha: 0.4),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCount(int count) {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    return Text(
      'Found $count ${count == 1 ? 'mission' : 'missions'}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: EcoColors.ink.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: EcoColors.ink.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EcoColors.ink.withValues(alpha: 0.05),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.assignment_outlined,
            size: 48,
            color: EcoColors.ink.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No missions match "$_searchQuery"'
                : widget.emptyMessage ?? 'No missions available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: EcoColors.ink.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MissionListItem extends StatelessWidget {
  final Mission mission;
  final bool isHistory;

  const MissionListItem({super.key, required this.mission, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailScreen(mission: mission),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isHistory
                    ? EcoColors.ink.withValues(alpha: 0.05)
                    : EcoColors.forest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  mission.categories.isNotEmpty
                      ? mission.categories.first.icon
                      : '🌱',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isHistory
                          ? EcoColors.ink.withValues(alpha: 0.7)
                          : EcoColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: EcoColors.ink.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(mission.startTime),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: EcoColors.ink.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.ink.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mission.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: EcoColors.ink.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status/Action
            if (!isHistory) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: EcoColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: EcoColors.forest,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 12),
              if (mission.registrationStatus == 'Cancelled')
                const Icon(
                  Icons.cancel_outlined,
                  color: EcoColors.terracotta,
                  size: 20,
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  color: EcoColors.forest,
                  size: 20,
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
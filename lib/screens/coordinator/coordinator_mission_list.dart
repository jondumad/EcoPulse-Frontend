import 'package:flutter/material.dart';
import 'package:frontend/widgets/coordinator_mission_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/mission_filter_widgets.dart';
import '../../widgets/volunteer_list_modal.dart';
import 'qr_display.dart';
import 'mission_management_screen.dart';

class CoordinatorMissionListScreen extends StatefulWidget {
  const CoordinatorMissionListScreen({super.key});

  @override
  State<CoordinatorMissionListScreen> createState() =>
      _CoordinatorMissionListScreenState();
}

class _CoordinatorMissionListScreenState
    extends State<CoordinatorMissionListScreen> {
  final Set<int> _selectedMissions = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(
        context,
        listen: false,
      ).fetchMissions(mine: true);
    });
  }

  void _toggleSelection(int missionId) {
    setState(() {
      if (_selectedMissions.contains(missionId)) {
        _selectedMissions.remove(missionId);
        if (_selectedMissions.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMissions.add(missionId);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(int missionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedMissions.add(missionId);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMissions.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _handleBatchAction(
    String action,
    MissionProvider provider,
  ) async {
    final count = _selectedMissions.length;
    final ids = _selectedMissions.toList();

    if (action == 'Notify') {
      final message = await showDialog<String>(
        context: context,
        builder: (ctx) {
          String val = '';
          return AlertDialog(
            title: Text('Notify Volunteers ($count Missions)'),
            content: TextField(
              decoration: const InputDecoration(hintText: 'Enter message...'),
              onChanged: (v) => val = v,
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, val),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (message != null && message.isNotEmpty) {
        int successCount = 0;
        int failCount = 0;

        // Show loading indicator?
        // For now just process.

        for (final id in ids) {
          try {
            await provider.contactVolunteers(id, message);
            successCount++;
          } catch (e) {
            failCount++;
            debugPrint('Failed to notify mission $id: $e');
          }
        }

        if (!mounted) return;

        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sent $successCount notifications. Failed: $failCount',
              ),
            ),
          );
        }
        _clearSelection();
      }
      return;
    }

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$action $count Missions?'),
            content: Text(
              action == 'Duplicate'
                  ? 'This will create copies of the selected missions.'
                  : 'This action will update the status of selected missions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: action == 'Cancel' ? Colors.red : null,
                ),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      if (action == 'Duplicate') {
        int successCount = 0;
        for (final id in ids) {
          try {
            await provider.duplicateMission(id);
            successCount++;
          } catch (e) {
            debugPrint('Failed to duplicate $id: $e');
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated $successCount missions')),
        );
        _clearSelection();
      } else {
        // Batch status updates usually supported by backend as single call
        try {
          if (action == 'Cancel') {
            await provider.batchAction(ids, 'cancel');
          } else if (action == 'Mark as Emergency') {
            await provider.batchAction(ids, 'emergency');
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully processed $action')),
          );
          _clearSelection();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, provider, _) {
        final missions = provider.filteredMissions;

        return Scaffold(
          backgroundColor: AppTheme.clay,
          appBar: null,
          body: Stack(
            children: [
              Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,
                    child: _isSelectionMode
                        ? const SizedBox.shrink()
                        : SafeArea(
                            bottom: false,
                            child: _buildSearchAndFilter(provider),
                          ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => provider.fetchMissions(
                        mine: true,
                        forceRefresh: true,
                      ),
                      child: CustomScrollView(
                        slivers: [
                          if (!_isSelectionMode)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                child: _buildOverview(provider.missions),
                              ),
                            ),

                          if (provider.isLoading)
                            const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (missions.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(provider),
                            )
                          else
                            ..._buildGroupedMissionSlivers(missions, provider),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 120),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- Floating Selection Pill ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutBack,
                bottom: _isSelectionMode ? 100 : -100, // Float above bottom nav
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.forest.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Count Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${_selectedMissions.length}',
                                style: const TextStyle(
                                  fontFamily: 'Fraunces',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Buttons
                        _SelectionAction(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notify',
                          onTap: () => _handleBatchAction('Notify', provider),
                        ),
                        _SelectionAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Cancel',
                          onTap: () => _handleBatchAction('Cancel', provider),
                        ),

                        // More Menu
                        PopupMenuButton<String>(
                          offset: const Offset(0, -180),
                          color: AppTheme.ink,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (val) =>
                              _handleBatchAction(val, provider),
                          itemBuilder: (context) => [
                            _buildPopupItem(
                              'Duplicate',
                              Icons.copy_rounded,
                              Colors.white,
                            ),
                            _buildPopupItem(
                              'Mark as Emergency',
                              Icons.warning_amber_rounded,
                              AppTheme.terracotta,
                            ),
                            _buildPopupItem(
                              'Export Data',
                              Icons.file_download_outlined,
                              Colors.white70,
                            ),
                          ],
                        ),

                        const VerticalDivider(
                          color: Colors.white24,
                          width: 1,
                          indent: 10,
                          endIndent: 10,
                        ),

                        // Close Selection
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _clearSelection,
                          tooltip: 'Clear Selection',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedMissionSlivers(
    List<Mission> missions,
    MissionProvider provider,
  ) {
    final now = DateTime.now();
    final upcomingMissions = missions
        .where((m) => m.endTime.isAfter(now))
        .toList();
    final pastMissions = missions
        .where((m) => m.endTime.isBefore(now))
        .toList();

    List<Widget> slivers = [];

    // UPCOMING MISSIONS SECTION
    if (upcomingMissions.isNotEmpty) {
      slivers.add(_buildSectionHeader('UPCOMING MISSIONS', marginTop: 0));
      slivers.add(_buildMissionSliver(upcomingMissions, provider));
    }

    // PAST MISSIONS SECTION
    if (pastMissions.isNotEmpty) {
      slivers.add(_buildSectionHeader('PAST MISSIONS', marginTop: 32));

      // Only group by date if sorting by Date
      if (provider.currentSort == 'Date') {
        // Force sort past missions by endTime descending for chronological view
        pastMissions.sort((a, b) => b.endTime.compareTo(a.endTime));

        final Map<String, List<Mission>> groupedPastMissions = {};
        for (var m in pastMissions) {
          final dateStr = DateFormat('EEEE, MMM d, yyyy').format(m.endTime);
          groupedPastMissions.putIfAbsent(dateStr, () => []).add(m);
        }

        final sortedDates = groupedPastMissions.keys.toList();
        for (var date in sortedDates) {
          slivers.add(_buildDateHeader(date));
          slivers.add(
            _buildMissionSliver(groupedPastMissions[date]!, provider),
          );
        }
      } else {
        // For other sort orders (Distance, Status, etc.), show flat list
        // Note: provider.filteredMissions is already sorted by the selected criteria
        // We just trust that order within the 'Past' subset.
        slivers.add(_buildMissionSliver(pastMissions, provider));
      }
    }

    return slivers;
  }

  Widget _buildSectionHeader(String title, {double marginTop = 24}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, marginTop, 16, 12),
        child: EcoSectionHeader(title: title),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppTheme.forest,
            ),
            const SizedBox(width: 8),
            Text(
              date.toUpperCase(),
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.forest,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Divider(color: AppTheme.forest, thickness: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSliver(List<Mission> missions, MissionProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final mission = missions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CoordinatorMissionCard(
              mission: mission,
              isSelected: _selectedMissions.contains(mission.id),
              isSelectionMode: _isSelectionMode,
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(mission.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MissionManagementScreen(mission: mission),
                    ),
                  );
                }
              },
              onLongPress: () => _enterSelectionMode(mission.id),
              onVolunteerTap: () {
                VolunteerListModal.show(
                  context,
                  missionId: mission.id,
                  missionTitle: mission.title,
                  maxVolunteers: mission.maxVolunteers,
                );
              },
            ),
          );
        }, childCount: missions.length),
      ),
    );
  }

  Widget _buildSearchAndFilter(MissionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.clay,
      child: Column(
        children: [
          // Search + Sort Row
          Row(
            children: [
              Expanded(
                child: MissionSearchBar(
                  onChanged: provider.setSearchQuery,
                  // Pass a dummy controller or handle clearer internally inside the widget if needed
                  // For the provider version, we might just be setting state directly.
                  // But MissionSearchBar supports controller if we passed one.
                  // Since we didn't use a controller here before, we rely on onChanged.
                  // To support 'clear', the widget handles suffix icon logic based on controller text.
                  // If we want the suffix icon to clear the provider search, we might need a controller
                  // or just rely on the user clearing the text manually.
                  // For now, let's keep it simple and just use the onChanged.
                ),
              ),
              const SizedBox(width: 12),
              MissionSortButton(
                onSelected: provider.setSortOption,
                currentSort: provider.currentSort,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                EcoFilterChip(
                  label: 'All',
                  isSelected: provider.isFilterActive('All'),
                  onTap: () => provider.toggleFilter('All'),
                  color: AppTheme.forest,
                ),
                EcoFilterChip(
                  label: 'Emergency',
                  isSelected: provider.isFilterActive('Emergency'),
                  onTap: () => provider.toggleFilter('Emergency'),
                  color: AppTheme.terracotta,
                ),
                EcoFilterChip(
                  label: 'Active',
                  isSelected: provider.isFilterActive('Active'),
                  onTap: () => provider.toggleFilter('Active'),
                  color: AppTheme.forest,
                ),
                EcoFilterChip(
                  label: 'Completed',
                  isSelected: provider.isFilterActive('Completed'),
                  onTap: () => provider.toggleFilter('Completed'),
                  color: Colors.grey,
                ),
                EcoFilterChip(
                  label: 'Cancelled',
                  isSelected: provider.isFilterActive('Cancelled'),
                  onTap: () => provider.toggleFilter('Cancelled'),
                  color: Colors.red[900]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(List<Mission> missions) {
    final activeCount = missions
        .where((m) => m.status == 'Open' || m.status == 'InProgress')
        .length;
    final criticalCount = missions.where((m) => m.isEmergency).length;

    return EcoPulseCard(
      child: Column(
        children: [
          const EcoSectionHeader(title: 'COORDINATOR OVERVIEW'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              EcoStatItem(
                label: 'ACTIVE',
                value: activeCount.toString(),
                color: AppTheme.forest,
              ),
              EcoStatItem(
                label: 'CRITICAL',
                value: criticalCount.toString(),
                color: AppTheme.terracotta,
              ),
              EcoStatItem(
                label: 'TOTAL',
                value: missions.length.toString(),
                color: AppTheme.ink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MissionProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppTheme.ink.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No missions found',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search query.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            EcoPulseButton(
              label: 'Clear Filters',
              onPressed: () {
                provider.clearFilters();
              },
              isSmall: true,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.ink,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onTap,
      tooltip: label,
    );
  }
}

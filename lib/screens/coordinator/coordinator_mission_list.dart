import 'package:flutter/material.dart';
import 'package:frontend/widgets/coordinator_mission_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/attendance_provider.dart';
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
  Map<int, int> _pendingCounts = {};

  // Archive / History View State
  bool _showAllPast = false;
  int? _activeYear;
  int? _activeMonth;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(
        context,
        listen: false,
      ).fetchMissions(mine: true);
      _fetchPendingCounts();
    });
  }

  Future<void> _fetchPendingCounts() async {
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final pending = await attendanceProvider.getPendingVerifications();
      if (!mounted) return;
      
      final Map<int, int> counts = {};
      for (var v in pending) {
        final missionId = v['missionId'] as int;
        counts[missionId] = (counts[missionId] ?? 0) + 1;
      }
      
      setState(() {
        _pendingCounts = counts;
      });
    } catch (e) {
      debugPrint('Error fetching pending counts: $e');
    }
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
    final ids = _selectedMissions.toList();
    final missions = provider.missions
        .where((m) => _selectedMissions.contains(m.id))
        .toList();

    if (action == 'Notify') {
      _showNotifyDialog(provider, ids);
      return;
    }

    if (action == 'Export Data') {
      _handleExport(missions);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          _BatchConfirmationDialog(action: action, missions: missions),
    );

    if (result != null && result['confirm'] == true) {
      final justification = result['justification'] as String?;

      if (action == 'Duplicate') {
        _handleBatchDuplicate(provider, ids);
      } else {
        try {
          if (action == 'Cancel') {
            await provider.batchAction(ids, 'cancel');
          } else if (action == 'Mark as Emergency') {
            await provider.batchAction(
              ids,
              'emergency',
              justification: justification,
            );
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

  Future<void> _showNotifyDialog(
    MissionProvider provider,
    List<int> ids,
  ) async {
    final count = ids.length;
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

      for (final id in ids) {
        try {
          await provider.contactVolunteers(id, message);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent $successCount notifications. Failed: $failCount'),
        ),
      );
      _clearSelection();
    }
  }

  Future<void> _handleBatchDuplicate(
    MissionProvider provider,
    List<int> ids,
  ) async {
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
  }

  void _handleExport(List<Mission> missions) {
    // Placeholder for CSV export logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting mission data...')));
    _clearSelection();
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
                      onRefresh: () async {
                        await provider.fetchMissions(
                          mine: true,
                          forceRefresh: true,
                        );
                        await _fetchPendingCounts();
                      },
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
    final allPastMissions = missions
        .where((m) => m.endTime.isBefore(now))
        .toList();

    List<Widget> slivers = [];

    // 1. UPCOMING MISSIONS SECTION
    if (upcomingMissions.isNotEmpty) {
      slivers.add(_buildSectionHeader('UPCOMING MISSIONS', marginTop: 0));
      slivers.add(_buildMissionSliver(upcomingMissions, provider));
    }

    if (allPastMissions.isEmpty) return slivers;

    // 2. PAST MISSIONS / ARCHIVE SECTION
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    slivers.add(_buildSectionHeader(
      _showAllPast ? 'MISSION ARCHIVE' : 'RECENT PAST MISSIONS',
      marginTop: 32,
      trailing: _showAllPast
          ? TextButton(
              onPressed: () => setState(() => _showAllPast = false),
              child: const Text(
                'BACK TO RECENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    ));

    if (!_showAllPast) {
      // Show missions from the last 7 days
      final recentPastMissions = allPastMissions
          .where((m) => m.endTime.isAfter(sevenDaysAgo))
          .toList();

      if (recentPastMissions.isEmpty) {
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Center(
              child: Text(
                'No activity in the past 7 days.',
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ));
      } else {
        _addDateGroupedSlivers(slivers, recentPastMissions, provider);
      }

      // Show "View All" button if there are older missions
      if (allPastMissions.length > recentPastMissions.length) {
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: EcoPulseButton(
              label: 'VIEW ALL HISTORY',
              icon: Icons.history_rounded,
              isPrimary: false,
              isSmall: true,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.violet,
              onPressed: () => setState(() => _showAllPast = true),
            ),
          ),
        ));
      }
    } else {
      // ARCHIVE VIEW: Grouped by Year -> Month
      final Map<int, Map<int, List<Mission>>> grouped = {};
      for (var m in allPastMissions) {
        grouped.putIfAbsent(m.endTime.year, () => {});
        grouped[m.endTime.year]!.putIfAbsent(m.endTime.month, () => []).add(m);
      }

      final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      if (_activeYear == null || !years.contains(_activeYear)) {
        _activeYear = years.isNotEmpty ? years.first : null;
      }

      if (_activeYear != null) {
        final months = grouped[_activeYear]!.keys.toList()..sort((a, b) => b.compareTo(a));
        if (_activeMonth == null || !months.contains(_activeMonth)) {
          _activeMonth = months.isNotEmpty ? months.first : null;
        }

        // Selection Tabs
        slivers.add(SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: years.map((y) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: EcoFilterChip(
                      label: '$y',
                      isSelected: _activeYear == y,
                      onTap: () => setState(() {
                        _activeYear = y;
                        _activeMonth = null; 
                      }),
                      color: AppTheme.forest,
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Month Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: months.map((m) {
                    final monthName = DateFormat.MMMM().format(DateTime(2024, m));
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: EcoFilterChip(
                        label: monthName.toUpperCase(),
                        isSelected: _activeMonth == m,
                        onTap: () => setState(() => _activeMonth = m),
                        color: AppTheme.violet,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ));

        // Missions for selected month
        if (_activeMonth != null) {
          final historyMissions = grouped[_activeYear]![_activeMonth]!;
          _addDateGroupedSlivers(slivers, historyMissions, provider);
        }
      }
    }

    return slivers;
  }

  void _addDateGroupedSlivers(
    List<Widget> slivers,
    List<Mission> missions,
    MissionProvider provider,
  ) {
    // Note: Always sort by date for consistency in past views
    missions.sort((a, b) => b.endTime.compareTo(a.endTime));

    final Map<String, List<Mission>> groupedByDate = {};
    for (var m in missions) {
      final dateStr = DateFormat('EEEE, MMM d, yyyy').format(m.endTime);
      groupedByDate.putIfAbsent(dateStr, () => []).add(m);
    }

    final sortedDates = groupedByDate.keys.toList();
    for (var date in sortedDates) {
      slivers.add(_buildDateHeader(date));
      slivers.add(_buildMissionSliver(groupedByDate[date]!, provider));
    }
  }

  Widget _buildSectionHeader(String title, {double marginTop = 24, Widget? trailing}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, marginTop, 16, 12),
        child: EcoSectionHeader(title: title, trailing: trailing),
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
              pendingVerificationsCount: _pendingCounts[mission.id] ?? 0,
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

class _BatchConfirmationDialog extends StatefulWidget {
  final String action;
  final List<Mission> missions;

  const _BatchConfirmationDialog({
    required this.action,
    required this.missions,
  });

  @override
  State<_BatchConfirmationDialog> createState() =>
      _BatchConfirmationDialogState();
}

class _BatchConfirmationDialogState extends State<_BatchConfirmationDialog> {
  final _justificationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isEmergency = widget.action == 'Mark as Emergency';
    final count = widget.missions.length;

    return AlertDialog(
      title: Text('${widget.action} $count Missions?'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.action == 'Duplicate'
                    ? 'This will create copies of the following missions:'
                    : 'This will update the following missions:',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.missions.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 8),
                  itemBuilder: (ctx, idx) => Text(
                    '• ${widget.missions[idx].title}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (isEmergency) ...[
                const SizedBox(height: 24),
                const Text(
                  'JUSTIFICATION REQUIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _justificationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Explain the emergency (min 20 chars)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 20) return 'More detail needed';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isEmergency && !_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'confirm': true,
              'justification': _justificationController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isEmergency
                ? AppTheme.terracotta
                : (widget.action == 'Cancel' ? Colors.red : AppTheme.forest),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

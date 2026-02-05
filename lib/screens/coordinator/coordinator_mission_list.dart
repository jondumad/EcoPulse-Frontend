import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/volunteer_bottom_sheet.dart';
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
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
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
        try {
          for (final id in ids) {
            await provider.contactVolunteers(id, message);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications sent successfully')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send notifications: $e')),
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
      try {
        if (action == 'Cancel') {
          await provider.batchAction(ids, 'cancel');
        } else if (action == 'Mark as Emergency') {
          await provider.batchAction(ids, 'emergency');
        } else if (action == 'Duplicate') {
          for (final id in ids) {
            await provider.duplicateMission(id);
          }
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
                      onRefresh: () =>
                          provider.fetchMissions(forceRefresh: true),
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
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final mission = missions[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CoordinatorMissionCard(
                                      mission: mission,
                                      isSelected: _selectedMissions.contains(
                                        mission.id,
                                      ),
                                      isSelectionMode: _isSelectionMode,
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          _toggleSelection(mission.id);
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MissionManagementScreen(
                                                    mission: mission,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      onLongPress: () =>
                                          _enterSelectionMode(mission.id),
                                      onVolunteerTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) =>
                                              VolunteerBottomSheet(
                                                missionId: mission.id,
                                                missionTitle: mission.title,
                                                maxVolunteers:
                                                    mission.maxVolunteers,
                                              ),
                                        );
                                      },
                                    ),
                                  );
                                }, childCount: missions.length),
                              ),
                            ),
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search missions...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort by',
                onSelected: provider.setSortOption,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Date', child: Text('Date')),
                  const PopupMenuItem(
                    value: 'Volunteer fill rate',
                    child: Text('Volunteer fill rate'),
                  ),
                  const PopupMenuItem(value: 'Status', child: Text('Status')),
                  const PopupMenuItem(
                    value: 'Distance',
                    child: Text('Distance'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Emergency',
                  isSelected: provider.isFilterActive('Emergency'),
                  onTap: () => provider.toggleFilter('Emergency'),
                  color: AppTheme.terracotta,
                ),
                _FilterChip(
                  label: 'Active',
                  isSelected: provider.isFilterActive('Active'),
                  onTap: () => provider.toggleFilter('Active'),
                  color: AppTheme.forest,
                ),
                _FilterChip(
                  label: 'Completed',
                  isSelected: provider.isFilterActive('Completed'),
                  onTap: () => provider.toggleFilter('Completed'),
                  color: Colors.grey,
                ),
                _FilterChip(
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'COORDINATOR OVERVIEW',
            style: AppTheme.lightTheme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OverviewStat(
                label: 'ACTIVE',
                value: activeCount.toString(),
                color: AppTheme.forest,
              ),
              const SizedBox(width: 40),
              _OverviewStat(
                label: 'CRITICAL',
                value: criticalCount.toString(),
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 40),
              _OverviewStat(
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
                provider.setSearchQuery('');
                // Ideally also clear active filters, need a method for that
                // provider.clearFilters();
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? color : AppTheme.ink.withValues(alpha: 0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: color,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? color : Colors.transparent),
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
            color: color,
            height: 1,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: AppTheme.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _CoordinatorMissionCard extends StatelessWidget {
  final Mission mission;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onVolunteerTap;

  const _CoordinatorMissionCard({
    required this.mission,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onVolunteerTap,
  });

  Color _getStatusColor() {
    if (mission.isEmergency) return AppTheme.terracotta;
    if (mission.status == 'Completed') return Colors.grey;
    if (mission.status == 'Cancelled') return Colors.red[900]!;
    if (mission.status == 'InProgress') return AppTheme.forest;
    return AppTheme.ink; // Open
  }

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inDays > 1) return '${diff.inDays} days left';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays == 0) {
      if (diff.inHours > 0) return 'In ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
      return 'Starting now';
    }
    // Past
    final past = now.difference(time);
    if (past.inDays > 0) return '${past.inDays}d ago';
    if (past.inHours > 0) return '${past.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final volunteerProgress =
        (mission.maxVolunteers != null && mission.maxVolunteers! > 0)
        ? mission.currentVolunteers / mission.maxVolunteers!
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          EcoPulseCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: AppTheme.forest, width: 2)
                    : Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),

                color: isSelected
                    ? AppTheme.forest.withValues(alpha: 0.05)
                    : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.clay,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              mission.categories.isNotEmpty
                                  ? mission.categories.first.icon
                                  : '📋',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mission.title,
                                style: AppTheme
                                    .lightTheme
                                    .textTheme
                                    .headlineMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetaItem(
                                      icon: Icons.location_on_outlined,
                                      label: mission.locationName,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetaItem(
                                      icon: Icons.access_time,
                                      label: _getRelativeTime(
                                        mission.startTime,
                                      ),
                                      color: mission.isEmergency
                                          ? AppTheme.terracotta
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: onVolunteerTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'VOLUNTEERS',
                                      style: AppTheme
                                          .lightTheme
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 16),
                                  ],
                                ),
                                Text(
                                  '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppTheme.forest),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.clay,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: volunteerProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.forest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: EcoPulseButton(
                            label: 'Manage',
                            onPressed: onTap, // Go to management
                            isSmall: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            onPressed:
                                _getStatusColor() == Colors.grey ||
                                    _getStatusColor() == Colors.red[900]! ||
                                    mission.endTime.isBefore(DateTime.now())
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QRDisplayScreen(
                                          missionId: mission.id,
                                          missionTitle: mission.title,
                                          activeUntil: mission.endTime,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.qr_code_2_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.clay,
                              foregroundColor: AppTheme.ink,
                              disabledBackgroundColor: AppTheme.clay
                                  .withValues(alpha: 0.5),
                              disabledForegroundColor: AppTheme.ink.withValues(
                                alpha: 0.2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ), // Smaller padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color.fromRGBO(0, 0, 0, 0.06),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.forest,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color ?? AppTheme.ink.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

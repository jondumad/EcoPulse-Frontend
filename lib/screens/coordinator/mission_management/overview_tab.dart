import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/mission_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/mission_provider.dart';
import '../../../../providers/collaboration_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/eco_notify_widgets.dart';
import '../../../../widgets/eco_pulse_widgets.dart';
import '../../../../widgets/user_search_modal.dart';
import '../edit_mission_screen.dart';

class OverviewTab extends StatefulWidget {
  final Mission mission;

  const OverviewTab({super.key, required this.mission});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late Mission _mission;
  bool _isUpdatingStatus = false;
  List<dynamic> _collaborators = [];
  bool _isLoadingCollaborators = false;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
    _fetchCollaborators();
    // Defer socket listener setup to ensure context is ready or do it in post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForEarlyCheckins();
    });
  }

  @override
  void dispose() {
    final collaborationProvider = Provider.of<CollaborationProvider>(
      context,
      listen: false,
    );
    collaborationProvider.socket?.off('early_checkin_alert');
    super.dispose();
  }

  Future<void> _fetchMission() async {
    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      await missionProvider.fetchMissions(mine: true);
      if (!mounted) return;
      final mission = missionProvider.missions.firstWhere(
        (m) => m.id == widget.mission.id,
      );
      setState(() => _mission = mission);
    } catch (e) {
      debugPrint('Error fetching specific mission: $e');
    }
  }

  Future<void> _fetchCollaborators() async {
    setState(() => _isLoadingCollaborators = true);
    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      final collabs = await missionProvider.getCollaborators(widget.mission.id);
      if (mounted) {
        setState(() {
          _collaborators = collabs;
          _isLoadingCollaborators = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCollaborators = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await Provider.of<MissionProvider>(
        context,
        listen: false,
      ).updateMissionStatus(widget.mission.id, status);
      if (mounted) await _fetchMission();
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  // Socket Listener for Early Check-ins
  void _listenForEarlyCheckins() {
    final collaborationProvider = Provider.of<CollaborationProvider>(
      context,
      listen: false,
    );
    final socket = collaborationProvider.socket;
    if (socket == null) return;
    socket.emit('join_mission', {'missionId': widget.mission.id});
    socket.off('early_checkin_alert');

    socket.on('early_checkin_alert', (data) {
      if (!mounted) return;
      if (data['missionId'] != widget.mission.id) return;

      _showEarlyStartDialog(data);
    });
  }

  void _showEarlyStartDialog(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Early Check-In Detected'),
        content: Text(
          '${data['volunteerName']} has checked in early.\n'
          'Do you want to start the mission now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Wait'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('InProgress');
            },
            style: ElevatedButton.styleFrom(backgroundColor: EcoColors.forest),
            child: const Text('Yes, Start Mission'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifySheet() async {
    EcoNotifySheet.show(
      context,
      title: 'Broadcast Update',
      subtitle: 'Notify all registered volunteers',
      onSend: (message) async {
        await Provider.of<MissionProvider>(
          context,
          listen: false,
        ).contactVolunteers(widget.mission.id, message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification sent to all volunteers'),
              backgroundColor: EcoColors.forest,
            ),
          );
        }
      },
    );
  }

  Future<void> _addCollaborator(int userId) async {
    try {
      await Provider.of<MissionProvider>(
        context,
        listen: false,
      ).addCollaborator(widget.mission.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborator added'),
            backgroundColor: EcoColors.forest,
          ),
        );
        _fetchCollaborators();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeCollaborator(int userId) async {
    try {
      await Provider.of<MissionProvider>(
        context,
        listen: false,
      ).removeCollaborator(widget.mission.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborator removed'),
            backgroundColor: EcoColors.forest,
          ),
        );
        _fetchCollaborators();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;

    return Consumer<MissionProvider>(
      builder: (context, missionProvider, _) {
        final mission = missionProvider.missions.firstWhere(
          (m) => m.id == widget.mission.id,
          orElse: () => _mission,
        );
        final isCreator = currentUser?.id == mission.createdBy;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMissionHeader(mission),
            const SizedBox(height: 24),
            _buildQuickStats(mission),
            const SizedBox(height: 32),
            const EcoSectionHeader(title: 'Mission Control'),
            _buildActionControls(mission),
            const SizedBox(height: 32),

            // Team Management Section (Visible to everyone involved, but actions restricted)
            if (isCreator || _collaborators.isNotEmpty) ...[
              EcoSectionHeader(
                title: 'Team Management',
                trailing: isCreator
                    ? GestureDetector(
                        onTap: () => UserSearchModal.show(
                          context,
                          mission.id,
                          targetRoleId: 2, // Coordinator
                          title: 'Invite Coordinator',
                          onInvite: _addCollaborator,
                        ),
                        child: Text(
                          'INVITE',
                          style: EcoText.monoSM(
                            context,
                          ).copyWith(color: EcoColors.forest),
                        ),
                      )
                    : null,
              ),
              if (_isLoadingCollaborators)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_collaborators.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No collaborators yet.',
                    style: TextStyle(color: Colors.black38),
                  ),
                )
              else
                ..._collaborators.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: EcoColors.clay,
                      child: Text(
                        c['name'][0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      c['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCreator
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeCollaborator(c['id']),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 32),
            ],

            const EcoSectionHeader(title: 'Description'),
            EcoPulseCard(
              child: Text(mission.description, style: EcoText.bodyMD(context)),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
  );
  }

  Widget _buildMissionHeader(Mission mission) {
    final bool isCompleted = mission.status == 'Completed';
    final bool isInProgress = mission.status == 'InProgress';
    final Color statusColor = isCompleted
        ? EcoColors.forest
        : (isInProgress
              ? EcoColors.violet
              : EcoColors.ink.withValues(alpha: 0.4));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, EcoColors.clay.withValues(alpha: 0.5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: EcoColors.ink.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mission.categories.isNotEmpty
                        ? mission.categories.first.icon
                        : '🌱',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.locationName.toUpperCase(),
                      style: EcoText.monoSM(context).copyWith(
                        color: EcoColors.ink.withValues(alpha: 0.4),
                        letterSpacing: 2,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.title,
                      style: EcoText.displayLG(context).copyWith(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mission.status
                                .replaceFirst('InProgress', 'In Progress')
                                .toUpperCase(),
                            style: EcoText.monoSM(context).copyWith(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Mission mission) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.clay),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: EcoStatItem(
              label: 'Volunteers',
              value:
                  '${mission.currentVolunteers}/${mission.maxVolunteers ?? '∞'}',
              color: EcoColors.forest,
            ),
          ),
          Container(width: 1, height: 30, color: EcoColors.clay),
          Expanded(
            child: EcoStatItem(
              label: 'Points',
              value: '${mission.pointsValue}',
              color: EcoColors.violet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(Mission mission) {
    final bool isCompleted = mission.status == 'Completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: _buildLifecycleButton(mission),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: EcoPulseButton(
                label: 'NOTIFY SQUAD',
                icon: Icons.notifications_active_rounded,
                isSmall: true,
                backgroundColor: EcoColors.violet,
                onPressed: _isUpdatingStatus ? null : _showNotifySheet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EcoPulseButton(
                label: 'EDIT MISSION',
                icon: Icons.edit_note_rounded,
                isSmall: true,
                backgroundColor: EcoColors.terracotta,
                onPressed: _isUpdatingStatus
                    ? null
                    : () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => EditMissionScreen(mission: mission),
                          ),
                        );
                        if (res == true && mounted) _fetchMission();
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifecycleButton(Mission mission) {
    if (mission.status == 'Open') {
      return EcoPulseButton(
        label: 'START MISSION NOW',
        icon: Icons.play_arrow_rounded,
        isLoading: _isUpdatingStatus,
        onPressed: _isUpdatingStatus ? null : () => _updateStatus('InProgress'),
      );
    }
    if (mission.status == 'InProgress') {
      return EcoPulseButton(
        label: 'CONCLUDE MISSION',
        icon: Icons.check_circle_rounded,
        isLoading: _isUpdatingStatus,
        backgroundColor: EcoColors.terracotta,
        onPressed: _isUpdatingStatus ? null : () => _updateStatus('Completed'),
      );
    }
    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/mission_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/mission_provider.dart';
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
  }

  Future<void> _fetchMission() async {
    try {
      final missionProvider = Provider.of<MissionProvider>(context, listen: false);
      await missionProvider.fetchMissions(mine: true);
      if (!mounted) return;
      final mission = missionProvider.missions.firstWhere((m) => m.id == widget.mission.id);
      setState(() => _mission = mission);
    } catch (e) {
      debugPrint('Error fetching specific mission: $e');
    }
  }

  Future<void> _fetchCollaborators() async {
    setState(() => _isLoadingCollaborators = true);
    try {
      final missionProvider = Provider.of<MissionProvider>(context, listen: false);
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
      await Provider.of<MissionProvider>(context, listen: false).updateMissionStatus(widget.mission.id, status);
      if (mounted) await _fetchMission();
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _showNotifySheet() async {
    EcoNotifySheet.show(
      context,
      title: 'Broadcast Update',
      subtitle: 'Notify all registered volunteers',
      onSend: (message) async {
        await Provider.of<MissionProvider>(context, listen: false)
            .contactVolunteers(widget.mission.id, message);
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
      await Provider.of<MissionProvider>(context, listen: false).addCollaborator(widget.mission.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collaborator added'), backgroundColor: EcoColors.forest),
        );
        _fetchCollaborators();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _removeCollaborator(int userId) async {
    try {
      await Provider.of<MissionProvider>(context, listen: false).removeCollaborator(widget.mission.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collaborator removed'), backgroundColor: EcoColors.forest),
        );
        _fetchCollaborators();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;
    final isCreator = currentUser?.id == _mission.createdBy; // Assuming mission model has creatorId or similar field logic

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMissionHeader(_mission),
        const SizedBox(height: 24),
        _buildQuickStats(_mission),
        const SizedBox(height: 32),
        const EcoSectionHeader(title: 'Mission Control'),
        _buildActionControls(_mission),
        const SizedBox(height: 32),
        
        // Team Management Section (Visible to everyone involved, but actions restricted)
        if (isCreator || _collaborators.isNotEmpty) ...[
          EcoSectionHeader(
            title: 'Team Management', 
            trailing: isCreator 
              ? GestureDetector(
                  onTap: () => UserSearchModal.show(
                    context, 
                    widget.mission.id, 
                    targetRoleId: 2, // Coordinator
                    title: 'Invite Coordinator',
                    onInvite: _addCollaborator
                  ),
                  child: Text('INVITE', style: EcoText.monoSM(context).copyWith(color: EcoColors.forest)),
                )
              : null,
          ),
          if (_isLoadingCollaborators)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_collaborators.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No collaborators yet.', style: TextStyle(color: Colors.black38)))
          else
            ..._collaborators.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: EcoColors.clay,
                child: Text(c['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: isCreator 
                ? IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red), onPressed: () => _removeCollaborator(c['id']))
                : null,
            )),
          const SizedBox(height: 32),
        ],

        const EcoSectionHeader(title: 'Description'),
        EcoPulseCard(child: Text(_mission.description, style: EcoText.bodyMD(context))),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMissionHeader(Mission mission) {
    return EcoPulseCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EcoColors.clay, borderRadius: BorderRadius.circular(12)),
            child: Text(mission.categories.isNotEmpty ? mission.categories.first.icon : '🌱', style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.locationName, style: EcoText.bodyBoldMD(context)),
                Text(mission.status.toUpperCase(), style: EcoText.monoSM(context).copyWith(color: EcoColors.forest)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Mission mission) {
    return Row(
      children: [
        Expanded(child: EcoPulseCard(child: EcoStatItem(label: 'Volunteers', value: '${mission.currentVolunteers}/${mission.maxVolunteers ?? '∞'}'))),
        const SizedBox(width: 16),
        Expanded(child: EcoPulseCard(child: EcoStatItem(label: 'Points', value: '${mission.pointsValue}'))),
      ],
    );
  }

  Widget _buildActionControls(Mission mission) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (mission.status == 'Open')
          EcoPulseButton(
            label: 'Start Mission',
            icon: Icons.play_arrow,
            isSmall: true,
            isLoading: _isUpdatingStatus,
            onPressed: _isUpdatingStatus ? null : () => _updateStatus('InProgress'),
          ),
        if (mission.status == 'InProgress')
          EcoPulseButton(
            label: 'Complete Mission',
            icon: Icons.check_circle,
            isSmall: true,
            isLoading: _isUpdatingStatus,
            onPressed: _isUpdatingStatus ? null : () => _updateStatus('Completed'),
          ),
        EcoPulseButton(
          label: 'Notify All',
          icon: Icons.notifications,
          isSmall: true,
          isPrimary: false,
          onPressed: _isUpdatingStatus ? null : _showNotifySheet,
        ),
        EcoPulseButton(
          label: 'Edit Info',
          icon: Icons.edit,
          isSmall: true,
          isPrimary: false,
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
      ],
    );
  }
}
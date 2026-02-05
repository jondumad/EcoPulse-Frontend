import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/eco_app_bar.dart';
import 'edit_mission_screen.dart';

class MissionManagementScreen extends StatefulWidget {
  final Mission mission;

  const MissionManagementScreen({super.key, required this.mission});

  @override
  State<MissionManagementScreen> createState() =>
      _MissionManagementScreenState();
}

class _MissionManagementScreenState extends State<MissionManagementScreen> {
  bool _isLoadingRegistrations = false;
  bool _isUpdatingStatus = false;
  List<Map<String, dynamic>> _registrations = [];
  Mission? _latestMission;

  @override
  void initState() {
    super.initState();
    _latestMission = widget.mission;
    _fetchRegistrations();
  }

  Future<void> _fetchMission() async {
    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      await missionProvider.fetchMissions();

      if (!mounted) return;

      final mission = missionProvider.missions.firstWhere(
        (m) => m.id == widget.mission.id,
      );

      setState(() {
        _latestMission = mission;
      });
    } catch (e) {
      debugPrint('Error fetching specific mission: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      await missionProvider.updateMissionStatus(widget.mission.id, newStatus);

      if (!mounted) return;
      await _fetchMission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mission status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _fetchRegistrations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRegistrations = true;
    });

    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      final data = await missionProvider.fetchRegistrations(widget.mission.id);

      if (mounted) {
        setState(() {
          _registrations = data;
          _isLoadingRegistrations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRegistrations = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load volunteers: $e')),
        );
      }
    }
  }

  Future<void> _manualCheckIn(int userId) async {
    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      await missionProvider.manualCheckIn(widget.mission.id, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer manually checked in')),
        );
        _fetchRegistrations(); // Refresh list to show new status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  Future<void> _manualComplete(int userId) async {
    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );
      await missionProvider.manualComplete(widget.mission.id, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer marked as completed')),
        );
        _fetchRegistrations(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  void _showVolunteerActions(Map<String, dynamic> user, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage ${user['name']}',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Current Status: $currentStatus',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              if (currentStatus != 'CheckedIn' && currentStatus != 'Completed')
                ListTile(
                  leading: const Icon(
                    Icons.login_rounded,
                    color: AppTheme.violet,
                  ),
                  title: const Text('Manual Check-In'),
                  subtitle: const Text('Force check-in volunteer'),
                  onTap: () {
                    Navigator.pop(context);
                    _manualCheckIn(user['id']);
                  },
                ),
              if (currentStatus != 'Completed')
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.forest,
                  ),
                  title: const Text('Mark Completed'),
                  subtitle: const Text('Verify completion & award points'),
                  onTap: () {
                    Navigator.pop(context);
                    _manualComplete(user['id']);
                  },
                ),
              if (currentStatus == 'Completed')
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Volunteer has completed this mission!"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMINISTRATION',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage Mission',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MISSION HEADER CARD
            _buildMissionHeader(_latestMission ?? widget.mission),
            const SizedBox(height: 24),

            // QUICK STATS
            _buildQuickStats(_latestMission ?? widget.mission),
            const SizedBox(height: 32),

            // ACTION CONTROLS
            Text(
              'MISSION CONTROL',
              style: AppTheme.lightTheme.textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            _buildActionControls(),
            const SizedBox(height: 32),

            // VOLUNTEER ROSTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VOLUNTEER ROSTER',
                  style: AppTheme.lightTheme.textTheme.labelLarge,
                ),
                Text(
                  '${(_latestMission ?? widget.mission).currentVolunteers} ACTIVE',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVolunteerList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionHeader(Mission mission) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.clay,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                mission.categories.isNotEmpty
                    ? mission.categories.first.icon
                    : '📋',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTheme.lightTheme.textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  mission.locationName,
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
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
        Expanded(
          child: _StatBox(
            label: 'STATUS',
            value: mission.status.toUpperCase(),
            color: _getStatusColor(mission.status),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            label: 'CAPACITY',
            value:
                '${mission.currentVolunteers}/${mission.maxVolunteers ?? "∞"}',
            color: AppTheme.forest,
          ),
        ),
      ],
    );
  }

  Widget _buildActionControls() {
    final status = (_latestMission ?? widget.mission).status;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (status == 'Open' || status == 'Pending')
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: 'Start Mission',
            onPressed: _isUpdatingStatus
                ? () {}
                : () => _updateStatus('InProgress'),
            color: AppTheme.forest,
          ),
        if (status == 'InProgress')
          _ControlButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Complete',
            onPressed: _isUpdatingStatus
                ? () {}
                : () => _updateStatus('Completed'),
            color: AppTheme.violet,
          ),
        _ControlButton(
          icon: Icons.edit_note_rounded,
          label: 'Edit Info',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditMissionScreen(
                  mission: _latestMission ?? widget.mission,
                ),
              ),
            );

            if (result == true && mounted) {
              _fetchMission(); // Refresh details if updated
            }
          },
          color: AppTheme.ink,
        ),
        if (status != 'Completed' && status != 'Cancelled')
          _ControlButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel',
            onPressed: _isUpdatingStatus
                ? () {}
                : () => _updateStatus('Cancelled'),
            color: AppTheme.terracotta,
          ),
      ],
    );
  }

  Widget _buildVolunteerList() {
    if (_isLoadingRegistrations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_registrations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.clay.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderSubtle,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: AppTheme.ink.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No volunteers registered yet.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Volunteers will appear here as they register.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _registrations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reg = _registrations[index];
        final user = reg['user'];
        final status = reg['status'];

        return InkWell(
          onTap: () => _showVolunteerActions(user, status),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.clay,
                  child: Text(
                    (user['name'] as String)[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.ink),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                      Text(
                        user['email'],
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppTheme.forest;
      case 'InProgress':
        return AppTheme.violet;
      case 'Completed':
        return AppTheme.ink;
      case 'Cancelled':
        return AppTheme.terracotta;
      default:
        return AppTheme.ink;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Registered':
        color = AppTheme.ink;
        break;
      case 'CheckedIn':
        color = AppTheme.violet;
        break;
      case 'Completed':
        color = AppTheme.forest;
        break;
      default:
        color = AppTheme.ink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        softWrap: false,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
          color: color,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

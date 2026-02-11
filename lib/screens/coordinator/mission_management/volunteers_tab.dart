import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/mission_model.dart';
import '../../../../providers/attendance_provider.dart';
import '../../../../providers/mission_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/eco_notify_widgets.dart';
import '../../../../widgets/eco_pulse_widgets.dart';

class VolunteersTab extends StatefulWidget {
  final Mission mission;

  const VolunteersTab({super.key, required this.mission});

  @override
  State<VolunteersTab> createState() => _VolunteersTabState();
}

class _VolunteersTabState extends State<VolunteersTab> {
  List<Map<String, dynamic>> _registrations = [];
  List<dynamic> _pendingVerifications = [];
  bool _isLoadingRegistrations = false;

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
    _fetchPendingVerifications();
  }

  Future<void> _fetchRegistrations() async {
    if (!mounted) return;
    setState(() => _isLoadingRegistrations = true);
    try {
      final missionProvider = Provider.of<MissionProvider>(context, listen: false);
      final data = await missionProvider.fetchRegistrations(widget.mission.id);
      if (mounted) {
        setState(() {
          _registrations = data;
          _isLoadingRegistrations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRegistrations = false);
    }
  }

  Future<void> _fetchPendingVerifications() async {
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final allPending = await attendanceProvider.getPendingVerifications();
      if (mounted) {
        setState(() {
          _pendingVerifications = allPending.where((v) => v['missionId'] == widget.mission.id).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching pending verifications: $e');
    }
  }

  Future<void> _handleVerification(int attendanceId, String status) async {
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attendanceProvider.verifyAttendance(attendanceId, status);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance $status'), backgroundColor: EcoColors.forest));
        _fetchPendingVerifications();
        _fetchRegistrations();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _promoteUser(int registrationId) async {
    try {
      await Provider.of<MissionProvider>(context, listen: false).promoteFromWaitlist(registrationId);
      if (mounted) _fetchRegistrations();
    } catch (e) {
      debugPrint('Error promoting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRegistrations && _registrations.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: EcoColors.forest));
    }
    final waitlisted = _registrations.where((r) => r['status'] == 'Waitlisted').toList();
    final active = _registrations.where((r) => r['status'] != 'Waitlisted' && r['status'] != 'Cancelled').toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchRegistrations();
        await _fetchPendingVerifications();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_pendingVerifications.isNotEmpty) ...[
            const EcoSectionHeader(title: 'PENDING VERIFICATION'),
            ..._pendingVerifications.map((v) => _buildVerificationCard(v)),
            const SizedBox(height: 24),
          ],
          if (waitlisted.isNotEmpty) ...[
            const EcoSectionHeader(title: 'WAITLIST'),
            ...waitlisted.map((r) => _buildVolunteerCard(r)),
            const SizedBox(height: 24),
          ],
          EcoSectionHeader(title: 'ACTIVE ROSTER', trailing: Text('${active.length} total')),
          if (active.isEmpty) 
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No active volunteers')))
          else
            ...active.map((r) => _buildVolunteerCard(r)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(dynamic v) {
    final user = v['user'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EcoPulseCard(
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(user['name'], style: EcoText.bodyBoldMD(context)),
              subtitle: Text('${v['totalHours']} hours requested'),
              trailing: const EcoPulseTag(label: 'Pending', color: EcoColors.violet),
            ),
            Row(
              children: [
                Expanded(child: EcoPulseButton(label: 'Reject', isPrimary: false, isSmall: true, onPressed: () => _handleVerification(v['id'], 'Rejected'))),
                const SizedBox(width: 8),
                Expanded(child: EcoPulseButton(label: 'Verify', isSmall: true, onPressed: () => _handleVerification(v['id'], 'Verified'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(Map<String, dynamic> reg) {
    final user = reg['user'];
    final status = reg['status'];
    final bool isCheckedIn = status == 'CheckedIn';
    final bool isCompleted = status == 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () => _showVolunteerActions(user, status),
        leading: CircleAvatar(
          backgroundColor: isCheckedIn ? EcoColors.forest.withValues(alpha: 0.1) : (isCompleted ? Colors.orange.withValues(alpha: 0.1) : EcoColors.clay),
          child: Text(
            user['name'][0].toUpperCase(),
            style: TextStyle(
              color: isCheckedIn ? EcoColors.forest : (isCompleted ? Colors.orange : EcoColors.ink),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user['name'], style: EcoText.bodyBoldMD(context)),
        subtitle: Text(status),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'Waitlisted')
              EcoPulseButton(
                label: 'Promote',
                isSmall: true,
                onPressed: () => _promoteUser(reg['id']),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                onPressed: () => _showIndividualNotifySheet(user['id'], user['name']),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showVolunteerActions(dynamic user, String status) async {
    final bool isCheckedIn = status == 'CheckedIn';
    final bool isRegistered = status == 'Registered';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user['name'], style: EcoText.displayMD(context)),
            const SizedBox(height: 8),
            Text('Current Status: $status', style: EcoText.bodySM(context)),
            const SizedBox(height: 24),
            
            if (isRegistered)
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: EcoColors.forest),
                title: const Text('Manual Check-in'),
                subtitle: const Text('Mark as present without QR scan'),
                onTap: () {
                  Navigator.pop(context);
                  _handleManualAction(user['id'], 'check_in');
                },
              ),
            
            if (isCheckedIn)
              ListTile(
                leading: const Icon(Icons.verified_outlined, color: Colors.orange),
                title: const Text('Manual Complete'),
                subtitle: const Text('Verify completion immediately'),
                onTap: () {
                  Navigator.pop(context);
                  _handleManualAction(user['id'], 'complete');
                },
              ),

            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: EcoColors.violet),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _showIndividualNotifySheet(user['id'], user['name']);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualAction(int userId, String action) async {
    final TextEditingController reasonController = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(action == 'check_in' ? 'Manual Check-in' : 'Manual Complete'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for override...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (res == true && reasonController.text.isNotEmpty) {
      if (!mounted) return;
      try {
        final provider = Provider.of<MissionProvider>(context, listen: false);
        if (action == 'check_in') {
          await provider.manualCheckIn(widget.mission.id, userId, reasonController.text);
        } else {
          await provider.manualComplete(widget.mission.id, userId, reasonController.text);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action successful'), backgroundColor: EcoColors.forest));
          _fetchRegistrations();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showIndividualNotifySheet(int userId, String userName) async {
    final messenger = ScaffoldMessenger.of(context);
    EcoNotifySheet.show(
      context,
      title: 'Message $userName',
      subtitle: 'Send a direct notification',
      icon: Icons.chat_bubble_outline_rounded,
      onSend: (message) async {
        if (!mounted) return;
        await Provider.of<MissionProvider>(context, listen: false)
            .contactVolunteer(widget.mission.id, userId, message);
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('Message sent to $userName'),
            backgroundColor: EcoColors.forest,
          ),
        );
      },
    );
  }
}

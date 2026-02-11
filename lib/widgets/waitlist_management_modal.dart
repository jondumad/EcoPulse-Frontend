import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../models/mission_model.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class WaitlistManagementModal extends StatefulWidget {
  final int missionId;
  final String missionTitle;

  const WaitlistManagementModal({
    super.key,
    required this.missionId,
    required this.missionTitle,
  });

  static void show(BuildContext context, {required int missionId, required String missionTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WaitlistManagementModal(
        missionId: missionId,
        missionTitle: missionTitle,
      ),
    );
  }

  @override
  State<WaitlistManagementModal> createState() => _WaitlistManagementModalState();
}

class _WaitlistManagementModalState extends State<WaitlistManagementModal> {
  List<dynamic> _volunteers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<MissionProvider>(context, listen: false);
      final volunteers = await provider.getMissionVolunteers(widget.missionId);
      if (mounted) {
        setState(() {
          _volunteers = volunteers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handlePromote(int userId) async {
    try {
      final provider = Provider.of<MissionProvider>(context, listen: false);
      await provider.promoteFromWaitlistByUserId(widget.missionId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer promoted successfully')));
        _loadVolunteers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promotion failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitlisted = _volunteers.where((v) => v['status'] == 'Waitlisted').toList();
    final registered = _volunteers.where((v) => v['status'] == 'Registered' || v['status'] == 'CheckedIn').toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.clay,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : waitlisted.isEmpty && registered.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (waitlisted.isNotEmpty) ...[
                        _buildSectionHeader('WAITLIST (${waitlisted.length})', AppTheme.violet),
                        ...waitlisted.map((v) => _buildVolunteerTile(v, isWaitlisted: true)),
                      ],
                      if (registered.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('CONFIRMED (${registered.length})', AppTheme.forest),
                        ...registered.map((v) => _buildVolunteerTile(v, isWaitlisted: false)),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.missionTitle, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const Text('WAITLIST MANAGEMENT', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black38)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildVolunteerTile(Map<String, dynamic> v, {required bool isWaitlisted}) {
    final user = v['user'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EcoPulseCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: (isWaitlisted ? AppTheme.violet : AppTheme.forest).withValues(alpha: 0.1),
              child: Text(user['name'][0], style: TextStyle(color: isWaitlisted ? AppTheme.violet : AppTheme.forest, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('ID: ${user['id']}', style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ),
            if (isWaitlisted)
              EcoPulseButton(
                label: 'PROMOTE',
                isSmall: true,
                onPressed: () => _handlePromote(user['id']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No volunteers registered yet.'));
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<dynamic> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final pending = await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).getPendingVerifications();
      if (mounted) {
        setState(() {
          _pending = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: AppTheme.terracotta,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify(int id, String status) async {
    try {
      final success = await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).verifyAttendance(id, status);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance $status'),
              backgroundColor:
                  status == 'Verified' ? AppTheme.forest : AppTheme.terracotta,
            ),
          );
          Provider.of<AuthProvider>(context, listen: false).refreshProfile();
        }
        _loadPending();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.terracotta,
          ),
        );
      }
    }
  }

  void _showManualActionDialog() {
    final missions = Provider.of<MissionProvider>(context, listen: false).missions;
    
    showDialog(
      context: context,
      builder: (context) => _ManualActionDialog(missions: missions),
    ).then((_) => _loadPending());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Attendance Review',
          style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.forest),
            onPressed: _showManualActionDialog,
            tooltip: 'Manual Check-in',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pending.length} PENDING REVIEW',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.forest,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.forest))
                : _pending.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPending,
                        color: AppTheme.forest,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: _pending.length,
                          itemBuilder: (context, index) => _VerificationCard(
                            data: _pending[index],
                            onVerify: (id) => _handleVerify(id, 'Verified'),
                            onReject: (id) => _handleVerify(id, 'Rejected'),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            'Clear Skies!',
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(color: Colors.black26),
          ),
          const Text('No pending verifications to review.', style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(int) onVerify;
  final Function(int) onReject;

  const _VerificationCard({
    required this.data,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final user = data['user'];
    final mission = data['mission'];
    final checkIn = DateTime.parse(data['checkInTime']).toLocal();
    final checkOut = data['checkOutTime'] != null 
        ? DateTime.parse(data['checkOutTime']).toLocal() 
        : null;
    final hours = data['totalHours'] ?? 0.0;
    final gps = data['gpsProof'] ?? 'No GPS data';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: EcoPulseCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.forest.withValues(alpha: 0.1),
                  child: Text(user['name'][0], 
                    style: const TextStyle(color: AppTheme.forest, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(user['email'], style: const TextStyle(color: Colors.black38, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.clay,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${hours.toStringAsFixed(1)} HRS', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildDetail(Icons.assignment_outlined, 'Mission', mission['title']),
            const SizedBox(height: 12),
            _buildDetail(Icons.access_time, 'Time', 
              '${DateFormat('HH:mm').format(checkIn)} - ${checkOut != null ? DateFormat('HH:mm').format(checkOut) : 'Active'}'),
            const SizedBox(height: 12),
            _buildDetail(Icons.location_on_outlined, 'GPS Proof', gps, isMono: true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EcoPulseButton(
                    label: 'REJECT',
                    isPrimary: false,
                    onPressed: () => onReject(data['id']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EcoPulseButton(
                    label: 'VERIFY',
                    icon: Icons.check,
                    onPressed: () => onVerify(data['id']),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.forest.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontFamily: isMono ? 'JetBrainsMono' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualActionDialog extends StatefulWidget {
  final List<Mission> missions;
  const _ManualActionDialog({required this.missions});

  @override
  State<_ManualActionDialog> createState() => _ManualActionDialogState();
}

class _ManualActionDialogState extends State<_ManualActionDialog> {
  Mission? _selectedMission;
  int? _userId;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Verification', style: TextStyle(fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manually record participation for a volunteer.', 
              style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 20),
            DropdownButtonFormField<Mission>(
              decoration: const InputDecoration(labelText: 'Select Mission', border: OutlineInputBorder()),
              items: widget.missions.map((m) => DropdownMenuItem(value: m, child: Text(m.title, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedMission = val),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'User ID', hintText: 'Enter numerical ID', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userId = int.tryParse(val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason for Override', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forest, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Complete Mission'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedMission == null || _userId == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await provider.manualComplete(_selectedMission!.id, _userId!, _reasonController.text);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual verification successful')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual verification failed')));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../providers/collaboration_provider.dart';
import '../../providers/attendance_provider.dart';
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

class _MissionManagementScreenState extends State<MissionManagementScreen>
    with SingleTickerProviderStateMixin {
  // Common State
  Mission? _latestMission;
  bool _isUpdatingStatus = false;

  // Volunteers Tab State
  List<Map<String, dynamic>> _registrations = [];
  List<dynamic> _pendingVerifications = [];
  bool _isLoadingRegistrations = false;

  // Collaboration Tab State
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  CollaborationProvider? _collabProvider;

  // Logistics Tab State
  String? _qrToken;
  Timer? _qrTimer;
  int _qrSecondsLeft = 300;
  bool _isLoadingQR = false;
  String? _qrError;

  @override
  void initState() {
    super.initState();
    _latestMission = widget.mission;
    _fetchRegistrations();
    _fetchPendingVerifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_collabProvider == null) {
      _collabProvider = Provider.of<CollaborationProvider>(context, listen: false);
      _collabProvider!.initBoard(widget.mission.id);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _chatScrollController.dispose();
    _qrTimer?.cancel();
    _collabProvider?.leaveBoard();
    super.dispose();
  }

  // --- Logic Methods ---

  Future<void> _fetchMission() async {
    try {
      final missionProvider = Provider.of<MissionProvider>(context, listen: false);
      await missionProvider.fetchMissions(mine: true);
      if (!mounted) return;
      final mission = missionProvider.missions.firstWhere((m) => m.id == widget.mission.id);
      setState(() => _latestMission = mission);
    } catch (e) {
      debugPrint('Error fetching specific mission: $e');
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance $status')));
        _fetchPendingVerifications();
        _fetchRegistrations();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- Logistics Logic ---

  bool _isExpired() {
    final mission = _latestMission ?? widget.mission;
    return DateTime.now().isAfter(mission.endTime);
  }

  Future<void> _fetchQR() async {
    if (!mounted) return;
    if (_isExpired()) {
      setState(() {
        _qrError = 'Mission has ended';
        _isLoadingQR = false;
      });
      return;
    }

    setState(() {
      _isLoadingQR = true;
      _qrError = null;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final result = await attendanceProvider.getQRCode(widget.mission.id);
      if (mounted) {
        setState(() {
          _qrToken = result['qrToken'];
          _qrSecondsLeft = 300;
          _isLoadingQR = false;
        });
        _startQRTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = e.toString();
          _isLoadingQR = false;
        });
      }
    }
  }

  void _startQRTimer() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_qrSecondsLeft > 0) {
        setState(() => _qrSecondsLeft--);
      } else {
        timer.cancel();
        _fetchQR();
      }
    });
  }

  void _showFullScreenQR() {
    if (_qrToken == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.mission.title,
                      style: EcoText.displayMD(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VOLUNTEER CHECK-IN',
                      style: EcoText.monoSM(context).copyWith(color: EcoColors.forest),
                    ),
                    const SizedBox(height: 60),
                    QrImageView(
                      data: _qrToken!,
                      size: MediaQuery.of(context).size.width * 0.7,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: EcoColors.forest,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: EcoColors.forest,
                      ),
                    ),
                    const SizedBox(height: 60),
                    const EcoPulseTag(label: 'LIVE TOKEN'),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 24,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 32, color: EcoColors.ink),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: EcoPulseLayout(
        appBar: EcoAppBar(
          height: 140,
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MISSION HUB', style: EcoText.monoSM(context)),
              const SizedBox(height: 4),
              Text(_latestMission?.title ?? widget.mission.title, 
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: EcoText.displayMD(context)),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: EcoColors.forest,
            labelColor: EcoColors.forest,
            unselectedLabelColor: Colors.black38,
            tabs: [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'VOLUNTEERS'),
              Tab(text: 'COLLABORATION'),
              Tab(text: 'LOGISTICS'),
            ],
          ),
        ),
        child: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildVolunteersTab(),
            _buildCollaborationTab(),
            _buildLogisticsTab(),
          ],
        ),
      ),
    );
  }

  // --- Tab Implementation (Partial, showing structure) ---

  Widget _buildOverviewTab() {
    final mission = _latestMission ?? widget.mission;
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
        const EcoSectionHeader(title: 'Description'),
        EcoPulseCard(child: Text(mission.description, style: EcoText.bodyMD(context))),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildVolunteersTab() {
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

  Widget _buildCollaborationTab() {
    final collab = context.watch<CollaborationProvider>();
    return Column(
      children: [
        _buildPresenceHeader(collab.activeUsers),
        const Divider(height: 1),
        // Sub-navigation for Chat/Checklist
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildSubTabButton('CHAT', _collabSubTab == 0, () => setState(() => _collabSubTab = 0)),
              _buildSubTabButton('CHECKLIST', _collabSubTab == 1, () => setState(() => _collabSubTab = 1)),
            ],
          ),
        ),
        Expanded(
          child: _collabSubTab == 0 
            ? Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: collab.comments.length,
                      itemBuilder: (context, index) => _buildChatBubble(collab.comments[index]),
                    ),
                  ),
                  _buildChatInput(collab),
                ],
              )
            : _buildChecklistSection(collab),
        ),
      ],
    );
  }

  int _collabSubTab = 0;

  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? EcoColors.forest : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? EcoColors.forest : Colors.black38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const EcoSectionHeader(title: 'CHECK-IN QR CODE'),
        _buildQRSection(),
        const SizedBox(height: 40),
        const EcoSectionHeader(title: 'LOCATION DETAILS'),
        _buildLocationCard(),
        const SizedBox(height: 100),
      ],
    );
  }

  // --- Sub-widgets Helper ---

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
          onPressed: _isUpdatingStatus ? null : _showNotifyDialog,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      child: ListTile(
        leading: CircleAvatar(child: Text(user['name'][0].toUpperCase())),
        title: Text(user['name']),
        subtitle: Text(status),
        trailing: status == 'Waitlisted' 
          ? EcoPulseButton(label: 'Promote', isSmall: true, onPressed: () => _promoteUser(reg['id']))
          : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildChecklistSection(CollaborationProvider provider) {
    final checklist = provider.checklist;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: checklist.length,
            itemBuilder: (context, index) {
              final item = checklist[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: CheckboxListTile(
                  title: Text(item.content, style: TextStyle(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.black38 : Colors.black,
                  )),
                  value: item.isCompleted,
                  onChanged: (val) => provider.toggleChecklistItem(item.id, val ?? false),
                  activeColor: EcoColors.forest,
                ),
              );
            },
          ),
        ),
        _buildChecklistInput(provider),
      ],
    );
  }

  final TextEditingController _checklistController = TextEditingController();

  Widget _buildChecklistInput(CollaborationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _checklistController,
              decoration: const InputDecoration(hintText: 'Add task...', border: InputBorder.none),
              onSubmitted: (val) => _addChecklistItem(provider),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: EcoColors.forest),
            onPressed: () => _addChecklistItem(provider),
          ),
        ],
      ),
    );
  }

  void _addChecklistItem(CollaborationProvider provider) {
    if (_checklistController.text.isNotEmpty) {
      provider.addChecklistItem(_checklistController.text);
      _checklistController.clear();
    }
  }

  Widget _buildPresenceHeader(List<dynamic> users) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: Row(
        children: [
          Text('ACTIVE:', style: EcoText.monoSM(context)),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              itemBuilder: (c, i) => Padding(padding: const EdgeInsets.only(right: 4), child: CircleAvatar(radius: 12, child: Text(users[i]['name'][0], style: const TextStyle(fontSize: 10)))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(dynamic comment) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.userName, style: EcoText.bodyBoldMD(context).copyWith(fontSize: 12, color: EcoColors.forest)),
            const SizedBox(height: 4),
            Text(comment.content, style: EcoText.bodyMD(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(CollaborationProvider collab) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Type an update...', border: InputBorder.none))),
            IconButton(icon: const Icon(Icons.send, color: EcoColors.forest), onPressed: () {
              if (_commentController.text.isNotEmpty) {
                collab.sendComment(_commentController.text);
                _commentController.clear();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    if (_qrToken == null && !_isLoadingQR && _qrError == null) {
      return EcoPulseButton(
        label: 'Generate Check-in QR',
        icon: Icons.qr_code,
        onPressed: _fetchQR,
      );
    }

    if (_isLoadingQR) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: EcoColors.forest),
        ),
      );
    }

    if (_isExpired()) {
      return EcoPulseCard(
        child: Column(
          children: [
            Icon(
              Icons.lock_clock,
              size: 48,
              color: AppTheme.ink.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Mission Ended',
              style: EcoText.bodyBoldMD(context),
            ),
            const SizedBox(height: 8),
            const Text(
              'QR checking is no longer available',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_qrError != null) {
      return Column(
        children: [
          Text(
            'Error: $_qrError',
            style: const TextStyle(color: EcoColors.terracotta),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          EcoPulseButton(label: 'Retry', isSmall: true, onPressed: _fetchQR),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        EcoPulseCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: _qrToken!,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: EcoColors.forest,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: EcoColors.forest,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showFullScreenQR,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: EcoColors.forest,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('REFRESH IN', style: EcoText.monoSM(context)),
              Text(
                '${_qrSecondsLeft ~/ 60}:${(_qrSecondsLeft % 60).toString().padLeft(2, '0')}',
                style: EcoText.displayMD(context),
              ),
            ],
          ),
        ),
        const Positioned(
          top: -10,
          left: 0,
          child: EcoPulseTag(label: 'LIVE TOKEN', isRotated: true),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final mission = _latestMission ?? widget.mission;
    return EcoPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.place, 'Address', mission.locationName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.gps_fixed, 'GPS', mission.locationGps ?? 'Not available'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EcoColors.forest.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text('$label: ', style: EcoText.bodyMD(context).copyWith(color: Colors.black45)),
        Expanded(child: Text(value, style: EcoText.bodyBoldMD(context))),
      ],
    );
  }

  // --- Actions ---

  Future<void> _promoteUser(int registrationId) async {
    try {
      await Provider.of<MissionProvider>(context, listen: false).promoteFromWaitlist(registrationId);
      if (mounted) _fetchRegistrations();
    } catch (e) {
      debugPrint('Error promoting user: $e');
    }
  }

  Future<void> _showNotifyDialog() async {
    String msg = '';
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Notify Volunteers'),
        content: TextField(onChanged: (v) => msg = v, decoration: const InputDecoration(hintText: 'Message...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, msg), child: const Text('Send')),
        ],
      ),
    );
    if (res != null && res.isNotEmpty && mounted) {
      await Provider.of<MissionProvider>(context, listen: false).contactVolunteers(widget.mission.id, res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications sent')));
      }
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
}

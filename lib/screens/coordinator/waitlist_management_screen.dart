import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';

class WaitlistManagementScreen extends StatefulWidget {
  final Mission mission;

  const WaitlistManagementScreen({super.key, required this.mission});

  @override
  State<WaitlistManagementScreen> createState() =>
      _WaitlistManagementScreenState();
}

class _WaitlistManagementScreenState extends State<WaitlistManagementScreen> {
  List<Map<String, dynamic>> _waitlistedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaitlist();
  }

  Future<void> _loadWaitlist() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<MissionProvider>(context, listen: false);
      final registrations = await provider.getMissionRegistrations(
        widget.mission.id,
      );

      setState(() {
        _waitlistedUsers = registrations
            .where((r) => r['status'] == 'Waitlisted')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading waitlist: $e')));
      }
    }
  }

  Future<void> _promoteUser(int registrationId) async {
    try {
      final provider = Provider.of<MissionProvider>(context, listen: false);
      await provider.promoteFromWaitlist(registrationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User promoted successfully!')),
        );
        _loadWaitlist(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _togglePriority(int registrationId, bool currentPriority) async {
    try {
      final provider = Provider.of<MissionProvider>(context, listen: false);
      await provider.setPriority(registrationId, !currentPriority);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentPriority ? 'Priority removed' : 'Marked as priority',
            ),
          ),
        );
        _loadWaitlist(); // Refresh
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
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: AppBar(
        title: const Text('Waitlist Management'),
        backgroundColor: AppTheme.forest,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _waitlistedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.forest.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users on waitlist',
                    style: EcoText.bodyMD(
                      context,
                    ).copyWith(color: AppTheme.ink.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _waitlistedUsers.length,
              itemBuilder: (context, index) {
                final registration = _waitlistedUsers[index];
                final user = registration['user'];
                final isPriority = registration['isPriority'] ?? false;
                final registrationId = registration['id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPriority
                          ? AppTheme.terracotta
                          : AppTheme.violet,
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isPriority) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            color: AppTheme.terracotta,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${user['totalPoints']} points',
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_upward, size: 20),
                              const SizedBox(width: 8),
                              const Text('Promote Now'),
                            ],
                          ),
                          onTap: () => _promoteUser(registrationId),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                isPriority ? Icons.star_border : Icons.star,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPriority
                                    ? 'Remove Priority'
                                    : 'Mark Priority',
                              ),
                            ],
                          ),
                          onTap: () =>
                              _togglePriority(registrationId, isPriority),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
